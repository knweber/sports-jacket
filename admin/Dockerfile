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
CMD ["puma"]

# update bundler to prevent errors concerning the lockfile
RUN gem install --no-document bundler
COPY Gemfile Gemfile.lock /app/
RUN bundle install --deployment
COPY ./ /app/

WORKDIR /app/admin/
