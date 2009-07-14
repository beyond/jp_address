# Include hook code here
begin
  require 'jp_address'
rescue LoadError
  begin
    require 'fastercsv'
    require 'ar-extensions'
  rescue LoadError
    puts "Install the fastercsv gem and ar-extensions gem."
  end
end