FROM ruby:2.4.0

MAINTAINER FamBrands

ENV RACK_ENV=production
ENV APP_NAME=production_pull
ENV DATABASE_URL=""
ENV RECHARGE_ACCESS_TOKEN=""
ENV RECHARGE_SLEEP_TIME=1
ENV REDIS_URL=""
ENV QUEUE="default"

VOLUME /app/logs
WORKDIR /app

# update bundler to prevent errors concerning the lockfile
RUN gem install bundler
ADD Rakefile Gemfile Gemfile.lock /app/
RUN bundle install --deployment
COPY ./ /app/

CMD ["rake", "resque:work"]
