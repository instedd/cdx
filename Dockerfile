FROM phusion/passenger-ruby20

# Install prerequisites
RUN \
  apt-get update && \
  apt-get install -y nodejs libzmq3-dev && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup nginx / passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD docker/nginx-app.conf /etc/nginx/sites-enabled/app.conf
ADD docker/nginx-env.conf /etc/nginx/main.d/env.conf

# Setup daemons
RUN mkdir /etc/service/subscribers
ADD docker/subscribers.sh /etc/service/subscribers/run
RUN mkdir /etc/service/csv_watch
ADD docker/csv_watch.sh /etc/service/csv_watch/run

# Prepare application directory
RUN mkdir /app
WORKDIR /app

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 8 --deployment --without development test

# Install the application
ADD . /app

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Set permissions for tmp and log directories
RUN mkdir -p /app/tmp /app/log && chown -R app:app /app/tmp /app/log

EXPOSE 80
