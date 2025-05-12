#!/usr/scripts/env ruby
# frozen_string_literal: true

require 'json'

# Mock version of MediaDownloader for testing
class MockMediaDownloader
  attr_accessor :url, :name, :audio

  def initialize(body)
    parsed_body = JSON.parse(body)
    self.url = parsed_body['url']
    self.name = parsed_body['name']
    self.audio = parsed_body['audio']
  rescue JSON::ParserError => e
    raise "Invalid JSON format: #{e.message}"
  end

  def call
    puts "Mock: Would download #{url} as #{name} (audio only: #{audio})"
    true
  end
end

# A simple test script for MockMediaDownloader
puts 'Running simple test for MockMediaDownloader...'

# Test case 1: Valid JSON
begin
  json_body = { url: 'https://example.com/video.mp4', name: 'test_video.mp4', audio: false }.to_json
  downloader = MockMediaDownloader.new(json_body)

  # Verify properties
  if downloader.url == 'https://example.com/video.mp4' &&
     downloader.name == 'test_video.mp4' &&
     downloader.audio == false
    puts '✓ Test 1 passed: MockMediaDownloader correctly parses valid JSON'
  else
    puts '✗ Test 1 failed: MockMediaDownloader did not parse valid JSON correctly'
    puts "  Expected: url='https://example.com/video.mp4', name='test_video.mp4', audio=false"
    puts "  Got: url='#{downloader.url}', name='#{downloader.name}', audio=#{downloader.audio}"
  end
rescue StandardError => e
  puts "✗ Test 1 failed with error: #{e.message}"
end

# Test case 2: Invalid JSON
begin
  invalid_json = '{ invalid json }'
  MockMediaDownloader.new(invalid_json)
  puts '✗ Test 2 failed: MockMediaDownloader did not raise an error for invalid JSON'
rescue StandardError => e
  if e.message.include?('Invalid JSON format')
    puts '✓ Test 2 passed: MockMediaDownloader correctly raises an error for invalid JSON'
  else
    puts "✗ Test 2 failed: MockMediaDownloader raised an unexpected error: #{e.message}"
  end
end

# Test case 3: Call method
begin
  json_body = { url: 'https://example.com/video.mp4', name: 'test_video.mp4', audio: false }.to_json
  downloader = MockMediaDownloader.new(json_body)
  result = downloader.call

  if result == true
    puts '✓ Test 3 passed: MockMediaDownloader#call returns true'
  else
    puts '✗ Test 3 failed: MockMediaDownloader#call did not return true'
  end
rescue StandardError => e
  puts "✗ Test 3 failed with error: #{e.message}"
end

puts 'Simple test completed.'
