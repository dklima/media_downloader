# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require 'yaml'
require_relative '../../lib/loader'

class TestConfig < Minitest::Test
  def setup
    %w[RABBITMQ_HOST RABBITMQ_PORT RABBITMQ_USER RABBITMQ_PASS RABBITMQ_VHOST RABBITMQ_QUEUE
       DOWNLOADER_PATH].each do |env_var|
      ENV.delete(env_var)
    end

    # Mock for config.yml
    @config_data = {
      'rabbitmq' => {
        'host' => 'localhost',
        'port' => '5672',
        'user' => 'guest',
        'pass' => 'guest',
        'vhost' => '/',
        'queue' => 'downloads'
      },
      'downloader' => {
        'path' => '/tmp/downloads'
      }
    }
  end

  def test_load_config_success
    # Mock YAML.load_file
    YAML.stubs(:load_file).returns(@config_data)
    config = Config.send(:load_config)

    assert_equal @config_data, config
  end

  def test_load_config_with_array
    array_config = [
      { 'rabbitmq' => { 'user' => 'guest', 'pass' => 'guest', 'vhost' => '/', 'queue' => 'download_queue',
                        'host' => 'localhost', 'port' => '5672' } },
      { 'downloader' => { 'path' => '/tmp/downloads' } }
    ]
    expected_merged = {
      'rabbitmq' => {
        'host' => 'localhost',
        'port' => '5672',
        'user' => 'guest',
        'pass' => 'guest',
        'vhost' => '/',
        'queue' => 'download_queue'
      },
      'downloader' => {
        'path' => '/tmp/downloads'
      }
    }

    YAML.stubs(:load_file).returns(array_config)
    config = Config.send(:load_config)

    assert_equal expected_merged, config
  end

  def test_load_config_file_not_found
    YAML.stubs(:load_file).raises(Errno::ENOENT.new('No such file or directory'))
    error = assert_raises(RuntimeError) { Config.send(:load_config) }

    assert_match(/Configuration error: No such file or directory/, error.message)
  end

  def test_load_config_invalid_yaml
    syntax_error = Psych::SyntaxError.new('file', 1, 1, 0, 'syntax error', 'context')
    YAML.stubs(:load_file).raises(syntax_error)
    error = assert_raises(RuntimeError) { Config.send(:load_config) }

    assert_match(/Configuration error: .* syntax error/, error.message)
  end

  def test_env_or_config_env_priority
    ENV['RABBITMQ_HOST'] = 'env_host'

    old_config = Config.const_get(:CONFIG)
    Config.send(:remove_const, :CONFIG)
    Config.const_set(:CONFIG, @config_data)

    begin
      result = Config.send(:env_or_config, 'RABBITMQ_HOST', 'rabbitmq', 'host')

      assert_equal 'env_host', result
    ensure
      # restore original CONFIG
      Config.send(:remove_const, :CONFIG)
      Config.const_set(:CONFIG, old_config)
    end
  end

  def test_env_or_config_fallback_to_config
    old_config = Config.const_get(:CONFIG)
    Config.send(:remove_const, :CONFIG)
    Config.const_set(:CONFIG, @config_data)

    begin
      result = Config.send(:env_or_config, 'RABBITMQ_HOST', 'rabbitmq', 'host')

      assert_equal 'localhost', result
    ensure
      Config.send(:remove_const, :CONFIG)
      Config.const_set(:CONFIG, old_config)
    end
  end

  def test_env_or_config_missing_value
    incomplete_config = { 'rabbitmq' => {} }

    old_config = Config.const_get(:CONFIG)
    Config.send(:remove_const, :CONFIG)
    Config.const_set(:CONFIG, incomplete_config)

    begin
      error = assert_raises(RuntimeError) do
        Config.send(:env_or_config, 'RABBITMQ_HOST', 'rabbitmq', 'host')
      end
      assert_match(/Missing configuration for rabbitmq.host/, error.message)
    ensure
      Config.send(:remove_const, :CONFIG)
      Config.const_set(:CONFIG, old_config)
    end
  end

  def with_temp_config(config_data)
    old_config = Config.const_get(:CONFIG)
    Config.send(:remove_const, :CONFIG)
    Config.const_set(:CONFIG, config_data)

    yield
  ensure
    Config.send(:remove_const, :CONFIG)
    Config.const_set(:CONFIG, old_config)
  end

  # Config methods test
  def test_rabbitmq_host
    ENV['RABBITMQ_HOST'] = 'test_host'

    with_temp_config(@config_data) do
      assert_equal 'test_host', Config.rabbitmq_host

      ENV.delete('RABBITMQ_HOST')

      assert_equal 'localhost', Config.rabbitmq_host
    end
  end

  def test_rabbitmq_port
    ENV['RABBITMQ_PORT'] = '15672'

    with_temp_config(@config_data) do
      assert_equal '15672', Config.rabbitmq_port

      ENV.delete('RABBITMQ_PORT')

      assert_equal '5672', Config.rabbitmq_port
    end
  end

  def test_rabbitmq_user
    ENV['RABBITMQ_USER'] = 'admin'

    with_temp_config(@config_data) do
      assert_equal 'admin', Config.rabbitmq_user

      ENV.delete('RABBITMQ_USER')

      assert_equal 'guest', Config.rabbitmq_user
    end
  end

  def test_rabbitmq_pass
    ENV['RABBITMQ_PASS'] = 'secret'

    with_temp_config(@config_data) do
      assert_equal 'secret', Config.rabbitmq_pass

      ENV.delete('RABBITMQ_PASS')

      assert_equal 'guest', Config.rabbitmq_pass
    end
  end

  def test_rabbitmq_vhost
    ENV['RABBITMQ_VHOST'] = '/test'

    with_temp_config(@config_data) do
      assert_equal '/test', Config.rabbitmq_vhost

      ENV.delete('RABBITMQ_VHOST')

      assert_equal '/', Config.rabbitmq_vhost
    end
  end

  def test_rabbitmq_queue
    ENV['RABBITMQ_QUEUE'] = 'test_queue'

    with_temp_config(@config_data) do
      assert_equal 'test_queue', Config.rabbitmq_queue

      ENV.delete('RABBITMQ_QUEUE')

      assert_equal 'downloads', Config.rabbitmq_queue
    end
  end

  def test_downloader_path
    ENV['DOWNLOADER_PATH'] = '/var/downloads'

    with_temp_config(@config_data) do
      assert_equal '/var/downloads', Config.downloader_path

      ENV.delete('DOWNLOADER_PATH')

      assert_equal '/tmp/downloads', Config.downloader_path
    end
  end
end
