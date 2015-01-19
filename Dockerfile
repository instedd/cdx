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

# Prepare application directory
RUN mkdir /app
WORKDIR /app

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 8 --deployment --without development test

# Install the application
ADD . /app
RUN mkdir -p /app/tmp && chown -R app:app /app/tmp

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

EXPOSE 80
