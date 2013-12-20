require 'eventmachine'
require 'em-synchrony'
require 'em/mqtt'
require 'json'

class LiveTextClient

  def initialize(opts={})
    @logger    = opts[:logger] || Logger.new(STDOUT)
    @server    = 'test.mosquitto.org'
    @topic     = 'bbc/livetext/#'
    @callbacks = { :on_message => [], :on_programme_changed => [] }
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
    @callbacks[:on_message] << block
  end

  def on_programme_changed(&block)
    @callbacks[:on_programme_changed] << block
  end

  def notify(message_name, payload={})
    @callbacks[message_name].each { |cb| 
      cb.call(payload) 
    }
  end

  private
  # Push a new message into a cache
  def cache_store(key, message)
    @messages[key] = [] if @messages[key].nil?
    @messages[key].shift if @messages[key].length == 10
    @messages[key] << message
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
  def is_new?(message)
    result = false
    previous_messages   = cache_get(message[:station_id])
    if(previous_messages)
      seen_message_before = previous_messages.any? { |m| message[:text] == m[:text] }

      if !seen_message_before
        if previous_messages.length > 7
          @logger.debug("New message - programme has changed for #{:station_id}")
          @logger.debug(previous_messages)
          result = true 
        else
          @logger.debug("Previous_messages.length < 7")
        end
      end
    end
    result
  end

  # Parse and store an incoming data, notifying any
  # callbacks registered on the class via on_message
  def handle_incoming_message(data)
    message = parse(data)
    text = message[:text].downcase

    if text.include?("now playing") || text.include?("coming next")
      @logger.debug("Discarding message #{message}")
    else
      @logger.debug("Keeping message #{message}")
      # fire on_message callbacks
      notify(:on_message, message)
      # if the is_new? is true then fire on_programme_changed callbacks
      notify(:on_programme_changed, message) if is_new?(message)
      # store the message in the cache
      cache_store(message[:station_id], message)
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
