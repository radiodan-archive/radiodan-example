=begin
In order to fake a radio, we need to stream radio content.
BBC Radio streams are playlist files, which contain
a link to a time-restricted audio stream.

Every few hours, the stream disconnects and you have to
download the playlist again to continue.

This downloads the playlists and parses for the audio end point.
=end

require "radiodan/playlist"
require "rest-client"

class DownloadBBCRadio
  URL = "http://www.bbc.co.uk/radio/listen/live/r%s_aaclca.pls"
  STATIONS = %w{1 1x 2 3 4 4lw 4x 5l 5lsp 6 an}
  attr_accessor :stations

  def run
    @stations ||= Hash.new
    @threads = []

    RestClient.proxy = ENV['HTTP_PROXY']

    STATIONS.each do |station|
      @threads << Thread.new do
        req = RestClient.get(URL % station)
        next if req.nil?

        url = req.match(/^File2=(.*)$/)[1]

        station_name = "bbc_radio_#{station}"

        content = Radiodan::Playlist.new tracks: Radiodan::Track.new(:file => url, :id => station_name)
        @stations[station_name] = content
      end
    end

    # World Service stream
    @stations["bbc_radio_ws"] = Radiodan::Playlist.new(tracks: Radiodan::Track.new(:file => "http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-eieuk", :id => "bbc_radio_ws"))

    @threads.collect(&:join)
    @stations = Hash[@stations.sort]
  end
end
