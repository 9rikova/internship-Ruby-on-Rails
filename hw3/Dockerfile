FROM ruby:2.7-alpine
LABEL version="1.0"
WORKDIR /app
COPY main.rb /app/
COPY csv/* /app/csv/
CMD [ "ruby", "main.rb", "-a" ]