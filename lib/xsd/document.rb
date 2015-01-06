module Xsd

  BUILD_IN_TYPES = {'type:http://www.w3.org/2001/XMLSchema:decimal' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:float' => {'type' => 'number'},
                    'type:http://www.w3.org/2001/XMLSchema:double' => {'type' => 'number'},
                    'type:http://www.w3.org/2001/XMLSchema:integer' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:positiveInteger' => {'type' => 'integer', 'minimum' => 0, 'exclusiveMinimum' => true},
                    'type:http://www.w3.org/2001/XMLSchema:negativeInteger' => {'type' => 'integer', 'maximum' => 0, 'exclusiveMaximum' => true},
                    'type:http://www.w3.org/2001/XMLSchema:nonPositiveInteger' => {'type' => 'integer', 'maximum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:nonNegativeInteger' => {'type' => 'integer', 'minimum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:long' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:int' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:short' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:byte' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:unsignedLong' => {'type' => 'integer', 'minimum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:unsignedInt' => {'type' => 'integer', 'minimum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:unsignedShort' => {'type' => 'integer', 'minimum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:unsignedByte' => {'type' => 'integer', 'minimum' => 0},
                    'type:http://www.w3.org/2001/XMLSchema:date' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:dateTime' => {'$ref' => 'DateTime'},
                    'type:http://www.w3.org/2001/XMLSchema:gYearMonth' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:gYear' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:duration' => {'type' => 'string', 'pattern' => 'P([0-9]*Y)?([0-9]*M)?([0-9]*D)?(T([0-9]*H)?([0-9]*M)?([0-9]*S)?)?'},
                    'type:http://www.w3.org/2001/XMLSchema:time' => {'$ref' => 'Time'},
                    'type:http://www.w3.org/2001/XMLSchema:gMonthDay' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:gMonth' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:gDay' => {'$ref' => 'Date'},
                    'type:http://www.w3.org/2001/XMLSchema:string' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:token' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:language' => {'type' => 'string', 'enum' => %w{en es}},
                    'type:http://www.w3.org/2001/XMLSchema:NMTOKEN' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:NMTOKENS' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:Name' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:NameNC' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:ID' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:IDREF' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:IDREFS' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:ENTITY' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:ENTITIES' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:QName' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:boolean' => {'type' => 'boolean'},
                    'type:http://www.w3.org/2001/XMLSchema:hexBinary' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:base64Binary' => {'type' => 'integer'},
                    'type:http://www.w3.org/2001/XMLSchema:anyURI' => {'type' => 'string'},
                    'type:http://www.w3.org/2001/XMLSchema:notation' => {'type' => 'string'}}.freeze

  class Document < Nokogiri::XML::SAX::Document

    [Xsd::Schema, Element, ComplexType, SimpleType].each do |tag_type|
      class_eval("def start_#{tag_type.tag_name.gsub(':', '_')}(attributes = [])
          #{tag_type == Xsd::Schema ? '@schema = ' : ''}#{tag_type}.new(top_if_available, attributes)
        end")
    end

    attr_reader :uri
    attr_reader :schema

    def initialize(uri, str_doc)
      @uri = uri
      @stack = [:floor]

      parser = Nokogiri::XML::SAX::Parser.new(self)
      parser.parse(str_doc)
    end

    def start_element(name, attributes = [])
      unless @xsd_tag
        @xsd_tag = 'http://www.w3.org/2001/XMLSchema'
        if attr = attributes.detect { |attr| attr[0] =~ /\Axmlns:/ && attr[1] == 'http://www.w3.org/2001/XMLSchema' }
          @xsd_tag = attr[0].from(attr[0].index(':') + 1)
        end
      end
      name = "xs:#{name.from(@xsd_tag.length + 1)}" if name.start_with?("#{@xsd_tag}:")
      primary_method = "start_#{name.gsub(':', '_')}".to_sym
      push process_element_message(primary_method, :start_element, name, attributes)
    end

    def end_element(name)
      name = "xs:#{name.from(@xsd_tag.length + 1)}" if name.start_with?("#{@xsd_tag}:")
      primary_method = "end_#{name.gsub(':', '_')}".to_sym
      if (element = push process_element_message(primary_method, :end_element, name)) &&
          top.respond_to?(parent_callback_method = "when_#{primary_method}".to_sym)
        top.send(parent_callback_method, element)
      end
    end

    private

    def process_element_message(primary_method, alternative_method, name, attributes=nil)
      if top.respond_to?(primary_method)
        if attributes
          return top.send(primary_method, attributes)
        end

        return top.send(primary_method)
      elsif top_available? && top.respond_to?(alternative_method)
        if attributes
          return top.send(alternative_method, name, attributes)
        end

        return top.send(alternative_method, name)
      elsif self.respond_to?(primary_method)
        if attributes
          return self.send(primary_method, attributes)
        end

        return self.send(primary_method)
      end

      return nil
    end

    def push(obj)
      if obj == :pop
        @stack.pop
      else
        @stack << obj if obj
      end
    end

    def pop
      @stack.last == :floor ? self : @stack.pop
    end

    def pop!
      pop while top_available?
      @stack.pop
      @stack << :floor if @stack.empty?
    end

    def top
      @stack.last == :floor ? self : @stack.last
    end

    def top_if_available
      top_available? ? top : nil
    end

    def top_available?
      @stack.last != :floor
    end
  end
end