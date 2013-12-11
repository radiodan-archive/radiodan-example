require 'eventmachine'
require 'em-synchrony'
require 'em/mqtt'
require 'json'

class NowPlayingClient

  def initialize(opts={})
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/nowplaying/#'
    @callbacks = []
    @current   = {}
    @expire_tracks = opts[:expire_tracks] || false
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
    expire_on_end(payload) if @expire_tracks
    notify(payload)
  end

  def expire_on_end(message)
    duration   = message['duration']
    station_id = message[:station_id]
    EventMachine::Synchrony.add_timer(duration) do
      expired_message = { :station_id => station_id }
      cache_store(station_id, expired_message)
      notify(expired_message)
    end
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
