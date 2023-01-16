# CDX

Reference implementation for the Connected Diagnostics API (http://dxapi.org/)

## CDX Core Server. Getting Started

### Development environment (with Docker)

1. Clone the repo.

2. Install Docker.

3. Install `gems`:
	```
	$ docker-compose build
	$ docker-compose run --rm web bundle install
	```

4. Setup development db, test db and elasticsearch index template:
	```
	$ docker-compose run --rm web rake db:setup db:test:prepare elasticsearch:setup
	```

### Additionally setup for importing Loinc Codes

1. Import Loinc Codes
	```
	$ docker-compose run --rm web rails r script/loinc_codes/import_csv.rb
	```

### Creating your first user in localhost
1. Go to http://localhost:3000
2. Create your account
3. You won't receive the email.  Instead, you can confirm your account by following the steps below
4. With the container up, run this command ```docker-compose exec web bash```
5. Then run this command ```rails c```
6. Then run this command ```User.last.confirm!```

This will confirm the last user that was created in your local environment.  Then you should be able to Login normally.


### Additionally setup for working with devices

1.  With the container up, run this command ```docker-compose exec web bash```.

2. Then run this command ```export PASSWORD=XXXX``` (defining a password at least 8 characters long)

3. Import manifests: `bundle exec rake manifests:load`

To create an initial set of tests:

4. Navigate to the application

5. Create a new account and sign in

6. Create a new institution

7. Create a new site

8. Create a new device, choosing Genoscan model

9. Navigate to `/api/playground`

10. Select your newly created device

11. Copy the contents of `/spec/fixtures/csvs/genoscan_sample.csv` into the _Data_ field

12. Run create message and navigate to _Tests_ to verify the tests were successfully imported

### Running the environment

```
$ docker-compose up
```

### Useful commands

```
# Open a terminal in the web server directory
$ docker-compose exec web bash

# Reload web server container
$ docker-compose restart web
```

### Locations setup

Locations are obtained from the [InSTEDD Location Service](https://github.com/instedd/location_service). You can specify a different path in config/settings/development.yml.local

### NNDD

To run [notifiable diseases](https://github.com/instedd/notifiable-diseases) on development, checkout the project and symlink the custom settings files in `/etc/nndd` on this project:

    $ cd $NOTIFIABLE_DISEASES/conf
    $ ln -s $CDP/etc/nndd/overrides.js overrides.js
    $ ln -s $CDP/etc/nndd/overrides.css overrides.css

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

### Legacy setup (local installation, without Docker)
1. Clone the repo.

2. Install dependencies:
	* `bundle install`.
	* ImageMagick for [Paperclip](https://github.com/thoughtbot/paperclip#image-processor)
		* Install it in mac with: `brew install imagemagick`
	* [Redis](http://redis.io/download) is [used](https://github.com/mperham/sidekiq/wiki/Using-Redis) by [sidekiq](http://sidekiq.org/). CDX uses sidekiq as [ActiveJob](http://guides.rubyonrails.org/active_job_basics.html#backends) backend
		* Install it in mac with: `brew install redis`
		* you can start it with `redis-server --daemonize yes`
	* [Elasticsearch](https://www.elastic.co/) is used as the main index for test results.
		* We support elasticsearch versions < 2.x
		* Install it in mac with: `brew install elasticsearch17`

3. Setup development database: `bundle exec rake db:setup`

4. Setup test database: `bundle exec rake db:test:prepare`

5. Setup elasticsearch index template: `bundle exec rake elasticsearch:setup`

6. Run tests: `bundle exec rake` (this will run `rspec` and `cucumber`)

7. Start development server: `bundle exec rails s`

## Screen resolutions

The minimum supported screen resolution is 1366x768.
Mobile devices and screen resolutions less than 1366x768 are not supported.

## Supported browsers

The supported browsers are: Google Chrome, Safari, Firefox.
It's recomended to use the latest version of the browser.

## Tests

### Unit tests

Unit tests are written in rspec and can be run inside the docker container:

```console
$ docker compose run --rm web bash
> rspec
```

You may only run specs inside a directory or file by specifying it on the
command line. You may even specify a line to target a single test. For example:

```console
$ docker compose run --rm web bash
> rspec spec/controllers
> rspec spec/controllers/samples_controller_test.rb
> rspec spec/controllers/samples_controller_test.rb:26
```

The test suite is particularly slow, but we can reduce the runtime a bit by
running it in parallel. For example to split the test suite in 2 parts (you can
replace 2 with 3, 4 or more) and only run the unit tests and skip the system
tests:

```console
$ docker compose run --rm web bash
> bin/rails parallel:setup[2]
> parallel_rspec -n 2 spec/ --exclude-pattern spec/features/
```


### System tests

System tests are regular rspec tests using the
[SitePrism](https://github.com/site-prism/site_prism). Under the hood this
is basically Capybara and Selenium Webdriver.

System tests are grouped under `spec/features`. There are some legacy Cucumber
tests under `/features` (kept until we can rewrite them).

Specs usually don't interact with Capybara and the browser directly but through
page objects using the [SitePrism](https://github.com/site-prism/site_prism)
abstraction library: the page object describes how to access the different
resources and the tests then use these to open pages, navigate, fill and submit
form. Those pages are located under `features/support/page_objects`.

#### Headless

By default system tests are configured to run in headless Firefox ESR docker
containers that must be started.

By default we start 2 instances, if you're using `parallel_rspec` make sure to
scale as many as required in a `docker-compose.override.yml` file. You'll may
also want to scale it down to 1:

```yaml
version: "2.4"

services:
  selenium:
    scale: 4
```

You can then run headless system tests inside a docker container:

```console
$ docker compose up -d selenium
$ docker compose run --rm web bash
> rspec spec/features/*
> rspec spec/features/my_spec.rb
> cucumber
```

#### Visible

When writing or debugging system tests, you'll likely want to run tests in a
visible browser. You should install and run `geckodriver` and/or `chromedriver`
on your host and make sure it's available on an IP that the docker containers
can reach. For example once of:

```
$ geckodriver --host 0.0.0.0
$ chromedriver --allowed-ips 0.0.0.0
```

Then export environment variables before running tests. For example (make sure
to replace `your.host.ip` with an actual IP on your host:

```console
$ docker compose run --rm web bash
> export HEADLESS=false
> export SELENIUM_URL=http://your.host.ip:4444/
> rspec spec/features/*
> cucumber
```

You may also target another browser (by default it's Firefox), for example
Chrome with:

```console
> export BROWSER=chrome
```

If you want system tests to always run visible on a host browser, you can set
the environment variables in your `docker-compose.override.yml`. For example:

```yaml
version: "2.4"

services:
  web:
    environment:
      HEADLESS: "false"
      SELENIUM_URL: "http://<your.host.ip>:4444/"
      BROWSER: "chrome" # or "firefox"
```

Then run tests as per the above:
```console
$ docker compose run --rm web bash
> rspec spec/features/my_spec.rb
```
