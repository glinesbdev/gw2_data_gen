require "http/client"
require "html5"

class KlassGuts
  getter html_node : String

  def initialize(@html_node)
  end

  def to_s
    no_guts_no_glory
  end

  private def array
    /array/ =~ html_node ? "Array(" : ""
  end

  private def boolean
    /boolean/ =~ html_node ? "Bool" : ""
  end

  private def closer
    array.empty? ? "" : ")"
  end

  private def crystal_type
    %Q{#{array}#{boolean}#{integer}#{string}#{closer}#{optional}}
  end

  private def documentation
    html_node.split(/ – /).last
  end

  private def integer
    /(?:number|integer)/ =~ html_node ? "UInt32" : ""
  end

  private def method_name
    html_node.split(" ").first
  end

  private def no_guts_no_glory
    %Q{\t# #{documentation}\n\tgetter #{method_name} : #{crystal_type}}
  end

  private def optional
    /optional/ =~ html_node ? "?" : ""
  end

  private def string
    /string/ =~ html_node ? "String" : ""
  end
end

class WikiConverter
  getter klass_name : String
  property parser   : HtmlParser

  def initialize(@klass_name)
    @parser = HtmlParser.new(klass_name)
  end

  def to_s
    definition
  end

  private def definition
    %Q{require "json"

module Gw2Api
  struct #{pretty_klass_name}
    include JSON::Serializable

    #{guts}
  end
end
}
  end
  
  private def guts
    @parser.sections.map(&.to_s).join("\n")
  end

  private def pretty_klass_name
    klass_name.split("/").last.camelcase
  end
end

class HtmlParser
  INVALID_HEADINGS = ["Parameters", "Example", "Notes", "References", "Endpoints", "Subobjects", "Other types"]
  URL              = "https://wiki.guildwars2.com/wiki/API:2"

  getter klass_name : String

  def initialize(@klass_name)
  end

  def sections
    parsed_sections
  end

  private def headings
    parsed_html.css(".mw-parser-output .mw-headline").compact
  end

  private def html
    HTTP::Client.get("#{URL}/#{klass_name}").body
  end

  private def parsed_html
    HTML5.parse(html)
  end

  private def parsed_sections
    valid_headings.map { |heading| HtmlSection.new(heading) }
  end

  private def valid_headings
    headings.reject { |heading| INVALID_HEADINGS.includes?(heading.inner_text) }
  end
end

class HtmlSection
  getter heading : HTML5::Node

  def initialize(@heading)
  end

  def to_s
    no_guts_no_glory
  end

  private def attributes
    heading.xpath_nodes("../following-sibling::ul[1]")
  end

  private def no_guts_no_glory
    attributes.flat_map do |attribute|
      attribute.inner_text.split("\n").map do |attr|
        KlassGuts.new(attr).to_s
      end
    end.join("\n")
  end
end

class FileWriter
  getter klass_name : String
  property converter : WikiConverter

  def initialize(@klass_name)
    @converter = WikiConverter.new(klass_name)
  end
  
  def write
    make_shit_happen
  end

  private def crystal_klass_name
    path_parts.last
  end

  private def dirpath
    "output/#{path_parts.dup.truncate(path_parts.size - 1, 1).join("/")}"
  end

  private def filename
    "#{crystal_klass_name}.cr"
  end

  private def filepath
    Path["#{dirpath}/#{filename}"]
  end

  private def make_dirpath
    Dir.mkdir_p(dirpath)
  end

  private def make_shit_happen
    make_dirpath
    write_file
  end

  private def path_parts
    klass_name.split("/")
  end

  private def write_file
    File.write(filepath, @converter.to_s)
  end
end