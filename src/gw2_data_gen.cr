require "./sam_is_fucking_awesome"

if ARGV.empty?
  puts "API URI fragment not supplied"
  exit
end

ARGV.each do |url_fragment|
  WikiConverter.new(url_fragment).write
end
