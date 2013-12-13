require 'eventmachine'
require 'live_text_client'
require 'bbc_service_map'

class ProgrammeAvoider
  include Radiodan::Logging

  def initialize(*config)
    @options  = config.shift
    @avoiding_track = @options[:avoiding_track]
    @avoiding = false
  end

  def call(player)
    @player = player

    EM.run do
      @live_text_client = LiveTextClient.new

      @live_text_client.on_message do |message|
        logger.debug message
      end

      @player.register_event :on_programme_changed do |id|
#      @live_text_client.on_programme_changed do 
         logger.debug "Programme changed"
         if @avoiding
           logger.info "Stopping avoiding due to programme change"
           logger.info "Programme should be finished, reinstating previous station"
           @player.playlist.tracks = @avoided_track
           @avoiding = false
           @avoided_track = nil
         end
      end

      # # Cancel avoiding when station is changed
      @player.register_event :change_station do |id|
         logger.info "Cancelling avoidance due to station change"
         @avoided_track = nil
         @avoiding = false
      end

       player.register_event :avoid do |type|
         # Only Avoid programmes
         logger.info "\n\ntype #{type}"
         avoid! if type == :programme
       end
    end
  end

  def avoid!
    if @avoiding
      logger.info "Already avoiding programme"
    else
      logger.info "\n\nAVOIDING PROGRAMME!!!!!\n\n"

      @avoided_track = @player.playlist.tracks
      logger.info "Current playlist.tracks #{@avoided_track}"
      logger.info "replacement_tracks #{replacement_tracks}"

      @player.playlist.tracks = replacement_tracks
      @avoiding = true
    end

  end

  def current_station_id
    @player.playlist.tracks.first[:id]
  end

  def replacement_tracks
    @avoiding_track
  end
end
