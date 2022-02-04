FROM nodered/node-red:2.2.0-minimal AS base

USER root

######## STAGE BUILD ######
FROM base as build

# add build tools
RUN apk update && apk add --no-cache python3-dev gcc g++ libc-dev libffi-dev libxml2 unixodbc-dev mariadb-dev postgresql-dev gnupg && \
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

######### STAGE RELEASE #######
FROM base AS release

COPY --from=build /root/mssql /root/mssql
COPY --from=build /root/wheels /root/wheels

RUN apk update && \
    apk add --allow-untrusted /root/mssql/msodbcsql17_17.8.1.1-1_amd64.apk && \
    apk add --allow-untrusted /root/mssql/mssql-tools_17.8.1.1-1_amd64.apk && \
    rm -rf /root/mssql && \
    apk add --no-cache python3 unixodbc && \
    python3 -m ensurepip && \
    pip3 install --no-cache --no-index /root/wheels/* && \
    rm -rf /root/wheels

WORKDIR /data

USER node-red

#ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]