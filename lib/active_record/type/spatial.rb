module ActiveRecord
  module Type
    class Spatial < Value # :nodoc:
      def type
        :spatial
      end

      def spatial?
        type == :spatial
      end

      def klass
        type == :spatial ? ::RGeo::Feature::Geometry : super
      end

      def set_geo_params(factory_settings, table_name, geometric_type)
        @factory_settings = factory_settings
        @table_name = table_name
        @geometric_type = geometric_type
      end

      private

      def cast_value(value)
        case value
        when ::RGeo::Feature::Geometry
          factory = @factory_settings.get_column_factory(@table_name, @column, :srid => value.srid)
          ::RGeo::Feature.cast(value, factory) rescue nil
        when ::String
          marker = value[4,1]
          if marker == "\x00" || marker == "\x01"
            factory = @factory_settings.get_column_factory(@table_name, @column,
              :srid => value[0,4].unpack(marker == "\x01" ? 'V' : 'N').first)
            ::RGeo::WKRep::WKBParser.new(factory).parse(value[4..-1]) rescue nil
          elsif value[0,10] =~ /[0-9a-fA-F]{8}0[01]/
            srid = value[0,8].to_i(16)
            if value[9,1] == '1'
              srid = [srid].pack('V').unpack('N').first
            end
            factory = @factory_settings.get_column_factory(@table_name, @column, :srid => srid)
            ::RGeo::WKRep::WKBParser.new(factory).parse(value[8..-1]) rescue nil
          else
            factory = @factory_settings.get_column_factory(@table_name, @column)
            ::RGeo::WKRep::WKTParser.new(factory, :support_ewkt => true).parse(value) rescue nil
          end
        else
          nil
        end
      end
    end
  end
end
