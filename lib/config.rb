# frozen_string_literal: true

# Config class for application configuration
# The priority is given to ENV variables over config file values
class Config
  RABBITMQ = 'rabbitmq'
  DOWNLOADER = 'downloader'
  private_constant :RABBITMQ, :DOWNLOADER

  def self.load_config
    config_file = YAML.load_file('config.yml')
    (config_file.is_a?(Array) ? config_file.reduce({}, :merge) : config_file)
  rescue Errno::ENOENT, Psych::SyntaxError => e
    raise "Configuration error: #{e.message}"
  end

  CONFIG = load_config
  private_constant :CONFIG

  def self.env_or_config(env_key, section, key)
    ENV[env_key] || CONFIG[section][key] || raise("Missing configuration for #{section}.#{key}")
  end

  def self.rabbitmq_host
    env_or_config('RABBITMQ_HOST', RABBITMQ, 'host')
  end

  def self.rabbitmq_port
    env_or_config('RABBITMQ_PORT', RABBITMQ, 'port')
  end

  def self.rabbitmq_user
    env_or_config('RABBITMQ_USER', RABBITMQ, 'user')
  end

  def self.rabbitmq_pass
    env_or_config('RABBITMQ_PASS', RABBITMQ, 'pass')
  end

  def self.rabbitmq_vhost
    env_or_config('RABBITMQ_VHOST', RABBITMQ, 'vhost')
  end

  def self.rabbitmq_queue
    env_or_config('RABBITMQ_QUEUE', RABBITMQ, 'queue')
  end

  def self.downloader_path
    env_or_config('DOWNLOADER_PATH', DOWNLOADER, 'path')
  end
end
