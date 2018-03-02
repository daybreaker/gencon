#!/usr/bin/env ruby

require 'slop'
require 'httparty'
require 'nokogiri'
require 'date'
require 'CGI'
require 'launchy'

opts = Slop.parse do |o|
  o.bool '-a', '--show_all', default: false
  o.bool '-w', '--wednesday', default: false
  o.bool '-m', '--monday', default: false
  o.bool '-c', '--connected', default: false
  o.bool '--miles', default: false
  o.integer '--max_distance'
  o.string '--checkin'
  o.string '--checkout'
  o.string '-k', '--key'
  o.integer '-t', '--minutes', default: 1
  o.bool '-b', '--browser', default: false
end

# Builds the Portal class for use by the command line
class Portal
  include HTTParty
  include ERB::Util
  include CGI::Util

  base_uri 'https://aws.passkey.com'

  def initialize(opts)
    @first_day = '2018-08-02'
    @last_day = '2018-08-05'

    @opts = opts
    @alerted = false
  end

  def checkin
    if @opts[:checkin]
      @opts[:checkin]
    else
      @opts.wednesday? ? (Date.parse(@first_day) - 1).to_s : @first_day
    end
  end

  def checkout
    if @opts[:checkout]
      @opts[:checkout]
    else
      @opts.monday? ? (Date.parse(@last_day) + 1).to_s : @last_day
    end
  end

  def event_url
    '/event/49547714/owner/10909638/rooms/select'
  end

  def start_url
    "/reg/#{@opts[:key]}/null/null/1/0/null"
  end

  def distance_units
    {
      1 => 'blocks',
      2 => 'yards',
      3 => 'miles',
      4 => 'meters',
      5 => 'kilometers',
    }
  end

  def body
    {
      hotelId: '0',
      # "distanceEnd": 0,
      # "maxGuests": 5,
      'blockMap.blocks%5B0%5D.blockId' => '0',
      'blockMap.blocks%5B0%5D.checkIn' => checkin,
      'blockMap.blocks%5B0%5D.checkOut' => checkout,
      'blockMap.blocks%5B0%5D.numberOfGuests' => '1',
      'blockMap.blocks%5B0%5D.numberOfRooms' => '1',
      'blockMap.blocks%5B0%5D.numberOfChildren' => '0'
      # "blockMap.blocks%5B0%5D.totalRooms": 1,
      # "blockMap.blocks%5B0%5D.totalGuests": 1
      # "minSlideRate": 0,
      # "maxSlideRate": 0,
      # "wlSearch": false,
      # "showAll": false,
      # "mod": false
    }
  end

  def search_resp
    resp = self.class.get(start_url)

    cookies = get_cookies(resp)

    # puts body.inspect
    # puts cookies

    self.class.post(
      event_url,
      query: body, # form encode this.
      headers: { 
        'Cookie' => cookies,
        'Host': 'book.passkey.com',
      },
    )
  end

  def search
    result_json = JSON.parse(
      Nokogiri.parse(search_resp.response.body)
        .css('script#last-search-results')
        .children.to_s,
    )
    hotels = filter(result_json.reject { |x| x['blocks'].empty? })

    display hotels
    alert hotels
  end

  def alert(hotels)
    if hotels.count > 0 && !@alerted && @opts.browser?
      @alerted = true
      Launchy.open("https://aws.passkey.com/reg/#{@opts[:key]}/null/null/1/0/null")
    end
  end

  def connected(hotel)
    hotel['messageMap'] && hotel['messageMap'].includes?('Skywalk to ICC')
  end

  def not_close_enough(hotel)
    return true if @opts.connected? && !connected(hotel)

    # Hide hotels that dont fit in @opts[:max_distance]
    if @opts[:max_distance]
      if hotel['distanceUnit'] == 3
        # Skip if hotel is measured in miles, and not filtering by miles, or hotel is too far
        return !@opts.miles? || hotel['distanceFromEvent'] > @opts[:max_distance]
      else
        # Skip if not using filtering by miles and hotel is too far
        # (This means if filtering by miles, all hotels measured in blocks will go through)
        return !@opts.miles? && hotel['distanceFromEvent'] > @opts[:max_distance]
      end
    end
    false
  end

  def not_cheap_enough(hotel)
    false
  end

  def not_matched(hotel)
    false
  end

  def reject_hotel?(hotel)
    # hide all hotels measured in miles, when not using --show_all
    return true if hotel['distanceUnit'] == 3 && !@opts.show_all?

    not_cheap_enough(hotel) || not_close_enough(hotel) || not_matched(hotel)
  end

  def hotel_dist(hotel)
    "#{hotel['distanceFromEvent']} #{distance_units[hotel['distanceUnit']]}"
  end

  def build_blocks(hotel)
    hotel['blocks'].map do |block|
      {
        name: CGI.unescapeHTML(hotel['name']),
        distance: connected(hotel) ? 'Skywalk' : hotel_dist(hotel),
        price: block['inventory'].sum { |inv| inv['rate'] },
        rooms: block['inventory'].collect { |inv| inv['available'] }.min,
        room: CGI.unescapeHTML(block['name']),
      }
    end
  end

  def filter(hotels)
    hotels
      .sort_by { |x| [x['distanceUnit'], x['distanceFromEvent']] }
      .map do |hotel|
        # Hide hotels miles away unless show all
        next if reject_hotel?(hotel)
        build_blocks(hotel)
      end
      .reject(&:nil?)
  end

  def display(hotels)
    printf "%-15s %-10s %-80s %s\n", 'Distance', 'Price', 'Hotel', 'Room'

    hotels.each do |hotel, _key|
      printf "%-15s $%-9s %-80s (%d) %s\n",
             hotel[:distance],
             hotel[:price],
             hotel[:name],
             hotel[:rooms],
             hotel[:room]
    end
    puts "-----------end search at #{Time.now}------------"
  end

  private

  def get_cookies(resp)
    cookie_hash = CookieHash.new
    resp.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
    cookie_hash.to_cookie_string
  end
end

portal = Portal.new(opts)
portal.search

now = Time.now
counter = opts[:minutes] * 60
loop do
  if Time.now < now + counter
    sleep 1
    next
  else
    now = Time.now
    portal.search
  end
end
