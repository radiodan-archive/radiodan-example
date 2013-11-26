require 'em/mqtt'
require 'em-synchrony'

class NowPlayingClient
  #include Radiodan::Logging

  def initialize(publish_client=nil)
    # @publish_client = publish_client
    @server = 'test.mosquitto.org'
    @topic  = 'bbc/#'
    connect!
  end

  def on_change(&block)
  end

  private
  def connect!
    EventMachine.synchrony do
      puts "Connecting to #{@server}"
      EventMachine::MQTT::ClientConnection.connect(@server) do |c|
        c.subscribe(@topic)
        c.receive_callback do |message|
          p message[:topic]
          p message[:payload]
        end
      end
    end
  end
end
