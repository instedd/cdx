FROM instedd/nginx-rails:2.2

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN \
  apt-get update && \
  apt-get install -y \
    cron \
    # wkhtmltopdf dependencies \
    xfonts-75dpi \
    xfonts-base \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# wkhtmltopdf
RUN \
  curl -L https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.jessie_amd64.deb --output wkhtmltopdf.deb && \
    dpkg -i wkhtmltopdf.deb && \
    rm -f wkhtmltopdf.deb

## Create a user for the web app.
RUN \
  addgroup --gid 9999 app && \
  adduser --uid 9999 --gid 9999 --disabled-password --gecos "Application" app && \
  usermod -L app

ENV POIROT_STDOUT true
ENV POIROT_SUPPRESS_RAILS_LOG true
ENV PUMA_OPTIONS "--preload -w 4"
ENV NNDD_VERSION "cdx-0.11-pre7"

# Install gem bundle
ADD Gemfile /app/
ADD Gemfile.lock /app/
ADD cdx.gemspec /app/
ADD cdx-api-elasticsearch.gemspec /app/
ADD deps/ /app/deps/

RUN bundle install --jobs 8 --deployment --without development test

# Install the application
ADD . /app

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# Download NNDD
RUN \
  mkdir -p /app/public/ && \
  curl -L https://github.com/instedd/notifiable-diseases/releases/download/$NNDD_VERSION/nndd.tar.gz | tar -xzv -C /app/public/

# Configure NNDD
RUN /app/docker/config-nndd

# Set permissions for tmp and log directories
RUN mkdir -p /app/tmp /app/log && chown -R app:app /app/tmp /app/log

# Add config files
ADD docker/web-run /etc/service/web/run
