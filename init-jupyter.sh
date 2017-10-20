#Environments
SPARK_PACKAGES=com.databricks:spark-avro_2.11:3.2.0
ANACONDA_VERSION=2-2.5.0
JUPYTER_LOG=/dev/null
#JUPYTER_LOG=/home/hadoop/.jupyter/jupyter.log

PYENV=~/.pyenv
PYENV_BIN=$PYENV/bin

##Install git and Anaconda
sudo yum -y install git
git clone https://github.com/pyenv/pyenv.git $PYENV

echo -e "\nexport PYENV_ROOT=$PYENV" | sudo tee -a ~/.bash_profile  >> /dev/null
echo -e "\nexport PATH=$PYENV_BIN:$PATH" | sudo tee -a ~/.bash_profile  >> /dev/null
echo -e "\neval '$($PYENV_BIN/pyenv init -)'" | sudo tee -a ~/.bash_profile  >> /dev/null
source ~/.bash_profile

pyenv install -l | grep ana
pyenv install anaconda$ANACONDA_VERSION
pyenv rehash
pyenv global anaconda$ANACONDA_VERSION

echo -e "\nexport PATH='$PYENV/versions/anaconda$ANACONDA_VERSION/bin/:$PATH'" | sudo tee -a ~/.bash_profile  >> /dev/null
source ~/.bash_profile
conda update --yes conda

##Install addtional python libraries
conda install --yes seaborn plotly

##Configure Jupyter
sudo su -l hadoop -c "jupyter notebook --generate-config"

JUPYTER_NOTEBOOK_CONFIG=/home/hadoop/.jupyter/jupyter_notebook_config.py
sudo sed -i -e "6i c.NotebookApp.ip = '0.0.0.0'" $JUPYTER_NOTEBOOK_CONFIG
sudo sed -i -e "6i c.NotebookApp.open_browser =False" $JUPYTER_NOTEBOOK_CONFIG
sudo sed -i -e "6i c.NotebookApp.port = 8080" $JUPYTER_NOTEBOOK_CONFIG
sudo sed -i -e "6i c.NotebookApp.token = ''" $JUPYTER_NOTEBOOK_CONFIG
sudo sed -i -e "6i c = get_config()" $JUPYTER_NOTEBOOK_CONFIG

IPYTHON_KERNEL_CONFIG=/home/hadoop/.ipython/profile_default/ipython_kernel_config.py
sudo su -l hadoop -c "ipython profile create"
sudo sed -i -e "3a c.InteractiveShellApp.matplotlib = 'inline'" $IPYTHON_KERNEL_CONFIG

##Launch Jupyter by executing "pyspark"
JUPYTER_PYSPARK_BIN=/home/hadoop/.jupyter/start-jupyter-pyspark.sh

cat << EOF > $JUPYTER_PYSPARK_BIN
export SPARK_HOME=/usr/lib/spark/
export PYSPARK_PYTHON=/usr/bin/python
export PYSPARK_DRIVER_PYTHON=jupyter
export PYSPARK_DRIVER_PYTHON_OPTS='notebook'
export SPARK_PACKAGES=$SPARK_PACKAGES
nohup pyspark --packages $SPARK_PACKAGES > $JUPYTER_LOG 2>&1 &
EOF

chmod +x $JUPYTER_PYSPARK_BIN
$JUPYTER_PYSPARK_BIN
