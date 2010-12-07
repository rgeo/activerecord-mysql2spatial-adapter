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


require 'rgeo/active_record'
require 'active_record/connection_adapters/mysql2_adapter'


module ActiveRecord
  
  class Base
    
    
    # Create a mysql2spatial connection adapter
    
    def self.mysql2spatial_connection(config_)
      config_[:username] = 'root' if config_[:username].nil?
      if ::Mysql2::Client.const_defined?(:FOUND_ROWS)
        config_[:flags] = ::Mysql2::Client::FOUND_ROWS
      end
      client_ = ::Mysql2::Client.new(config_.symbolize_keys)
      options_ = [config_[:host], config_[:username], config_[:password], config_[:database], config_[:port], config_[:socket], 0]
      ConnectionAdapters::Mysql2SpatialAdapter.new(client_, logger, options_, config_)
    end
    
    
  end
  
  
  module ConnectionAdapters  # :nodoc:
    
    class Mysql2SpatialAdapter < Mysql2Adapter  # :nodoc:
      
      
      ADAPTER_NAME = 'Mysql2Spatial'.freeze
      
      NATIVE_DATABASE_TYPES = Mysql2Adapter::NATIVE_DATABASE_TYPES.merge(:geometry => {:name => "geometry"}, :point => {:name => "point"}, :line_string => {:name => "linestring"}, :polygon => {:name => "polygon"}, :geometry_collection => {:name => "geometrycollection"}, :multi_point => {:name => "multipoint"}, :multi_line_string => {:name => "multilinestring"}, :multi_polygon => {:name => "multipolygon"})
      
      
      def native_database_types
        NATIVE_DATABASE_TYPES
      end
      
      
      def adapter_name
        ADAPTER_NAME
      end
      
      
      def quote(value_, column_=nil)
        if ::RGeo::Feature::Geometry.check_type(value_)
          "GeomFromWKB(0x#{::RGeo::WKRep::WKBGenerator.new(:hex_format => true).generate(value_)},#{value_.srid})"
        else
          super
        end
      end
      
      
      def add_index(table_name_, column_name_, options_={})
        if options_[:spatial]
          index_name_ = index_name(table_name_, :column => Array(column_name_))
          if ::Hash === options_
            index_name_ = options_[:name] || index_name_
          end
          execute "CREATE SPATIAL INDEX #{index_name_} ON #{table_name_} (#{Array(column_name_).join(", ")})"
        else
          super
        end
      end
      
      
      def columns(table_name_, name_=nil)
        result_ = execute("SHOW FIELDS FROM #{quote_table_name(table_name_)}", :skip_logging)
        columns_ = []
        result_.each(:symbolize_keys => true, :as => :hash) do |field_|
          columns_ << SpatialColumn.new(field_[:Field], field_[:Default], field_[:Type], field_[:Null] == "YES")
        end
        columns_
      end
      
      
      def indexes(table_name_, name_=nil)
        indexes_ = []
        current_index_ = nil
        result_ = execute("SHOW KEYS FROM #{quote_table_name(table_name_)}", name_)
        result_.each(:symbolize_keys => true, :as => :hash) do |row_|
          if current_index_ != row_[:Key_name]
            next if row_[:Key_name] == 'PRIMARY' # skip the primary key
            current_index_ = row_[:Key_name]
            indexes_ << ::RGeo::ActiveRecord::SpatialIndexDefinition.new(row_[:Table], row_[:Key_name], row_[:Non_unique] == 0, [], [], row_[:Index_type] == 'SPATIAL')
          end
          indexes_.last.columns << row_[:Column_name]
          indexes_.last.lengths << row_[:Sub_part]
        end
        indexes_
      end
      
      
      class SpatialColumn < ConnectionAdapters::Mysql2Column  # :nodoc:
        
        
        def initialize(name_, default_, sql_type_=nil, null_=true)
          super(name_, default_,sql_type_, null_)
          @geometric_type = ::RGeo::ActiveRecord.geometric_type_from_name(sql_type_)
          @ar_class = ::ActiveRecord::Base
        end
        
        
        def set_ar_class(val_)
          @ar_class = val_
        end
        
        
        attr_reader :geometric_type
        
        
        def spatial?
          type == :geometry
        end
        
        
        def klass
          type == :geometry ? ::RGeo::Feature::Geometry : super
        end
        
        
        def type_cast(value_)
          type == :geometry ? SpatialColumn.string_to_geometry(value_, @ar_class) : super
        end
        
        
        def type_cast_code(var_name_)
          type == :geometry ? "::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::SpatialColumn.string_to_geometry(#{var_name_}, self.class)" : super
        end
        
        
        private
        
        def simplified_type(sql_type_)
          sql_type_ =~ /geometry|point|linestring|polygon/i ? :geometry : super
        end
        
        
        def self.string_to_geometry(str_, ar_class_)
          case str_
          when ::RGeo::Feature::Geometry
            str_
          when ::String
            marker_ = str_[4,1]
            factory_generator_ = ar_class_.rgeo_factory_generator
            if marker_ == "\x00" || marker_ == "\x01"
              ::RGeo::WKRep::WKBParser.new(factory_generator_, :default_srid => str_[0,4].unpack(marker_ == "\x01" ? 'V' : 'N').first).parse(str_[4..-1])
            else
              ::RGeo::WKRep::WKTParser.new(factory_generator_, :support_ewkt => true).parse(str_)
            end
          else
            nil
          end
        end
        
        
      end
      
      
    end
    
  end
  
  
end
