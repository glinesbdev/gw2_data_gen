# require "http/client"
# require "html5"
# 
# puts "A page name is required" unless ARGV[0]
# 
# URL              = "https://wiki.guildwars2.com/wiki/API:2"
# IGNORE_ATTRS     = ["access_token", "v", "id", "ids", "lang"]
# INVALID_HEADINGS = ["Parameters", "Example", "Notes", "References", "Endpoints", "Subobjects", "Other types"]
# 
# def str_type(str : String) : String
#   optional = str =~ /optional/
#   modified_str = str.gsub(/, optional/) { "" }
# 
#   res = case modified_str
#         when "(string)"
#           "String"
#         when 
#           "UInt32"
#         when "(array of strings)", "(array of string)"
#           "Array(String)"
#         when "(array of numbers)", "(array of integer)"
#           "Array(UInt32)"
#         when "(boolean)"
#           "Bool"
#         else
#           str
#         end
# 
#   optional ? "#{res}?" : res
# end
# 
# # The tuple will contain the following data:
# # [0] - comments for the method (optional)
# # [1] - name of the method
# # [2] - type of the method
# def create_getters(attributes : Array(Tuple(String?, String, String))) : String
#   attributes.map do |item|
#     <<-DATA
#             # #{item[0]? || "No documentation provided."}
#             getter #{item[1]} : #{str_type(item[2])}
#         \n
#         DATA
#   end.join
# end
# 
# def definition(name : String, attributes : Array(Tuple(String?, String, String))) : String
#   <<-FILE
# require "json"
# 
# module Gw2Api
#   struct #{name.capitalize}
#     include JSON::Serializable
# 
#     #{create_getters(attributes)}
#   end
# end
# FILE
# end
# 
# def html_page(page : String)
#   HTML5.parse(HTTP::Client.get("#{URL}/#{page}").body)
# end
# 
# def find_element_in_page(page : String, selector : String) : Array(HTML5::Node)
#   html_page(page).css(selector)
# end
# 
# def valid_headings(page : String) : Array(HTML5::Node)
#   nodes = find_element_in_page(page, ".mw-parser-output .mw-headline").compact
#   nodes.reject! { |el| INVALID_HEADINGS.includes?(el.inner_text) }
# end
# 
# # From a heading on the page i.e. Armor, go to the next, and only next,
# # ul element and get the text from all its child elements.
# def attribute_nodes(heading : HTML5::Node) : Array(HTML5::Node)
#   heading.xpath_nodes("../following-sibling::ul[1]")
# end
# 
# def class_data(node : HTML5::Node) : Array(String)
#   node.inner_text.split(/\n/)
# end
# 
# def class_values(data : String) : Tuple(String?, String, String)?
#   values = data.split(/ – /)
#   matches = values.first.match(/(\w+) (\([\w\s, \w]+?\))/)
# 
#   return unless matches
# 
#   ret = matches.as(Regex::MatchData).to_a
#   ret[0] = values[1]?
# 
#   Tuple(String?, String, String).from(ret)
# end
# 
# def perform(name : String) : Array(Hash(String, Array(Tuple(String?, String, String))))
#   valid_headings(name).flat_map do |heading|
#     attributes = attribute_nodes(heading).flat_map do |attr|
#       class_data(attr).map do |data|
#         class_values(data)
#       end
#     end
# 
#     class_name = heading.inner_text
#       .split(/ /)
#       .map(&.capitalize.gsub(/[S|s]ubobject/) { "" })
#       .join
#       .gsub("Response") { name }
# 
#     {class_name => attributes.compact}
#   end
# end
# 
# def write_file(name : String)
#   perform(name).each do |hash|
#     name = name.split(/\//).last
#     klass = hash.keys.first
#     klass = klass.sub(klass.size - 1, "") if klass.ends_with?("s")
#     file_name = name.split(/(?=[A-Z])/).join("_").downcase
#     path = Path["output/#{name}"]
#     attributes = hash.values.first
# 
#     Dir.mkdir_p(path)
#     File.write("#{path}/#{file_name}.cr", definition(klass, attributes))
#   end
# end
# 
# ARGV.each do |name|
#   write_file(name)
# end

require "./sam_is_fucking_awesome"

if ARGV.empty?
  puts "API URI fragment not supplied"
  exit
end

ARGV.each do |klass_name|
  FileWriter.new(klass_name).write
end
