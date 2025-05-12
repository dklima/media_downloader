# frozen_string_literal: true

class MediaQueueConsumer
  attr_accessor :rabbitmq_client

  def initialize(rabbitmq_client = RabbitmqClient.new)
    CheckExternalDependencies.verify
    self.rabbitmq_client = rabbitmq_client
  end

  def start
    setup_signal_handlers
    process_messages
  rescue Interrupt
    shutdown
  rescue StandardError => e
    puts "[!] Error: #{e.message}"
    shutdown
    exit(1)
  end

  private

  def setup_signal_handlers
    %w[INT TERM].each do |signal|
      Signal.trap(signal) do
        shutdown
        exit(0)
      end
    end
  end

  def process_messages
    puts '[*] Waiting for messages. To exit press CTRL+C'

    rabbitmq_client.subscribe({ prefetch: 1, block: true }) do |delivery_info, _properties, body|
      process_message(delivery_info:, body:)
    end
  end

  def process_message(delivery_info:, body:)
    puts " [x] Received message #{body}"
    MediaDownloader.new(body).call
    puts ' [x] Done'
    rabbitmq_client.ack(delivery_info.delivery_tag)
  rescue StandardError => e
    puts " [!] Message processing failed: #{e.message}"
    # Consider implementing a dead letter strategy or retries here
    rabbitmq_client.reject(delivery_info.delivery_tag, false) # Don't requeue failed messages
  end

  def shutdown
    puts '[*] Shutting down...'
    rabbitmq_client&.close
  end
end
