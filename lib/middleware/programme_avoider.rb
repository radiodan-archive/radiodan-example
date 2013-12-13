require 'eventmachine'
require 'live_text_client'
require 'bbc_service_map'

class ProgrammeAvoider
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @avoiding_track = @options[:avoiding_track]
    @avoiding = false
    @avoiding_timer = nil
  end

  def call(player)
    @player = player

    EM.run do
      @live_text_client = LiveTextClient.new

      @live_text_client.on_message do |message|
        logger.debug message
      end

      # Cancel avoiding when station is changed
      player.register_event :change_station do |id|
        logger.info "Cancelling avoidance due to station change"
        @avoiding_timer.cancel if @avoiding_timer
        @avoided_track = nil
        @avoiding = false
      end

      # Stop avoiding when programme changes
      player.register_event :programme_changed do |id|
        logger.info "Stopping avoiding due to programme change"
        logger.info "Programme should be finished, reinstating previous station"
        @player.playlist.tracks = @avoided_track
        @avoiding = false
        @avoiding_timer.cancel if @avoiding_timer
        @avoided_track = nil
      end

      player.register_event :avoid do |type|
        # Only Avoid programmes
        avoid! if type == :programme
      end
    end
  end

  def avoid!
    if @avoiding
      logger.info "Already avoiding programme"
    else
      logger.info "AVOIDING PROGRAMME!"

      @avoided_track = @player.playlist.tracks
      logger.info "Current playlist.tracks #{@avoided_track}"
      logger.info "replacement_tracks #{replacement_tracks}"

      now_playing_track = @now_playing_client.now_playing(current_station_id)

      logger.info "current_station_id #{current_station_id}"
      logger.info "now_playing_track #{now_playing_track}"

      @player.playlist.tracks = replacement_tracks
      @avoiding = true
    end

  end

  # This does a look-up from the BBC-provided stream name
  # through the BBC Service Map to get an ID key that
  # matches those provided by the Now Playing service
  def current_station_id
    BBCRD::ServiceMap.lookup(@player.state.tracks.first.attributes[:Name]).programmes_id
  end

  def replacement_tracks
    @avoiding_track
  end
end
