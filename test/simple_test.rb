#!/usr/scripts/env ruby
# frozen_string_literal: true

require_relative '../lib/loader'

# A simple test script for MediaDownloader
puts 'Running simple test for MediaDownloader...'

# Test case 1: Valid JSON
begin
  json_body = { url: 'https://example.com/video.mp4', name: 'test_video.mp4', audio: false }.to_json
  downloader = MediaDownloader.new(json_body)

  # Verify properties
  if downloader.url == 'https://example.com/video.mp4' &&
     downloader.name == 'test_video.mp4' &&
     downloader.audio == false
    puts '✓ Test 1 passed: MediaDownloader correctly parses valid JSON'
  else
    puts '✗ Test 1 failed: MediaDownloader did not parse valid JSON correctly'
    puts "  Expected: url='https://example.com/video.mp4', name='test_video.mp4', audio=false"
    puts "  Got: url='#{downloader.url}', name='#{downloader.name}', audio=#{downloader.audio}"
  end
rescue StandardError => e
  puts "✗ Test 1 failed with error: #{e.message}"
end

# Test case 2: Invalid JSON
begin
  invalid_json = '{ invalid json }'
  MediaDownloader.new(invalid_json)
  puts '✗ Test 2 failed: MediaDownloader did not raise an error for invalid JSON'
rescue StandardError => e
  if e.message.include?('Invalid JSON format')
    puts '✓ Test 2 passed: MediaDownloader correctly raises an error for invalid JSON'
  else
    puts "✗ Test 2 failed: MediaDownloader raised an unexpected error: #{e.message}"
  end
end

puts 'Simple test completed.'
