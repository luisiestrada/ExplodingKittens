# config/initializers/pusher.rb
require 'pusher'

Pusher.app_id = '200598'
Pusher.key = '78511c9f413a61ee66ee'
Pusher.secret = '27eebd95d42a57bf55a4'
Pusher.logger = Rails.logger
Pusher.encrypted = true