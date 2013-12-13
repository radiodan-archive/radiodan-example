require 'eventmachine'
require 'em-synchrony'
require 'em/mqtt'
require 'json'

class LiveTextClient

  def initialize(opts={})
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/livetext/#'
    @callbacks = []
    @messages  = {}
    connect!
  end

  def messages_for(station_id=nil)
    if station_id
      cache_get(station_id)
    else
      @messages
    end
  end

  def on_message(&block)
    @callbacks << block
  end

  def notify(payload={})
    @callbacks.each { |cb| cb.call(payload) }
  end

  private
  # Push a new message into a cache
  def cache_store(key, message)
      @messages[key] = [] if @messages[key].nil?
      @messages[key] << message
    end
  end

  # Get the array of cached messages
  # Oldest is first in the array
  def cache_get(key)
    @messages[key] if @messages.has_key?(key)
  end

  # Parse an MQTT message into a Ruby Hash containing
  #   station id, live text message text, time received
  def parse(message)
    station = message.topic.gsub('#', '').gsub('bbc/livetext/', '')
    {
      :station_id => station,
      :text       => message.payload,
      :received   => Time.now
    }
  end

  # Checks to see if we have seen this message before
  # If we haven't, we assume it's a new programme being flagged
  def is_new?(message, payload)
    result = false
    if(cache_store(payload[:station_id]).include?(message))
      if(cache_store(payload[:station_id]).length > 7)
        @logger.debug("Think we have a new message - programme has changed")
        result = true
      end
    end
    cache_store(payload[:station_id], payload)
    if(cache_store(payload[:station_id]).length>10)
      cache_store(payload[:station_id]).shift
    end
    result
  end

  # Parse and store an incoming message, notifying any
  # callbacks registered on the class via on_message
  def handle_incoming_message(message)
    payload = parse(message)
    m = message.downcase
    if(m.include?("now playing") && m.include?("coming next"))
      @logger.debug("Discarding message #{message}")
    else
      @logger.debug("Keeping message #{message}")
      if(is_new?(message, payload))
        notify(payload)
      end
    end
  end

  # Connect to MQTT server and wait for messages
  # Call handle_incoming_message to process each
  # message received
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
