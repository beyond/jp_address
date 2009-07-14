require "open-uri"
require "rexml/document"

class JpAddress < ActiveRecord::Base
  establish_connection :jp_address
  set_table_name  "jp_address"
  
  def self.[](code)
    case code.length
      # 旧郵便番号（3or5桁）で検索
      when 3 then find_by_zipcode_old(code)
      when 5 then find_by_zipcode_old(code)
      # 郵便番号（7桁）で検索
      when 7 then find_by_zipcode(code)
    end
  end
  
  def googlemaps_url
    "http://maps.google.com/maps?f=q&hl=ja&geocode=&q=#{ERB::Util.url_encode(prefecture+city+address)}&ie=UTF8&z=16&iwloc=addr"
  end
  
  def geocode
    open("http://nyanjiro.net/post2geo/post2geo.php?postcode=#{zipcode}&type=xml") do |response|
      xml = REXML::Document.new(response.read)
      geo = Geocode.new
      geo.address   = xml.elements['/response/addresses/address'].text
      geo.latitude  = xml.elements['/response/addresses/latitude'].text
      geo.longitude = xml.elements['/response/addresses/longitude'].text
      geo
    end
  end
  
  class Geocode
    attr_accessor :address, :latitude, :longitude
  end
  
end