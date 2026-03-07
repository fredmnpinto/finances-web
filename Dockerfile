# syntax=docker/dockerfile:1

FROM ruby:3.4.1-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    libpq-dev \
    postgresql-client \
    nodejs \
    git \
    pkg-config \
    libvips \
    && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test"

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
