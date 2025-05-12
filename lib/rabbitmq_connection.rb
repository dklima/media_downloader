# frozen_string_literal: true

class RabbitmqConnection
  attr_accessor :connection

  def initialize
    self.connection = create_connection
  end

  def create_channel
    raise 'Not connected to RabbitMQ' unless connected?

    connection.create_channel
  end

  def connected?
    connection&.connected?
  end

  def close
    connection.close if connected?
  end

  def reconnect
    close
    self.connection = create_connection
  end

  private

  def create_connection
    Bunny.new(host: Config.rabbitmq_host,
              port: Config.rabbitmq_port,
              user: Config.rabbitmq_user,
              pass: Config.rabbitmq_pass,
              vhost: Config.rabbitmq_vhost).start
  rescue Bunny::TCPConnectionFailed, Bunny::AuthenticationFailureError => e
    raise "Failed to connect to RabbitMQ: #{e.message}"
  end
end
