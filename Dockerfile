FROM instedd/nginx-rails:2.2

# Install prerequisites
RUN \
  apt-get update && \
  apt-get install -y libzmq3-dev sudo && \
  apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
RUN bundle install --jobs 8 --deployment --without development test

# Install the application
ADD . /app

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Set permissions for tmp and log directories
RUN mkdir -p /app/tmp /app/log && chown -R nobody:nogroup /app/tmp /app/log

# Add config files
ADD docker/web-run /etc/service/web/run
