# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/loader'

class MediaDownloaderTest < Minitest::Test
  def test_initialization_with_valid_json
    # Arrange
    json_body = { url: 'https://example.com/video.mp4', name: 'test_video.mp4', audio: false }.to_json
    
    # Act
    downloader = MediaDownloader.new(json_body)
    
    # Assert
    assert_equal 'https://example.com/video.mp4', downloader.url
    assert_equal 'test_video.mp4', downloader.name
    assert_equal false, downloader.audio
  end
  
  def test_initialization_with_invalid_json
    # Arrange
    invalid_json = '{ invalid json }'
    
    # Act & Assert
    assert_raises(RuntimeError) do
      MediaDownloader.new(invalid_json)
    end
  end
end