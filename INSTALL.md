# Installation

This guide covers how to set up a production environment using CDX docker images based on an Ubuntu Linux server. Note that the environment will be configured so that CDX is the only web application running on the server; a more complex setup including a reverse proxy is required if multiple virtual hosts are needed.

During this guide, we'll assume that the server will be set up on `http://cdx.example.com`.

## Docker install

Install Docker on your server following the [instructions listed on the Docker page](https://docs.docker.com/engine/installation/ubuntulinux/). This guide has been tested on docker version 1.9.0, though may work on other versions.

Install [docker-compose](https://docs.docker.com/compose/install/) as well. This guide has been tested on compose version 1.5.2.

### Logging

Docker does not rotate log files by default. To enable this, and prevent log files from flooding the host's capacity, add the following line to `/etc/default/docker`:
```bash
DOCKER_OPTS="--log-opt max-size=1m --log-opt max-file=100"
```

Then restart the docker service via `restart docker`.

## Configuration

Create a folder where all configuration files will be stored, such as `/u/apps/cdx/`, and there create the configuration files.

### Files

All the following files are required.

#### client_version.json

This file contains the information on the CDX SSH client to be used for this server.

```json
{
  "version": "0.1.0",
  "url": "https://github.com/instedd/cdx-sync-client/releases/download/release-v0.1.0/cdx-win32-0.1.0.exe"
}
```

#### settings.local.yml

This file contains miscellaneous settings for the server. Remember to change the `host` key to your own hostname.

Google client id and secret are required to enable login using Google, and you should also enter a maps API key to be used for the static maps API. You can apply for these values in [Google's Developers Console](https://console.developers.google.com/).

```yml
host: cdx.example.com
app_version: latest
nndd_url: "/nndd/index.html"
location_service_url: https://locations-stg.instedd.org
google_client_id:
google_client_secret:
google_maps_api_key:
user_password_expire_in_months: 12
web_session_timeout: 360000000
```

#### docker.env

This file contains all environment values to be injected into the Docker containers.

Again, remember to change `cdx.example.com` to your corresponding hostname.

`MAILER_SENDER` should be the address from which user emails will be sent.

The last required setting is `SECRET_KEY_BASE`, which should be set to a random hex value to be kept secret; a sample value can be generated using Ruby by running `SecureRandom.hex(128)`.

```
RAILS_ENV=production
MYSQL_HOST=db
MYSQL_PASSWORD=root
REDIS_URL=redis://redis:6379
ELASTICSEARCH_URL=elasticsearch:9200

MAILER_SENDER=info@cdx.example.com

SECRET_KEY_BASE=

VIRTUAL_HOST=cdx.example.com

SSH_KEYS_PATH=/home/cdx-sync/.ssh/authorized_keys
SSH_SYNC_DIR=/home/cdx-sync/sync
SSH_SERVER_PORT=2223
SSH_SERVER_HOST=cdx.example.com
```

#### docker-compose.yml

Last but not least, set up the `docker-compose.yml` file for the application stack. The easiest way is to copy both `docker-compose.base.yml` and `docker-compose.prod.yml` from the project root, which contain the base configuration and the overrides for running in a production environment, respectively.

The `docker-compose.prod.yml` assumes there is `data` dir in the same folder as the compose config file, where mysql, elasticsearch and ssh clients will store their persistent data.

Make sure to change the image from `instedd/cdx:dev` to the image you actually want to use for this deployment. You should never work on dev, but [choose a specific tag](https://hub.docker.com/r/instedd/cdx/tags/).

### Attachments

Device models images and instructions are managed via [paperclip](https://github.com/thoughtbot/paperclip).

#### S3

If running on AWS, the recommended configuration is to use S3 for storage, setting the following variables in `docker.env`. The first is the name of the bucket where attachments will be stored, and the remaining two are the credentials used to upload them.
```
PAPERCLIP_S3_BUCKET=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
```

If the S3 bucket is not in the default (`us-east-1`) region, you need to also specify the [bucket's region-specific host name](https://docs.aws.amazon.com/general/latest/gr/s3.html#s3_region):

```
PAPERCLIP_S3_HOST_NAME=s3.us-west-1.amazonaws.com
```

#### Local storage

Alternatively, attachments can be stored locally. Create a folder within the data directory owned by user `9999` and mount it in `/app/public/system`. Assuming the data directory is `/u/apps/cdx/data/uploads`, then:
```bash
mkdir -p /u/apps/cdx/data/uploads
chown 9999:9999 /u/apps/cdx/data/uploads
```

And add the following entry to the `volumes` of the `web` service in `docker-compose.prod.yml`:
```yml
- './data/uploads:/app/public/system'
```
### SMTP

The SMTP server for sending emails is managed via the `SMTP` settings in `docker.env`. It is recommended to set them to an external SMTP server, such as [Google's Gmail](https://support.google.com/a/answer/176600?hl=en); in AWS, we suggest using [SES](https://aws.amazon.com/ses/).

```
SMTP_HOST=
SMTP_PORT=
SMTP_USERNAME=
SMTP_PASSWORD=
```

#### Local SMTP server

Alternatively, to spin up a local SMTP server, add the following configuration to your `docker-compose.prod.yml` file, replacing `cdx.example.com` to your own domain:

```yml
smtp:
  image: catatnight/postfix
  ports:
    - 25
  environment:
    maildomain: cdx.example.com
    smtp_user: cdx:cdx
```

Add a link from the `web` container to the new `smtp`:

```yml
web:
  links:
     - smtp
    ...
```

And set the `SMTP` section of your `docker.env` file to:

```bash
SMTP_HOST=smtp
SMTP_PORT=25
SMTP_USERNAME=cdx
SMTP_PASSWORD=cdx
SMTP_TLS=false
```

### Monitoring

The CDX app already ships with the New Relic agent installed. In order to enable it, set the following environment variables in `docker.env`, using your New Relic license key:

```bash
NEW_RELIC_LOG=stdout
NEW_RELIC_LOG_LEVEL=info
NEW_RELIC_AGENT_ENABLED=1
NEW_RELIC_APP_NAME=CDX
NEW_RELIC_LICENSE_KEY=
```

## Setup

_Note that all docker related commands typically require `sudo` privileges._

After all configuration files are set up, the next step is to set up the database. For the first run only, you need to set up the database from scratch:
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml run --rm web rake db:setup
```

Seed data for manufacturers and institutions can be inserted via, changing `demopass` to the default password to be used for the new created users:
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml run --rm web rake institutions:load manifests:load PASSWORD=demopass
```

Afterwards, run any migrations via:
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml run --rm web rake db:migrate
```

Remember to remove the `-f docker-compose.base.yml -f docker-compose.prod.yml` from all the previous commands if you use a single `docker-compose.yml` file.

## Running

Start or restart the app stack running:
```bash
docker-compose -f docker-compose.base.yml -f docker-compose.prod.yml up -d --force-recreate
```

## Upgrading

To upgrade to a new version of CDX, simply change the tag for the docker image in the docker-compose file; for instance, change `instedd/cdx:0.6` to `instedd/cdx:0.7`.

After the modification, restart the stack via the command listed in the previous section.
