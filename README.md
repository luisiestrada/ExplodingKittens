# Exploding Kittens

Exploding Kittens is an online turn-based card game developed using
the Ruby on Rails web framework, based on the [card game of the same
name](https://explodingkittens.com) published by The Oatmeal.

### Installation:
Ruby version used: `2.4.1`.

With Ruby installed, install Rails using `gem install rails`
and run `bundle install` to install all other necessary gems.

##### Extra steps
If you're on Ubuntu, here are some extra steps you may need:
```
sudo apt-get install postgresql
sudo su - postgres
service postgresql start
psql -d postgres -U postgres
create database kittens_development;
create user kittens with password 'password1';
export PGHOST=localhost
```
Exit this window using ctrl+D, then switch back to your role with: `su - your_username`.
Then navigate to the ExplodingKittens directory and run: `rake db:schema:load`.

### Running the application
Run `rails s` to start the application and navigate to
`localhost:3000` in your browser to view the website.
Create an account and you're ready to play! (requires 2 players)

#### Technologies:
* Ruby, HTML, CSS, JavaScript
* Frameworks/Libraries: Ruby on Rails, Bootstrap, jQuery
* Tools: Git, GitHub, Heroku
* Gems: PostgreSQL, Devise, Pusher

#### See more:
* [Final presentation slides](https://goo.gl/uqdOK1)

#### Note:
The game was developed strictly for educational purposes.
Seeing as the real game's card images (assets) were used,
the game is not hosted anywhere online.
