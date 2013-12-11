require 'eventmachine'
require 'em-synchrony'
require 'em/mqtt'
require 'json'
require 'logger'

class NowPlayingClient

  def initialize(opts={})
    @logger    = opts[:logger] || Logger.new(STDOUT)
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

  def is_duplicate?(msg)
    cached = now_playing(msg[:station_id])
    return false if cached.nil?
    message_key(cached) == message_key(msg)
  end

  def handle_incoming_message(message)
    payload = parse(message)
    unless is_duplicate?(payload)
      key = payload[:station_id]
      timer = expire_on_end(payload) if @expire_tracks
      cache_store(key, payload)
      notify(payload)
    end
  end

  def expire_on_end(message)
    duration   = message['duration']
    station_id = message[:station_id]
    @logger.debug "Setting #{duration}s timer for #{station_id} #{message_key(message)}"

    EventMachine::Synchrony.add_timer(duration) do
      current = now_playing(station_id)
      @logger.debug "Timer done for #{station_id} #{message_key(message)} / #{message_key(current)}"
      if message_key(message) == message_key(current)
        @logger.debug "Expiring #{station_id} #{message_key(message)}"
        current[:expired] = true
        cache_store(station_id, current)
        notify(current)
      end
    end
  end

  # Returns a key to identify identical messages
  # A message is identical if it has the same artist and title
  def message_key(message)
    "#{message['artist']}-#{message['title']}"
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
