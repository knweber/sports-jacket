FROM ruby:2.4.0

MAINTAINER FamBrands

EXPOSE 5678 9292

ENV RACK_ENV=production
ENV APP_NAME=production_pull
ENV DATABASE_URL=""
ENV RECHARGE_ACCESS_TOKEN=""
ENV RECHARGE_SLEEP_TIME=1
ENV REDIS_URL=""

VOLUME /app/logs
WORKDIR /app

# update bundler to prevent errors concerning the lockfile
RUN gem install bundler
ADD Gemfile Gemfile.lock /app/
RUN bundle install --deployment
ADD admin Rakefile config admin.ru /app/

ENTRYPOINT ["puma", "-C", "config/puma-admin.rb"]
