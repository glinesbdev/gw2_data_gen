require "./sam_is_fucking_awesome"

if ARGV.empty?
  puts "API URI fragment not supplied"
  exit
end

ARGV.each do |klass_name|
  FileWriter.new(klass_name).write
end
