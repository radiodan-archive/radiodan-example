require 'faye'

class FayeRelay
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @port     = @options[:port]
  end

  def call(player)
    faye_url = "http://localhost:#{@port}/faye"
    @player = player
    @client = Faye::Client.new(faye_url)

    logger.info "Client on #{faye_url}"

    @client.subscribe('/power') do
      logger.info "/power"
      @player.trigger_event :toggle_power
    end

    @client.subscribe('/volume') do |value|
      logger.info "/volume #{value}"
      @player.trigger_event :change_volume, value
    end

    @client.subscribe('/station') do |action_or_id|
      case action_or_id
      when "next"
        action_or_id = :next
      when "previous"
        action_or_id = :previous
      end

      logger.info "/station #{action_or_id}"

      @player.trigger_event :change_station, action_or_id
    end

    player.register_event :sync do |playlist|
      if playlist.tracks.first.attributes[:id].nil? && @player.playlist.tracks.first.attributes[:id]
        playlist.tracks.first.attributes[:id] = @player.playlist.tracks.first.attributes[:id]
      end

      # We use get track id from the current player playlist since it
      # contains the id of the stream that we set
      # and not the human-readable name that comes from
      # mpd e.g. 'bbc_radio_2' rather than "BBC Radio 2"
      @client.publish('/info', playlist.attributes)
    end

    player.register_event :now_playing do |info|
      @client.publish('/now_playing', info)
    end

  end
end
