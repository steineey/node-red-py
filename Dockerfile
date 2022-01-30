FROM nodered/node-red:2.2.0-minimal AS base

USER root
RUN apk update && apk upgrade

FROM base as builder

# add build tools
RUN apk add --no-cache python3-dev gcc g++ libc-dev libffi-dev libxml2 unixodbc-dev mariadb-dev postgresql-dev gnupg && \
    ln -sf python3 /usr/bin/python && python3 -m ensurepip && pip3 --no-cache-dir install wheel
# wheel build binaries
COPY requirements.txt /data/requirements.txt
RUN pip3 wheel --no-cache-dir --wheel-dir=/root/wheels -r /data/requirements.txt

WORKDIR /root/mssql
# download sqlserver driver
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.8.1.1-1_amd64.apk && \
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.8.1.1-1_amd64.apk && \
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.8.1.1-1_amd64.sig && \
curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.8.1.1-1_amd64.sig && \
curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import -
# verify driver install packages
RUN gpg --verify msodbcsql17_17.8.1.1-1_amd64.sig msodbcsql17_17.8.1.1-1_amd64.apk && \
    gpg --verify mssql-tools_17.8.1.1-1_amd64.sig mssql-tools_17.8.1.1-1_amd64.apk

FROM base

COPY --from=builder /root/mssql  /root/mssql
RUN apk add --allow-untrusted /root/mssql/msodbcsql17_17.8.1.1-1_amd64.apk && \
    apk add --allow-untrusted /root/mssql/mssql-tools_17.8.1.1-1_amd64.apk && \
    rm -rf /root/mssql

COPY --from=builder /root/wheels /root/wheels
RUN apk add --no-cache python3 unixodbc && \
    python3 -m ensurepip && \
    pip3 install --no-cache --no-index /root/wheels/* && \
    rm -rf /root/wheels

USER node-red