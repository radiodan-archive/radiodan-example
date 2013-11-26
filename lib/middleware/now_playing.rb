# require 'now_playing_client'
require 'em/mqtt'

class NowPlaying
  include Radiodan::Logging

  def initialize(*config)
    @options   = config.shift
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/nowplaying/#'
    # @now_playing_client = NowPlayingClient.new
  end

  def call(player)
    # @now_playing_client.on_change do |track_info|
    #   player.trigger_event :now_playing, track_info
    # end

    EventMachine::MQTT::ClientConnection.connect(@server) do |c|
      c.subscribe(@topic)
      c.receive_callback do |message|
        p message
      end
    end
  end
end
