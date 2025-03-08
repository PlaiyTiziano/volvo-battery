# frozen_string_literal: true

require 'dotenv'
require 'json'
require 'net/http'
require 'base64'
require_relative 'volvo_api/auth'
require_relative 'volvo_api/server'
require_relative 'volvo_api/energy'
require_relative 'utils'

Dotenv.load

BATTERY_LEVEL_CHECK_THRESHOLD = 100
BATTERY_POLLING_INTERVAL = 60
CHARGING_STATUS_INTERVAL = 600

def start_battery_level_polling(energy_service)
  counter = 0

  loop do
    level = energy_service.battery_level
    puts "Battery level is at #{level}%"

    notify_battery_level(level) if level >= 95

    sleep BATTERY_POLLING_INTERVAL

    # Every 100 level checks, break the loop and restart to make sure the car is still charging
    counter += 1
    break if counter > BATCH_LEVEL_CHECK_THRESHOLD
  end

  start
end

def notify_battery_level(level)
  message = "Volvo has charged to #{level}%"
  system("osascript -e 'display notification \"#{message}\" with title \"Volvo\"'")
end

def renew_tokens
  refresh_token = Utils.read_refresh_token

  VolvoAPI::Auth.new.renew_tokens(refresh_token)
end

def initial_authentication
  auth = VolvoAPI::Auth.new
  url = auth.authentication_url

  puts "Please visit: #{url}"

  code = VolvoAPI::Server.new.start_and_wait_for_code

  auth.exchange_code_for_tokens(code)
end

def start(retry_count = 0)
  return puts 'retry count reached' if retry_count > 5

  energy_service = VolvoAPI::Energy.new(ENV['VIN'], Utils.read_access_token)

  sleep CHARGING_STATUS_INTERVAL until energy_service.charging?

  start_battery_level_polling(energy_service)
rescue VolvoAPI::VolvoAPIAuthError
  renew_tokens

  start(retry_count + 1)
end

begin
  tokens = Utils.refresh_token_exists? ? renew_tokens : initial_authentication

  Utils.write_tokens_to_files(tokens)

  start
rescue VolvoAPI::VolvoAPITokenRenewError => e
  puts 'Failed to renew tokens'
  puts e.response_body
end
