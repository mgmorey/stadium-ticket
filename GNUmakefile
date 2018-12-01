SCRIPT_DIR = scripts

all:	Pipfile.lock requirements.txt

build:	.env Pipfile.lock
	docker-compose up --build

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

install:	.env Pipfile.lock
	$(SCRIPT_DIR)/install-app.sh

pip:	requirements.txt
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

.env:	.env-template
	cp .env-template tmp$$$$ && $(EDITOR) tmp$$$$ && mv tmp$$$$ .env

Pipfile.lock:	Pipfile
	pipenv install || true

requirements.txt:	Pipfile
	pipenv lock -r >tmp$$$$ && mv -f tmp$$$$ requirements.txt || true
