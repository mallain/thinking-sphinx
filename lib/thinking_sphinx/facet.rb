module ThinkingSphinx
  class Facet
    attr_reader :reference
    
    def initialize(reference)
      @reference = reference
      
      if reference.columns.length != 1
        raise "Can't translate Facets on multiple-column field or attribute"
      end
    end

    def self.name_for(facet)
      case facet
      when Facet
        facet.name
      when String, Symbol
        facet.to_s.gsub(/(_facet|_crc)$/,'').to_sym
      end
    end
    
    def name
      reference.unique_name
    end

    def self.attribute_name_for(name)
      name.to_s == 'class' ? 'class_crc' : "#{name}_facet"
    end
    
    def attribute_name
      # @attribute_name ||= case @reference
      # when Attribute
      #   @reference.unique_name.to_s
      # when Field
      @attribute_name ||= @reference.unique_name.to_s + "_facet"
      # end
    end
    
    def value(object, attribute_value)
      return translate(object, attribute_value) if @reference.is_a?(Field)
      
      case @reference.type
      when :string
        translate(object, attribute_value)
      when :datetime
        Time.at(attribute_value)
      when :boolean
        attribute_value > 0
      else
        attribute_value
      end
    end
    
    def to_s
      name
    end
    
    private
    
    def translate(object, attribute_value)
      column.__stack.each { |method|
        # if the object is an array
        if object.is_a? Array

          # Create a new temporarly variable
          object_tmp = Array.new

          # Browse the array
          object.each_index do |o|
            object_tmp << object[o].send(method)
          end

          # Refresh the object variable
          object = object_tmp

          # Clearing Processing
          object = collec_object(object)
        else
          # It s a Klass object like UserProfile, Community, etc...
          object = object.send(method)
        end
      }

      # If the object return several results
      if object.is_a? Array and object.length > 0
        object.each do |o|
          # If the object is an Array
          if o.is_a? Array
            # If the object first is not nil 
            unless o.first.nil?
              o.first.send(column.__name)
            end
          else
            # If the object o is not nil		
            unless o.nil?
              o.send(column.__name)
            end
          end
        end
      else
        # One result
        if !object.is_a? Array
          object.send(column.__name)
        end
      end
    end

    # collec_object
    # delete item empty and return object proper
    #
    # Arguments
    # Object is a Array
    # Object represent this architecture
    # [0] => Empty Array
    # [1] => [0] => Addresses, [1] Addresses
    # [2] => [0] => Addresses, [1] Addresses
    # [3] => Empty Array
    def collec_object(object)
      # Instanciate the result_object object
      result_object = Array.new

      # Browse the array
      object.each_index do |o|
        # If the object is an Array
        if object[o].is_a? Array
          # Checking if the Array is not null
          if !object[o].length.eql?(0)
            # Browse results
            object[o].each do |results|
              # Filling Array
              result_object[result_object.length] = results
            end
          end
        else
          # Object is a Klass like UserProfile, Community
          result_object << object[o]
        end
      end

      return result_object
    end
    
    def column
      @reference.columns.first
    end
  end
end
