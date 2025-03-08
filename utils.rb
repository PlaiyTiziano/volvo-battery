# frozen_string_literal: true

# Some utils module with general utilities
class Utils
  def self.read_access_token
    path = "#{ENV['TOKEN_STORAGE_PATH']}/battery_access_token"
    File.read(path)
  end

  def self.read_refresh_token
    path = "#{ENV['TOKEN_STORAGE_PATH']}/battery_refresh_token"
    File.read(path)
  end

  def self.refresh_token_exists?
    File.exist?("#{ENV['TOKEN_STORAGE_PATH']}/battery_refresh_token")
  end

  def self.write_tokens_to_files(token_info)
    write_token_to_file(
      type: :access_token,
      token: token_info['access_token']
    )
    write_token_to_file(
      type: :refresh_token,
      token: token_info['refresh_token']
    )
  end

  def self.write_token_to_file(type:, token:)
    path = "#{ENV['TOKEN_STORAGE_PATH']}/battery_#{type}"
    File.write(path, token)
  end
end
