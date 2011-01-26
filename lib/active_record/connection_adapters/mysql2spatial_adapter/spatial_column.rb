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


module ActiveRecord
  
  module ConnectionAdapters
    
    module Mysql2SpatialAdapter
      
      
      class SpatialColumn < ConnectionAdapters::Mysql2Column
        
        
        def initialize(name_, default_, sql_type_=nil, null_=true)
          super(name_, default_,sql_type_, null_)
          @geometric_type = ::RGeo::ActiveRecord.geometric_type_from_name(sql_type_)
          if type == :spatial
            @limit = {:type => @geometric_type.type_name.underscore}
          end
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
          type == :geometry ? SpatialColumn.convert_to_geometry(value_, @ar_class, name) : super
        end
        
        
        def type_cast_code(var_name_)
          type == :geometry ? "::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::SpatialColumn.convert_to_geometry(#{var_name_}, self.class, #{name.inspect})" : super
        end
        
        
        private
        
        def simplified_type(sql_type_)
          sql_type_ =~ /geometry|point|linestring|polygon/i ? :geometry : super
        end
        
        
        def self.convert_to_geometry(input_, ar_class_, column_)
          case input_
          when ::RGeo::Feature::Geometry
            factory_ = ar_class_.rgeo_factory_for_column(column_, :srid => input_.srid)
            ::RGeo::Feature.cast(input_, factory_)
          when ::String
            marker_ = input_[4,1]
            if marker_ == "\x00" || marker_ == "\x01"
              factory_ = ar_class_.rgeo_factory_for_column(column_, :srid => input_[0,4].unpack(marker_ == "\x01" ? 'V' : 'N').first)
              ::RGeo::WKRep::WKBParser.new(factory_).parse(input_[4..-1])
            else
              factory_ = ar_class_.rgeo_factory_for_column(column_)
              ::RGeo::WKRep::WKTParser.new(factory_, :support_ewkt => true).parse(input_)
            end
          else
            nil
          end
        end
        
        
      end
      
      
    end
    
  end
  
end
