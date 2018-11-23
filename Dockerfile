FROM debian
USER root
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
RUN apt-get update -qy
RUN apt-get install -qy --no-install-recommends make mariadb-client-10.1 python3 python3-pip
RUN pip3 install pipenv
RUN mkdir -p /app/database
COPY database/*.py /app/database/
COPY Makefile Pipfile* *.py scripts/mysql.sh sql/*.sql /app/
WORKDIR /app
RUN pipenv install
EXPOSE 5000
CMD make run
