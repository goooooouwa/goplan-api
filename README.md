# GoPlan API server

GoPlan web client: [https://github.com/goooooouwa/goplan-web](https://github.com/goooooouwa/goplan-web)

## How to setup local development environment

1. `bundle install`
2. `cp .env.development.example .env`
3. Modify `.env` to suit your local development preferences
4. `bundle exec rake db:create`
5. `bundle exec rake db:migrate`
6. `bundle exec rake db:seed`

## How to run

4. `bundle exec rails s -p [PORT]`

This will run the server in the development mode with the port you specify.

## Additional setup steps after server is run

1. Go to OAuth applications page, e.g. http://localhost:8000/oauth/applications with initial admin username & password found in `db/seed.rb`
2. Create a new application with the information defined in the corresponding GoPlan Web env file, e.g.:
    - Name: GoPlan Web
    - Redirect URI: http://localhost:3000/callback
    - Confidential: uncheck
    - Scopes: write
3. Copy the application UID and save it as REACT_APP_CLIENT_ID in the corresponding GoPlan Web env file
4. Open the API server login page, e.g. http://localhost:8000/users/sign_in to sign up a user account
5. Start GoPlan Web server, login and start using GoPlan.

## How to test

`bundle exec rspec`

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
