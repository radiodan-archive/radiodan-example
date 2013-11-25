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
      @client.publish('/info', playlist.attributes)
      # @client.publish('/station', :id => current_track[:id], :name => current_track[:Name] )
    end

    # player.register_event :toggle_power do
    #   power!
    # end

    # player.register_event :change_volume do |volume|
    #   volume(volume)
    # end

    # player.register_event :change_station do |station_id|
    #   case station_id
    #   when :next
    #     next_station
    #   when :previous
    #     previous_station
    #   else
    #     station(station_id)
    #   end
    # end
  end
end
