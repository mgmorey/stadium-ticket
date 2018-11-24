FROM debian

ENV APP_ENDPOINT=0.0.0.0:5000
ENV APP_NAME=stadium-ticket
ENV APP_UID=www-data

ENV BIN_DIR=/opt/$APP_NAME
ENV ETC_DIR=/opt/etc/$APP_NAME
ENV VAR_DIR=/opt/var/$APP_NAME

ENV APT_INSTALL="apt-get install -qy --no-install-recommends"
ENV APT_UPDATE="apt-get update -qy"
ENV DEBIAN_FRONTEND=noninteractive

RUN $APT_UPDATE
RUN $APT_INSTALL build-essential mariadb-client-10.1 python3 \
python3-dev python3-pip uwsgi uwsgi-plugin-python3

RUN pip3 install pipenv
RUN mkdir -p $BIN_DIR $ETC_DIR $VAR_DIR
RUN chown $APP_UID:$APP_UID $BIN_DIR $VAR_DIR

COPY database/*.py $BIN_DIR/database/
COPY Pipfile* *.py $BIN_DIR/
COPY app.ini $ETC_DIR/

WORKDIR $BIN_DIR
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIPENV_VENV_IN_PROJECT=true
RUN pipenv sync

EXPOSE $APP_PORT
CMD /usr/bin/uwsgi --ini $ETC_DIR/app.ini
