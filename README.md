# GoPlan API server

This repo is the API server of GoPlan, this API server is to serve content to the GoPlan Web client. You can find the GoPlan Web client repo [here](https://github.com/goooooouwa/goplan-web).

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

## How to deploy to production with Docker

1. `cp .env.production.example .env`
2. Modify `.env` to suit your docker deployment preferences
3. `sudo docker compose build`
4. `sudo docker compose up`
5. `sudo docker exec <container> /bin/bash -c 'bundle exec rake db:create'`
6. `sudo docker exec <container> /bin/bash -c 'bundle exec rake db:migrate'`
7. `sudo docker exec <container> /bin/bash -c 'bundle exec rake db:seed'`

Please note, in production, AdminUser won't be created automatically for security reasons. You need to manually create a AdminUser in Rails console with the following commands:

1. `sudo docker exec -it <container> /bin/bash -c 'bundle exec rails c'`
2. `AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password')`

Now, you can finish the steps in "Additional setup steps after server is run" section.

## How to test

`bundle exec rspec`
