require 'faye'
require 'bbc_service_map'

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

    @client.subscribe('/avoid') do |type|
      logger.info "/avoid #{type}"
      @player.trigger_event :avoid, type.to_sym
    end

    player.register_event :sync do |playlist|
      # Lookup the stream name from the playlist and convert
      # to a BBC Programmes service id e.g. 'BBC Radio 2' -> 'radio2'
      begin
        bbc_service = BBCRD::ServiceMap.lookup(playlist.tracks.first.attributes[:Name])
        playlist.tracks.first.attributes[:id] = bbc_service.programmes_id if bbc_service
        @client.publish('/info', playlist.attributes)
      rescue
        logger.error "Error publishing playlist attributes at Sync"
      end
    end

    player.register_event :now_playing do |info|
      @client.publish('/now_playing', info)
    end

  end
end
