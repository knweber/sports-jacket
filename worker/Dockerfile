FROM ruby:2.4.0

MAINTAINER FamBrands

ENV RACK_ENV=production
ENV APP_NAME=production_pull
ENV DATABASE_URL=""
ENV RECHARGE_ACCESS_TOKEN=""
ENV RECHARGE_SLEEP_TIME=1
ENV REDIS_URL=""
ENV QUEUE="*"

VOLUME /app/logs
WORKDIR /app
CMD ["rake", "resque:work"]

# update bundler to prevent errors concerning the lockfile
RUN gem install --no-document bundler
ADD Gemfile Gemfile.lock /app/
RUN bundle install --deployment
COPY ./ /app/
