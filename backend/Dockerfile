FROM ruby:3.1.2-slim AS base

# System deps
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    default-libmysqlclient-dev \
    default-mysql-client \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Gems
COPY Gemfile Gemfile.lock ./
RUN bundle config --global frozen 1 \
    && bundle install --jobs 4 --retry 3 \
    && rm -rf ~/.bundle/cache ~/.gem/cache

# Application code
COPY . .

# Precompile bootsnap for faster boot
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Ensure tmp dirs exist
RUN mkdir -p tmp/pids tmp/cache log

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
