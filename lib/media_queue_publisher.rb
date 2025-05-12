# frozen_string_literal: true

class MediaQueuePublisher
  attr_accessor :message, :rabbitmq_client

  def initialize(message, rabbitmq_client = RabbitmqClient.new)
    self.rabbitmq_client = rabbitmq_client
    self.message = message
  end

  def run
    result = publish_message
    display_confirmation if result
    result
  end

  private

  def publish_message
    rabbitmq_client.publish(message)
  ensure
    rabbitmq_client.close
  end

  def display_confirmation
    puts '✅ Successfully sent to processing queue:'
    puts message
  end
end
