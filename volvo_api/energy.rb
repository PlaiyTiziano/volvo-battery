# frozen_string_literal: true

module VolvoAPI
  # General error class for authentication failures coming from the Volvo API
  class VolvoAPIAuthError < StandardError
    attr_reader :response_body

    def initialize(msg, response_body)
      @response_body = response_body
      super(msg)
    end
  end

  # Class to handle energy related API calls
  class Energy
    BATTERY_LEVEL_URL = 'https://api.volvocars.com/energy/v1/vehicles/%s/recharge-status/battery-charge-level'
    CHARGING_STATUS_URL = 'https://api.volvocars.com/energy/v1/vehicles/%s/recharge-status/charging-system-status'

    CHARGING_STATUSES = {
      charging: 'CHARGING_SYSTEM_CHARGING',
      idle: 'CHARGING_SYSTEM_IDLE',
      done: 'CHARGING_SYSTEM_DONE',
      fault: 'CHARGING_SYSTEM_FAULT',
      scheduled: 'CHARGING_SYSTEM_SCHEDULED',
      unspecified: 'CHARGING_SYSTEM_UNSPECIFIED'
    }.freeze

    def initialize(vin, access_token)
      @vin = vin
      @access_token = access_token
    end

    def battery_level
      request_battery_level
    end

    def charging?
      request_charging_status == CHARGING_STATUSES[:charging]
    end

    private

    def request_battery_level
      uri = URI(BATTERY_LEVEL_URL % @vin)

      response = Net::HTTP.get_response(uri, energy_headers)
      response_body = JSON.parse(response.body)

      raise VolvoAPIAuthError.new('Authentication failure', response_body) unless response.is_a?(Net::HTTPSuccess)

      response_body['data']['batteryChargeLevel']['value'].to_i
    end

    def request_charging_status
      uri = URI(CHARGING_STATUS_URL % @vin)

      response = Net::HTTP.get_response(uri, energy_headers)
      response_body = JSON.parse(response.body)

      raise VolvoAPIAuthError.new('Authentication failure', response_body) unless response.is_a?(Net::HTTPSuccess)

      status = response_body['data']['chargingSystemStatus']['value']

      puts "Charge status: #{status}"

      status
    end

    def energy_headers
      {
        accept: 'application/vnd.volvocars.api.energy.vehicledata.v1+json',
        authorization: "Bearer #{@access_token}",
        "vcc-api-key": ENV['VCC_API_KEY']
      }
    end
  end
end
