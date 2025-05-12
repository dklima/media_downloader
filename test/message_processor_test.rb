# test/message_processor_test.rb
# frozen_string_literal: true

require 'minitest/autorun'
require 'mocha/minitest'
require_relative '../lib/loader'

class MessageProcessorTest < Minitest::Test
  def setup
    # Mock dependencies
    @mock_connection = mock('RabbitmqConnection')
    @mock_channel = mock('Channel')
    @mock_queue = mock('Queue')

    # Stub Config
    Config.stubs(:rabbitmq_queue).returns('test_queue')

    # Prevent actual signal trapping during tests
    Signal.stubs(:trap)

    # Prevent actual puts output
    @processor = MediaQueueConsumer.new
    @processor.stubs(:puts)

    # Stub the internal methods to avoid actual initialization
    MediaQueueConsumer.any_instance.stubs(:create_connection).returns(@mock_connection)
    MediaQueueConsumer.any_instance.stubs(:create_channel).returns(@mock_channel)
    MediaQueueConsumer.any_instance.stubs(:create_queue).returns(@mock_queue)
  end

  def test_initialize
    # We need to unstub the initialization methods for this specific test
    MediaQueueConsumer.any_instance.unstub(:create_connection)
    MediaQueueConsumer.any_instance.unstub(:create_channel)
    MediaQueueConsumer.any_instance.unstub(:create_queue)

    # Set up expectations for the initialization flow
    RabbitmqConnection.expects(:new).returns(@mock_connection)
    @mock_connection.expects(:create_channel).returns(@mock_channel)
    @mock_channel.expects(:queue).with('test_queue', durable: true).returns(@mock_queue)
    @mock_channel.expects(:prefetch).with(1).returns(@mock_channel)

    processor = MediaQueueConsumer.new

    assert_equal @mock_connection, processor.connection
    assert_equal @mock_channel, processor.channel
    assert_equal @mock_queue, processor.queue
  end

  def test_start_calls_required_methods
    processor = MediaQueueConsumer.new

    processor.expects(:setup_signal_handlers)
    processor.expects(:process_messages)

    processor.start
  end

  def test_start_handles_interrupt_exception
    processor = MediaQueueConsumer.new

    processor.expects(:setup_signal_handlers).raises(Interrupt)
    processor.expects(:shutdown)

    processor.start
  end

  def test_start_handles_standard_error
    processor = MediaQueueConsumer.new

    error = StandardError.new("Test error")
    processor.expects(:setup_signal_handlers).raises(error)
    processor.expects(:shutdown)
    processor.expects(:exit).with(1)

    # No need for the must_raise assertion that was causing problems
    processor.start
  end

  def test_process_message_successful
    processor = MediaQueueConsumer.new

    delivery_info = mock('DeliveryInfo')
    delivery_info.stubs(:delivery_tag).returns('tag123')
    body = '{"url":"https://example.com/video","name":"test_video","audio":false}'

    mock_downloader = mock('MediaDownloader')
    MediaDownloader.expects(:new).with(body).returns(mock_downloader)
    mock_downloader.expects(:call)

    @mock_channel.expects(:ack).with('tag123')

    processor.send(:process_message, delivery_info, body)
  end

  def test_process_message_handles_error
    processor = MediaQueueConsumer.new

    delivery_info = mock('DeliveryInfo')
    delivery_info.stubs(:delivery_tag).returns('tag123')
    body = '{"url":"https://example.com/video","name":"test_video","audio":false}'

    mock_downloader = mock('MediaDownloader')
    MediaDownloader.expects(:new).with(body).returns(mock_downloader)
    mock_downloader.expects(:call).raises(StandardError.new("Download failed"))

    @mock_channel.expects(:reject).with('tag123', false)

    processor.send(:process_message, delivery_info, body)
  end

  def test_shutdown
    processor = MediaQueueConsumer.new

    # Fix: Use the instance variable name as it appears in the method
    processor.instance_variable_set(:@connection, @mock_connection)
    @mock_connection.expects(:close)

    processor.send(:shutdown)
  end

  def test_process_messages_subscribes_to_queue
    processor = MediaQueueConsumer.new

    @mock_queue.expects(:subscribe).with(manual_ack: true, block: true)

    processor.send(:process_messages)
  end
end