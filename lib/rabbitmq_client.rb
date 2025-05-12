# frozen_string_literal: true

class RabbitmqClient
  attr_accessor :connection, :channel

  QUEUE_NAME = Config.rabbitmq_queue
  private_constant :QUEUE_NAME

  def initialize
    self.connection = RabbitmqConnection.new
    self.channel = connection.create_channel
  end

  def publish(options = {}, message)
    default_options = { durable: true, persistent: true }
    options = default_options.merge(options)

    queue = channel.queue(QUEUE_NAME, durable: options[:durable])
    queue.publish(message.to_json, persistent: options[:persistent])
  end

  def subscribe(options = {}, &block)
    default_options = { durable: true, manual_ack: true, block: true }
    options = default_options.merge(options)
    channel.prefetch(options[:prefetch]) if options[:prefetch]

    queue = channel.queue(QUEUE_NAME, durable: options[:durable])
    queue.subscribe(manual_ack: options[:manual_ack], block: options[:block], &block)
  end

  def ack(delivery_tag)
    channel.ack(delivery_tag)
  end

  def reject(delivery_tag, requeue = false)
    channel.reject(delivery_tag, requeue)
  end

  def close
    connection.close if connection
  end
end
