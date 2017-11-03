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

ADD . /app
#ADD https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py /tmp
#ADD https://github.com/postmodern/ruby-install/archive/master.tar.gz /tmp/ruby-install.tar.gz
WORKDIR /app
# update bundler to prevent errors concerning the lockfile
RUN gem install bundler
# needed to install awslogs
#RUN apt-get update && apt-get install -y python3
RUN bundle install --deployment
#RUN python3 /tmp/awslogs-agent-setup.py -n -r $AWS_REGION -c /app/config/awslogs.conf

ENTRYPOINT /app/entrypoint.sh
