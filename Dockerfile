FROM debian
USER root
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN apt-get update -qy
RUN apt-get install -qy --no-install-recommends mariadb-server-10.1 python3 python3-pip
RUN python3 -m pip install pipenv
RUN mkdir -p /app/database
COPY database/*.py /app/database/
COPY sql/*.sql Pipfile Pipfile.lock app.py tickets.py /app/
WORKDIR /app
RUN pipenv install
RUN ls -lR .
