require "option_parser"
require "./sam_is_fucking_awesome"

parser_options = Hash(String, String).new("")
url_fragments = Array(String).new

OptionParser.parse do |parser|
  parser.banner = "Usage: gw2_data_gen [options] [api_url_fragments (account, account/bank)]
  Options:"

  parser.on("-o PATH", "--output-path=PATH", "Path for output files. Full path will be created if it doesn't exist.") do |dest|
    parser_options["output"] = "#{dest}/"
  end

  parser.on("-h", "--help", "Prints this help screen.") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end

  parser.unknown_args do |args|
    url_fragments = args
  end
end

if url_fragments.empty?
  STDERR.puts "API URL fragment(s) not supplied"
  exit(1)
end

url_fragments.each do |url_fragment|
  WikiConverter.new(parser_options, url_fragment).write
end
