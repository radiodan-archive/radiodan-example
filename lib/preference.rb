require 'yaml'

class Preference
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @path     = @options[:file_path]
    @defaults = @options[:defaults]
    @playlist = @options[:playlist]
    @stations = @options[:stations]
    @prefs    = {}
  end

  def call(player)

    # Setup preferences for initial station
    # If no initial station saved, choose a random one
    initial_station = @stations[station_id] || @stations[@stations.keys.sample]

    # If no initial volume, choose 50%
    initial_volume  = volume || 50

    # Set initial settings
    @playlist.tracks = initial_station.tracks
    @playlist.volume = initial_volume

    # Set playlist on the player
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
