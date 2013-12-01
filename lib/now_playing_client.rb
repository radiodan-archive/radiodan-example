require 'eventmachine'
require 'em/mqtt'
require 'json'

class NowPlayingClient

  def initialize
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/nowplaying/#'
    @callbacks = []
    connect!
  end

  def on_message(&block)
    @callbacks << block
  end

  def notify(payload={})
    @callbacks.each { |cb| cb.call(payload) }
  end

  private
  def connect!
    EventMachine.run do
      EventMachine::MQTT::ClientConnection.connect(@server) do |c|
        c.subscribe(@topic)
        c.receive_callback do |message|
          station = message.topic.gsub('#', '').gsub('bbc/nowplaying/', '')
          payload = JSON.parse(message.payload)
          payload[:station_id] = station
          notify(payload)
        end
      end
    end
  end
end
