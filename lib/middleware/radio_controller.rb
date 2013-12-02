class RadioController
  include Radiodan::Logging

  @@playlist = Radiodan::Playlist.new

  def self.playlist
    @@playlist
  end

  def initialize(*config)
    @options  = config.shift
    @stations = @options[:stations] || []
    @current_station = nil
  end

  def call(player)
    @player = player
    logger.debug "RadioController middleware"

    player.register_event :playlist do |playlist|
      @current_station = playlist.tracks.first[:id]
    end

    player.register_event :toggle_power do
      power!
    end

    player.register_event :change_volume do |new_volume|
      current_volume = volume
      case new_volume
      when 'up'
        volume(current_volume + 2)
      when 'down'
        volume(current_volume - 2)
      else
        volume(new_volume)
      end
    end

    player.register_event :change_station do |station_id|
      case station_id
      when :next
        next_station
      when :previous
        previous_station
      else
        station(station_id)
      end
    end
  end

  def power!
    logger.info "Toggle power"
    if @player.playlist.state == :play
      @player.pause
    else
      @player.play
    end
  end

  def volume
    @player.playlist.volume
  end

  def volume(value=nil)
    @player.playlist.volume = value unless value.nil? || value < 0 || value > 100
    @player.playlist.volume
  end

  def next_station
    station(surrounding_stations[:next])
  end

  def previous_station
    station(surrounding_stations[:previous])
  end

  def station(station_id)
    station_playlist = @stations.find { |id, playlist| id == station_id }
    if station_playlist
      tracks = station_playlist[1].tracks
      @player.playlist.tracks = tracks
    end
  end

  private
  def surrounding_stations
    stations = @stations.keys
    current_station_index = stations.index(@current_station)
    next_station = stations[(current_station_index + 1) % @stations.length]
    prev_station = stations[(current_station_index - 1) % @stations.length]
    { :next => next_station, :previous => prev_station }
  end
end
