# Makefile to install a development environment and work with Tryton

TRYTON_VERSION := 5.8
TRYTON_PATH := ${HOME}/tryton
NODE_PATH := ${HOME}/.nodenv/bin
VENV_PATH := ${HOME}/tryton/.venv
VENV := . ${VENV_PATH}/bin/activate &&
SHELL := /bin/bash
INITIAL_EMAIL := "admin@example.org"
INITIAL_PWD := "admindemo"

all:
	@echo
	@echo =====================================================================================
	@echo Run '"'make quickstart_debian"'" or '"'make quickstart_fedora'"' to install a dev environment.
	@echo Run '"'make runserver'"' to start the server.

quickstart_debian: debian_packages quickstart

debian_packages:
	sudo apt update
	sudo apt install python3-venv python3-dev -y
	
quickstart_fedora: fedora_packages quickstart

fedora_packages:
	(rpm -qa | grep python3-devel) || sudo dnf install python3-devel

quickstart: create_venv pip_packages inifile create_db node webclient
	@echo
	@echo =====================================================================================
	@echo Installation has finished successfully
	@echo Run '"'make runserver'"' in order to start the server and access it through one of the following IP addresses
	@ip addr | sed 's/\/[0-9]*//' | awk '/inet / {print "http://" $$2 ":8000/"}'
	@echo Login user is '"'admin'"' password is '"'${INITIAL_PWD}'"'

create_venv:
	mkdir -p ${TRYTON_PATH}
	cd ${TRYTON_PATH} && python3 -m venv ${VENV_PATH}

pip_packages:
	${VENV} pip install -r requirements.txt

inifile:
	@mkdir -p ${TRYTON_PATH}
	@echo "[database]" > ${TRYTON_PATH}/tryton.ini
	@echo "uri = sqlite://tryton-dev.sqlite" >> ${TRYTON_PATH}/tryton.ini
	@echo "path = ${TRYTON_PATH}" >> ${TRYTON_PATH}/tryton.ini
	@echo "[web]" >> ${TRYTON_PATH}/tryton.ini
	@echo "root = ${TRYTON_PATH}/sao" >> ${TRYTON_PATH}/tryton.ini
	@echo "hostname = localhost" >> ${TRYTON_PATH}/tryton.ini

create_db:
	touch ${TRYTON_PATH}/tryton-dev.sqlite
	@echo "${INITIAL_PWD}" > ${TRYTON_PATH}/initialpwd.txt
	export TRYTONPASSFILE=${TRYTON_PATH}/initialpwd.txt && ${VENV} python ${VENV_PATH}/bin/trytond-admin -c ${TRYTON_PATH}/tryton.ini -d tryton-dev --all --email=${INITIAL_EMAIL}

webclient:
	git clone --single-branch --branch ${TRYTON_VERSION} https://github.com/tryton/sao.git ${TRYTON_PATH}/sao
	source ${HOME}/.profile && cd ${TRYTON_PATH}/sao && npm install bower po2json grunt-po2json grunt && npm install --production
	cd ${TRYTON_PATH}/sao && node_modules/grunt/bin/grunt --force

node:
	git clone https://github.com/OiNutter/nodenv.git ~/.nodenv
	echo 'export PATH="${HOME}/.nodenv/bin:${PATH}"' >> ~/.profile
	echo 'eval "$$(nodenv init -)"' >> ~/.profile
	git clone git://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build
	${NODE_PATH}/nodenv install 12.18.4
	${NODE_PATH}/nodenv rehash
	${NODE_PATH}/nodenv global 12.18.4

runserver:
	cd ${TRYTON_PATH} && ${VENV} python ${VENV_PATH}/bin/trytond -c tryton.ini

remove:
	cd ${HOME} && rm -Rf .nodenv .cache .npm ${TRYTON_PATH}
