FROM thehiveproject/cortex:3.1.0-1

USER root
RUN apt-get update
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python2 get-pip.py
RUN apt-get install -y --no-install-recommends python-pip python2.7-dev python3-pip python3-dev ssdeep libfuzzy-dev libfuzzy2 libimage-exiftool-perl libmagic1 build-essential git libssl-dev
RUN pip install -U pip setuptools && pip3 install -U pip setuptools
RUN git clone https://github.com/TheHive-Project/Cortex-Analyzers
RUN for I in $(find Cortex-Analyzers -name 'requirements.txt'); do pip install -r $I; done && for I in $(find Cortex-Analyzers -name 'requirements.txt'); do pip3 install -r $I || true; done
