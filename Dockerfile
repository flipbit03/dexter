FROM ruby:3.3.0-alpine3.19

RUN apk add --update make gcc musl-dev build-base libpq-dev && \
    rm -rf /var/cache/apk/*

COPY . /app

WORKDIR /app

RUN bundle install

ENTRYPOINT ["bundle", "exec", "dexter"]
