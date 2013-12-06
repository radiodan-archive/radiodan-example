require 'eventmachine'
require 'em/mqtt'
require 'json'

class NowPlayingClient

  def initialize
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/nowplaying/#'
    @callbacks = []
    @current   = {}
    connect!
  end

  def now_playing(station_id=nil)
    if station_id
      cache_get(station_id)
    else
      @current
    end
  end

  def on_message(&block)
    @callbacks << block
  end

  def notify(payload={})
    @callbacks.each { |cb| cb.call(payload) }
  end

  private
  def cache_store(key, value)
    @current[key] = value
  end

  def cache_get(key)
    @current[key] if @current.has_key?(key)
  end

  def parse(message)
    station = message.topic.gsub('#', '').gsub('bbc/nowplaying/', '')
    payload = JSON.parse(message.payload)
    payload[:station_id] = station
    payload[:start_time] = Time.now
    payload
  end

  def handle_incoming_message(message)
    payload = parse(message)
    cache_store(payload[:station_id], payload)
    notify(payload)
  end

  def connect!
    EventMachine.run do
      EventMachine::MQTT::ClientConnection.connect(@server) do |c|
        c.subscribe(@topic)
        c.receive_callback do |message|
          handle_incoming_message(message)
        end
      end
    end
  end
end
