# frozen_string_literal: true

require 'pkce_challenge'

module VolvoAPI
  # Error failure class for refresh token request failures
  class VolvoAPITokenRenewError < StandardError
    attr_reader :response_body

    def initialize(msg, response_body)
      @response_body = response_body
      super(msg)
    end
  end

  # Class to handle authentication with Volvo developer API
  class Auth
    VOLVO_AUTH_URL = 'https://volvoid.eu.volvocars.com/as/authorization.oauth2'
    VOLVO_TOKEN_URL = 'https://volvoid.eu.volvocars.com/as/token.oauth2'
    VOLVO_BATTERY_LEVEL_URL = "https://api.volvocars.com/energy/v1/vehicles/#{ENV['VIN']}/recharge-status/battery-charge-level"

    SCOPES = [
      'openid',
      'energy:battery_charge_level',
      'energy:charging_system_status'
    ].freeze

    def authentication_url
      uri = URI(VOLVO_AUTH_URL)
      uri.query = URI.encode_www_form(
        {
          response_type: 'code',
          client_id: ENV['CLIENT_ID'],
          redirect_uri: ENV['REDIRECT_URI'],
          scope: SCOPES.join(' '),
          code_challenge: pkce_challenge.code_challenge,
          code_challenge_method: 'S256'
        }
      )
      uri
    end

    def exchange_code_for_tokens(code)
      uri = URI(VOLVO_TOKEN_URL)
      body = www_url_encoded_authorization_form(code)

      res = Net::HTTP.post(uri, body, authorization_headers)

      JSON.parse(res.body)
    end

    def renew_tokens(refresh_token)
      uri = URI(VOLVO_TOKEN_URL)
      body = www_url_encoded_refresh_form(refresh_token)

      res = Net::HTTP.post(uri, body, authorization_headers)

      unless res.is_a?(Net::HTTPSuccess)
        raise VolvoAPITokenRenewError.new('Token renewal failure',
                                          JSON.parse(res.body))
      end

      JSON.parse(res.body)
    end

    private

    def pkce_challenge
      @pkce_challenge ||= PkceChallenge.challenge
    end

    def authorization_headers
      authorization = Base64.strict_encode64("#{ENV['CLIENT_ID']}:#{ENV['CLIENT_SECRET']}")

      {
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Authorization' => "Basic #{authorization}"
      }
    end

    def www_url_encoded_authorization_form(code)
      URI.encode_www_form(
        {
          grant_type: 'authorization_code',
          code: code,
          code_verifier: pkce_challenge.code_verifier,
          redirect_uri: ENV['REDIRECT_URI']
        }
      )
    end

    def www_url_encoded_refresh_form(refresh_token)
      URI.encode_www_form(
        {
          grant_type: 'refresh_token',
          refresh_token: refresh_token
        }
      )
    end
  end
end
