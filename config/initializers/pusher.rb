# config/initializers/pusher.rb
require 'pusher'

Pusher.app_id = Settings.pusher.app_id
Pusher.key = Settings.pusher.key
Pusher.secret = Settings.pusher.secret
Pusher.logger = Rails.logger
Pusher.encrypted = Settings.pusher.encrypted
