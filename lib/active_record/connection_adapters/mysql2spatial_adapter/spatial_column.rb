# -----------------------------------------------------------------------------
#
# Mysql2Spatial adapter for ActiveRecord
#
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


# :stopdoc:

module ActiveRecord

  module ConnectionAdapters

    module Mysql2SpatialAdapter


      # ActiveRecord 3.2 uses ConnectionAdapters::Mysql2Adapter::Column
      # whereas 3.0 and 3.1 use ConnectionAdapters::Mysql2Column
      column_base_class_ = defined?(ConnectionAdapters::Mysql2Adapter::Column) ?
        ConnectionAdapters::Mysql2Adapter::Column : ConnectionAdapters::Mysql2Column

      class SpatialColumn < column_base_class_


        FACTORY_SETTINGS_CACHE = {}


        def initialize(factory_settings_, table_name_, name_, default_, sql_type_=nil, null_=true)
          @factory_settings = factory_settings_
          @table_name = table_name_
          super(name_, default_,sql_type_, null_)
          @geometric_type = ::RGeo::ActiveRecord.geometric_type_from_name(sql_type_)
          if type == :spatial
            @limit = { type: @geometric_type.type_name.underscore }
          end
          FACTORY_SETTINGS_CACHE[factory_settings_.object_id] = factory_settings_
        end


        attr_reader :geometric_type


        def spatial?
          type == :spatial
        end


        def klass
          type == :spatial ? ::RGeo::Feature::Geometry : super
        end


        def type_cast(value_)
          if type == :spatial
            SpatialColumn.convert_to_geometry(value_, @factory_settings, @table_name, name)
          else
            super
          end
        end


        def type_cast_code(var_name_)
          if type == :spatial
            "::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::SpatialColumn.convert_to_geometry("+
              "#{var_name_}, ::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::SpatialColumn::"+
              "FACTORY_SETTINGS_CACHE[#{@factory_settings.object_id}], #{@table_name.inspect}, #{name.inspect})"
          else
            super
          end
        end


        private

        def simplified_type(sql_type_)
          sql_type_ =~ /geometry|point|linestring|polygon/i ? :spatial : super
        end


        def self.convert_to_geometry(input_, factory_settings_, table_name_, column_)
          case input_
          when ::RGeo::Feature::Geometry
            factory_ = factory_settings_.get_column_factory(table_name_, column_, :srid => input_.srid)
            ::RGeo::Feature.cast(input_, factory_) rescue nil
          when ::String
            marker_ = input_[4,1]
            if marker_ == "\x00" || marker_ == "\x01"
              factory_ = factory_settings_.get_column_factory(table_name_, column_,
                :srid => input_[0,4].unpack(marker_ == "\x01" ? 'V' : 'N').first)
              ::RGeo::WKRep::WKBParser.new(factory_).parse(input_[4..-1]) rescue nil
            elsif input_[0,10] =~ /[0-9a-fA-F]{8}0[01]/
              srid_ = input_[0,8].to_i(16)
              if input[9,1] == '1'
                srid_ = [srid_].pack('V').unpack('N').first
              end
              factory_ = factory_settings_.get_column_factory(table_name_, column_, :srid => srid_)
              ::RGeo::WKRep::WKBParser.new(factory_).parse(input_[8..-1]) rescue nil
            else
              factory_ = factory_settings_.get_column_factory(table_name_, column_)
              ::RGeo::WKRep::WKTParser.new(factory_, :support_ewkt => true).parse(input_) rescue nil
            end
          else
            nil
          end
        end


      end


    end

  end

end

# :startdoc:
