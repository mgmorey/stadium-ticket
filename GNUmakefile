SCRIPT_DIR = scripts

build:
	docker-compose up --build

clean:
	@find . '(' -name __pycache__ -o -name .pytest_cache ')' -print | xargs /bin/rm -rf

install:	clean pipenv
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

.PHONY: build clean install pip pipenv run stress traffic uninstall
