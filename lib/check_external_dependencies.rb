# frozen_string_literal: true

# Class responsible for checking if required external commands are available in the system
class CheckExternalDependencies
  DEFAULT_DEPENDENCIES = %w[yt-dlp ffmpeg].freeze

  attr_accessor :dependencies, :prompt

  def initialize(dependencies = DEFAULT_DEPENDENCIES)
    self.dependencies = dependencies
    self.prompt = TTY::Prompt.new
  end

  def run
    missing_dependencies = find_missing_dependencies

    if missing_dependencies.any?
      display_missing_dependencies(missing_dependencies)
      exit(1)
    else
      display_success
    end

    true
  end

  def self.verify(dependencies = DEFAULT_DEPENDENCIES)
    new(dependencies).run
  end

  private

  def find_missing_dependencies
    dependencies.reject { |cmd| command_exists?(cmd) }
  end

  def command_exists?(command)
    _, _, status = Open3.capture3('which', command)
    status.success?
  end

  def display_missing_dependencies(missing)
    prompt.warn("\n  🚫  MISSING DEPENDENCIES 🚫")
    prompt.say("\n    The following required commands were not found:", color: :yellow)

    missing.each do |cmd|
      prompt.say("    • #{cmd}", color: :red)
    end

    prompt.say("\n    Please install them before proceeding.", color: :yellow)
    prompt.say('    Exiting program...', color: :yellow)
  end

  def display_success
    prompt.ok("\n  ✅ DEPENDENCY CHECK PASSED  ") do
      total = dependencies.length
      prompt.say("\n  Found all #{total} required dependencies:".green)

      dependencies.each do |cmd|
        prompt.say("  ✓ #{cmd}".green)
      end

      prompt.say("\n  Ready to proceed with execution!".cyan.bold)
    end
  end
end
