require 'fastercsv'
require 'ar-extensions'
require 'kconv'
$KCODE='j'

class CreateJpAddress < ActiveRecord::Migration
  
  ADDRESS_CSV = File.expand_path(File.join(RAILS_ROOT, 'vendor', 'plugins', 'jp_address', 'ken_all.csv'))
  
  def self.up
    create_table :jp_address do |t|
      t.column :jiscode,          :string, :null => false, :limit => 5
      t.column :zipcode_old,      :string, :null => false, :limit => 5
      t.column :zipcode,          :string, :null => false, :limit => 7
      t.column :prefecture_kana,  :string, :null => false
      t.column :city_kana,        :string, :null => false
      t.column :address_kana,     :string, :null => true
      t.column :prefecture,       :string, :null => false
      t.column :city,             :string, :null => false
      t.column :address,          :string, :null => true
    end
    add_index :jp_address, :jiscode
    add_index :jp_address, :zipcode_old
    add_index :jp_address, :zipcode
    
    puts "Reading " + ADDRESS_CSV
    puts "This file is over 12MB, please wait ..."
    address_list = Array.new
    FasterCSV.foreach(ADDRESS_CSV) do |data|
      address_list << [ 
        data[0], # JISCODE(5)
        data[1], # ZIPCODE_OLD(3)
        data[2], # ZIPCODE(7)
        data[3].toutf8, # PREFECTURE
        data[4].toutf8, # CITY
        data[5].toutf8.gsub(/^[０-９].*$|（.*$/u,""), # ADDRESS
        data[6].toutf8, # PREFECTURE
        data[7].toutf8, # CITY
        data[8].toutf8.gsub(/^[０-９].*$|（.*$/u,"") # ADDRESS
      ] unless data[2]=~/^[0-9]{6}0$/
    end
    
    puts "Store all data into static_addresses table."
    puts "There are over 120,000 rows, please wait ..."
    column = [:jiscode, :zipcode_old, :zipcode, :prefecture_kana, :city_kana, :address_kana, :prefecture, :city, :address]
    JpAddress.import(column, address_list, :optimize => true)
  end
  
  def self.down
    drop_table :jp_address
  end
end