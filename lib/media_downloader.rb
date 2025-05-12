# frozen_string_literal: true

# MediaDownloader
class MediaDownloader
  attr_accessor :url, :name, :audio_only, :keep

  def initialize(body)
    parsed_body = JSON.parse(body)
    self.url = parsed_body['url']
    self.name = parsed_body['name']
    self.audio_only = parsed_body['audio_only']
    self.keep = parsed_body['keep']
  rescue JSON::ParserError => e
    raise "Invalid JSON format: #{e.message}"
  end

  def call
    command = ['yt-dlp', '-P', Config.downloader_path, '-f', 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best',
               url]
    command.push('-o', name) if name
    command.push('--audio-format', 'mp3', '--extract-audio') if audio_only
    command.push('-k') if keep

    output, err, status = Open3.capture3(*command)
    puts err
    puts output
    puts status
  end
end
