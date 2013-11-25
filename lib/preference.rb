require 'yaml'

class Preference
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @path     = @options[:file_path]
    @defaults = @options[:defaults]
    @playlist = @options[:playlist]
    @prefs    = {}
  end

  def call(player)

    player.playlist = @playlist

    player.register_event :playlist do |playlist|
      @current_station = playlist.tracks.first[:id]
      @prefs[:station_id] = @current_station
      save!
    end

    player.register_event :change_volume do |volume|
      @prefs[:volume] = volume
      save!
    end
  end

  def method_missing(method, *args, &block)
    load!
    @prefs[method] if @prefs.has_key?(method)
  end

  private
  def save!
    File.open(@path, 'w') { |f| YAML.dump(@prefs, f) }
  end

  def load!
    @prefs = YAML.load_file(@path) || {}
  end
end
