FROM ubuntu:18.04

ENV APP_NAME=stadium-ticket
ENV APP_PORT=5000

ENV APP_GID=www-data
ENV APP_UID=www-data
ENV DEBIAN_FRONTEND=noninteractive

ENV APT_UPDATE="apt-get update -qy"
RUN for i in 1 2 3; do $APT_UPDATE && break; done

ENV APT_INSTALL="apt-get install -qy --no-install-recommends build-essential \
mariadb-client-10.1 python3 python3-dev python3-pip uwsgi uwsgi-plugin-python3"
RUN for i in 1 2 3; do $APT_INSTALL && break; done

ENV APP_DIR=/opt/$APP_NAME
ENV ETC_DIR=/opt/etc/$APP_NAME
ENV VAR_DIR=/opt/var/$APP_NAME
RUN mkdir -p $APP_DIR $ETC_DIR $VAR_DIR

WORKDIR $APP_DIR
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PIPENV_VENV_IN_PROJECT=true
RUN pip3 install pipenv
COPY Pipfile* $APP_DIR/
RUN pipenv sync && /bin/rm Pipfile*

COPY app/ $APP_DIR/
COPY app.ini $ETC_DIR/
RUN chown -R $APP_UID:$APP_GID $APP_DIR $VAR_DIR

EXPOSE $APP_PORT
CMD /usr/bin/uwsgi --ini $ETC_DIR/app.ini
