#!/usr/scripts/env ruby
# frozen_string_literal: true

require_relative 'lib/loader'

def create_prompt
  TTY::Prompt.new(
    help_color: :cyan,
    interrupt: lambda do
      puts "\n❌ Operation cancelled. Exiting."
      exit(1)
    end
  )
end

def parse_command_line_options
  options = OpenStruct.new
  OptionParser.new do |opt|
    opt.on('-u', '--url URL', 'Audio or Video address') { |o| options.url = o }
    opt.on('-n', '--name FILENAME', 'Filename for the downloaded file') { |o| options.name = o }
    opt.on('-a', '--audio', 'The download link is a music or only audio') { |o| options.audio = o }
    opt.on('-k', '--keep', 'Keep original audio and video files') { |o| options.keep = o }
  end.parse!
  options
end

def ensure_url_provided(options)
  return options.url if options.url

  @prompt.ask('🎵 Enter the URL of the audio/video:') do |q|
    q.required true
    q.validate %r{\Ahttps?://}
    q.messages[:valid?] = 'URL must start with http:// or https://'
  end
end

@prompt = create_prompt

options = parse_command_line_options
url = ensure_url_provided(options)
audio_only = options.audio.nil? ? false : true

message = { url: url, name: options.name, audio_only:, keep: options.keep }

MediaQueuePublisher.new(message).run
