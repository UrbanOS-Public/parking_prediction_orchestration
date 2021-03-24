FROM python:3.8

RUN apt-get clean \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get -y update

RUN apt-get -y install python3-dev \
    && apt-get -y install libpcre3 libpcre3-dev \
    && apt-get -y install build-essential \
    && apt-get -y install unixodbc-dev \
    && apt-get -y install locales \
    && ACCEPT_EULA=Y apt-get -y install msodbcsql17 \
    && ACCEPT_EULA=Y apt-get -y install mssql-tools \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen --purge "en_US.UTF-8" \
    && echo "locales locales/default_environment_locale select en_US.UTF-8 UTF-8" | debconf-set-selections \
    && echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections \
    && rm "/etc/locale.gen" \
    && dpkg-reconfigure --frontend noninteractive locales \
    && update-locale "LANG=en_US.UTF-8"

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    PATH="${PATH}:/opt/mssql-tools/bin"
    
RUN pip3 install pipenv

WORKDIR /

ADD Pipfile* /

RUN pipenv install

ADD sql /sql
ADD ref_data /ref_data
ADD app /app

CMD [ "pipenv", "run", "python", "app/conductor.py" ]