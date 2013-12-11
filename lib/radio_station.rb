# Represents a playable radio station
# Including playlist and stream expiry
require "radiodan/playlist"
require "rest-client"

class RadioStation
  STATIONS = {
    :'1'   => 'BBC Radio 1',
    :'1x'  => 'BBC Radio 1xtra',
    :'2'   => 'BBC Radio 2',
    :'3'   => 'BBC Radio 3',
    :'4'   => 'BBC Radio 4',
    :'4lw' => 'BBC Radio Long Wave',
    :'4x'  => 'BBC Radio 4 Xtra',
    :'5l'  => 'BBC Radio 5 Live',
    :'6'   => 'BBC Radio 6 Music',
    :'an'  => 'BBC Asian Network',
    :'ws'  => 'BBC World Service',
  }

  URL = "http://www.bbc.co.uk/radio/listen/live/r%s_aaclca.pls"

  def self.list
    STATIONS.map do |id,title|
      if id == :'ws'
        RadioStation.new(id.to_s, title, "http://bbcwssc.ic.llnwd.net/stream/bbcwssc_mp1_ws-eieuk")
      else
        RadioStation.new(id.to_s, title)
      end
    end
  end

  def initialize(id, title=nil, url=nil)
    @id    = id
    @title = title
    @url   = url || URL
  end

  def stream_id
    @id
  end

  def bbc_id
    "bbc_radio_#{stream_id}"
  end

  def title
    @title
  end

  def playlist
    Radiodan::Playlist.new(tracks: tracks)
  end

  def tracks
    Radiodan::Track.new(:file => stream_url, :id => bbc_id)
  end

  def stream_url
    pls_file.match(/^File1=(.*)$/)[1]
  end

  def expires
    date = nil
    end_time_secs = stream_url.match(/e=([\d]*)/)
    date = DateTime.strptime(end_time_secs[1],'%s') if end_time_secs && end_time_secs.length > 0
    date
  end

  def pls_url
    @url % stream_id
  end

  def reset!
    @pls_file = nil
  end

  private
  def pls_file
    unless @pls_file
      @pls_file = RestClient.get(pls_url)
    end
    @pls_file
  end
end
