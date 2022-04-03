FROM ruby:2.7-alpine
LABEL version="1.0"
WORKDIR /app
COPY main.rb Gemfile /app/
COPY csv/prices.csv /app/csv/prices.csv
RUN bundler install
CMD [ "ruby", "main.rb" ]