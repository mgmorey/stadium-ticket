FROM debian
USER root

ENV APP_ENDPOINT=0.0.0.0:5000
ENV APP_NAME=stadium-ticket
ENV APP_UID=www-data

ENV APT_INSTALL="apt-get install -qy --no-install-recommends"
ENV APT_UPDATE="apt-get update -qy"
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIPENV_VENV_IN_PROJECT=true

RUN $APT_UPDATE
RUN $APT_INSTALL build-essential mariadb-client-10.1 python3
RUN $APT_INSTALL python3-dev python3-flask python3-pip
RUN $APT_INSTALL uwsgi uwsgi-plugin-python3
RUN pip3 install pipenv
RUN mkdir -p /app/database

COPY database/*.py /app/database/
COPY Makefile Pipfile* app.ini *.py scripts/mysql.sh sql/*.sql /app/

RUN /bin/chown -R $APP_UID:$APP_UID /app

WORKDIR /app
RUN pipenv sync

EXPOSE $APP_PORT
CMD ["/usr/bin/uwsgi", "--ini", "app.ini"]
