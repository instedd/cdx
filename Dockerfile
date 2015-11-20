FROM instedd/nginx-rails:2.2

## Create a user for the web app.
RUN \
  addgroup --gid 9999 app && \
  adduser --uid 9999 --gid 9999 --disabled-password --gecos "Application" app && \
  usermod -L app

ENV POIROT_STDOUT true
ENV POIROT_SUPPRESS_RAILS_LOG true

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

# Add config files
ADD docker/web-run /etc/service/web/run
