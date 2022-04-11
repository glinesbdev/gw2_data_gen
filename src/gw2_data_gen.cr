require "http/client"
require "html5"

URL              = "https://wiki.guildwars2.com/wiki/API:2"
IGNORE_ATTRS     = ["access_token", "v", "id", "ids", "lang"]
INVALID_HEADINGS = ["Parameters", "Example", "Notes", "References", "Endpoints"]

page = nil

def create_getters(attributes : Array(Hash(String, String))) : Array(String)
  getters = attributes.flat_map do |item|
    item.map do |key, value|
      "getter #{key} : #{value}"
    end
  end

  getters.join("\n    ")
end

def definition(name : String, attributes : Array(Hash(String, String))) : String
  <<-FILE
require "json"

module Gw2Api
  struct #{name.capitalize}
    include JSON::Serializable

    #{create_getters(attributes)}
  end
end
FILE
end

def str_type(str : String) : String
  optional = str =~ /optional/
  str = str.gsub(/,.*/) { "" }

  case str
  when "string"
    optional ? "String?" : "String"
  when "number"
    optional ? "UInt32?" : "UInt32"
  when "array of strings"
    optional ? "Array(String)?" : "Array(String)"
  when "array of numbers"
    optional ? "Array(UInt32)?" : "Array(UInt32)"
  else
    "String"
  end
end

def html_page(page : String) : HTML5::Node
  page ||= HTML5.parse(HTTP::Client.get("#{URL}/#{page}").body)
end

def find_element_in_page(page : String, selector : String) : Array(HTML5::Node)
  html_page(page).css(selector)
end

def valid_headings(page : String) : Array(HTML5::Node)
  nodes = find_element_in_page(page, ".mw-parser-output .mw-headline").compact
  nodes.reject! { |el| INVALID_HEADINGS.includes?(el.inner_text) }
end

def element_values(nodes : Array(HTML5::Node))
  nodes.compact!
  text_values = nodes.map(&.inner_text.match(/^[a-z]+$/))
    .compact
    .map(&.as(Regex::MatchData).string)
    .reject { |text| IGNORE_ATTRS.includes?(text) }
end

# p valid_headings("items").map(&.inner_text)
File.write("test.cr", definition("Item", [{"id" => str_type("number")}, {"name" => str_type("string")}, {"binding" => str_type("string, optional")}]))
