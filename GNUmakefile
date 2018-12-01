SCRIPT_DIR = scripts

all:	Pipfile.lock

build:
	docker-compose up --build

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

install:
	$(SCRIPT_DIR)/install-app.sh

pip:
	pip3 install pip --user
	pip3 install -r requirements.txt --user

pipenv:
	$(SCRIPT_DIR)/install-pipenv.sh
	pipenv install

run:
	docker-compose up

stress:
	$(SCRIPT_DIR)/load-test.sh

traffic:
	$(SCRIPT_DIR)/app-test.sh

uninstall:
	$(SCRIPT_DIR)/uninstall-app.sh

.PHONY: all build clean install pip pipenv run stress traffic uninstall

Pipfile.lock:	Pipfile
	pipenv install || true

requirements.txt:	Pipfile
	pipenv lock -r >/tmp/tmp$$$$ && mv -f /tmp/tmp$$$$ requirements.txt || true
