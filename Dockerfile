FROM ruby:2.4

# Cleanup expired Let's Encrypt CA (Sept 30, 2021)
RUN sed -i '/^mozilla\/DST_Root_CA_X3/s/^/!/' /etc/ca-certificates.conf && update-ca-certificates -f

RUN apt-get update && \
    apt-get install -y cron && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create a user for the web app.
RUN addgroup --gid 9999 app && \
    adduser --uid 9999 --gid 9999 --disabled-password --gecos "Application" app && \
    usermod -L app

# Application directory
RUN mkdir /app
WORKDIR /app

# Configuration
ARG gemfile=Gemfile
ENV BUNDLE_GEMFILE=${gemfile}
ENV PUMA_OPTIONS "--preload -w 4 -p 3000"
ENV NNDD_VERSION "cdx-0.11-pre7"
ENV RAILS_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

# Install gem bundle
COPY Gemfile* cdx.gemspec cdx-api-elasticsearch.gemspec /app/
COPY deps/ /app/deps/
RUN bundle install --jobs 8 --deployment --without development test

# Install the application
ADD . /app

# Precompile assets
RUN bundle exec rake assets:precompile RAILS_ENV=${RAILS_ENV}

# Download NNDD
RUN mkdir -p /app/public/ && \
    curl -L https://github.com/instedd/notifiable-diseases/releases/download/$NNDD_VERSION/nndd.tar.gz | tar -xzv -C /app/public/

# Configure NNDD
RUN /app/docker/config-nndd

# Set permissions for tmp and log directories
RUN mkdir -p /app/tmp /app/log && chown -R app:app /app/tmp /app/log

EXPOSE 3000
CMD ["/app/docker/web-run"]
