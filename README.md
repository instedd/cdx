[![Build Status](https://travis-ci.org/instedd/cdp.svg?branch=master)](https://travis-ci.org/instedd/cdp)

# README

Reference implementation for the Connected Diagnostics API (http://dxapi.org/)

## Getting Started

### CDX Core Server

To start developing:

1. Clone the repo.

2. Install dependencies:
  ```
    bundle install
  ```
3. Setup development database:
  ```
    bundle exec rake db:setup
  ```
4. Setup test database:
  ```
    bundle exec rake db:test:prepare
  ```
5. Run tests:
  ```
    bundle exec rspec
  ```
6. Start development server:
  ```
    bundle exec rails s
  ```

### Sync Server

In order to allow synchronization of clients through rsyns - for csv files -, you should use [cdx-sync-sshd](https://github.com/instedd/cdx-sync-sshd), which is a dockerized sshd container, with an inbox and outbox directoy for each client. Download and build it before continuing.

You have to mount sshd volumes pointing to the folders where you will store your authorized keys, server keys and sync directory.  Although sshd-server runs standalone and independently of the cdx server, the cdx server needs to be aware of such directories:
 * ```SYNC_HOME```: here is where files from clients wil be sync'ed. The file watcher will monitor inbox files here
 * ```SYNC_SSH```: here is where ```authorized_keys``` file will be stored. The cdx app will write such file on this directory whenever a new ssh keys is added to a device.

By default, the cdx app assumes such directories will point to the tmp directory of the cdp app. Thus, you should start the cdx-sync-sshd docker container this way:

```
  cd <where you have cloned cdx-sync-server>
  export CDP_PATH=<where you have cloned this cdp repository>
  make testrun SYNC_HOME=$CDP_PATH/tmp/sync \
               SYNC_SSH=$CDP_PATH/tmp/.ssh
```

### Sync File Watcher

Now you must start the sync filewatcher. It is based on [cdx-sync-server](https://github.com/instedd/cdx-sync-server), but already bundled into cdx app. Run the following:

```
 cd $CDX_PATH
 rake csv:watch
```

Now, whenever a new csv file enters the sshd inbox, it will be imported into the cdx platform.

### Sync File Watcher - Client Side

In the client side, you will need to run another filewatcher: [cdx-sync-client](https://github.com/instedd/cdx-sync-client). It is a Windos App. Install it using its NSI installer, restart your computer, and fill the form that will prompt after first restart.  You will be required to provide an activation token - you can generate it form the device manager in the CDP app.

