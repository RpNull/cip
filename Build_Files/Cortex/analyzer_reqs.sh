
wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
sudo python2 get-pip.py

apt install docker.io

mkdir -p /var/data/cortex

sudo apt-get install -y --no-install-recommends python-pip python2.7-dev python3-pip python3-dev ssdeep libfuzzy-dev libfuzzy2 libimage-exiftool-perl libmagic1 build-essential git libssl-dev

sudo pip install -U pip setuptools && sudo pip3 install -U pip setuptools

git clone https://github.com/TheHive-Project/Cortex-Analyzers

for I in $(find Cortex-Analyzers -name 'requirements.txt'); do sudo -H pip install -r $I; done && \
for I in $(find Cortex-Analyzers -name 'requirements.txt'); do sudo -H pip3 install -r $I || true; done

sudo mv Cortex-Analyzers/analyzers /var/data/cortex/
sudo chmod -R 777 /var/data/cortex/analyzers/
sudo mv Cortex-Analyzers/responders /var/data/cortex/
sudo chmod -R 777 /var/data/cortex/responders/