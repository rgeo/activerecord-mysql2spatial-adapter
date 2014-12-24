# -----------------------------------------------------------------------------
#
# Tests for the Mysql2Spatial ActiveRecord adapter
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

require 'minitest/autorun'
require 'rgeo/active_record/adapter_test_helper'


module RGeo
  module ActiveRecord  # :nodoc:
    module Mysql2SpatialAdapter  # :nodoc:
      module Tests  # :nodoc:
        class TestBasic < ::Minitest::Test  # :nodoc:

          DATABASE_CONFIG_PATH = ::File.dirname(__FILE__)+'/database.yml'
          include RGeo::ActiveRecord::AdapterTestHelper

          define_test_methods do

            def populate_ar_class(content_)
              klass_ = create_ar_class
              case content_
              when :latlon_point
                klass_.connection.create_table(:spatial_test) do |t_|
                  t_.column 'latlon', :point
                end
              end
              klass_
            end


            def test_version
              assert_not_nil(::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::VERSION)
            end


            def test_create_simple_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :geometry
              end
              assert_equal(::RGeo::Feature::Geometry, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_point_geometry
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.column 'latlon', :point
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_geometry_with_index
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test, :options => 'ENGINE=MyISAM') do |t_|
                t_.column 'latlon', :geometry, :null => false
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.index([:latlon], :spatial => true)
              end
              assert(klass_.connection.indexes(:spatial_test).last.spatial)
            end


            def test_set_and_get_point
              klass_ = populate_ar_class(:latlon_point)
              obj_ = klass_.new
              assert_nil(obj_.latlon)
              obj_.latlon = @factory.point(1, 2)
              assert_equal(@factory.point(1, 2), obj_.latlon)
              assert_equal(3785, obj_.latlon.srid)
            end


            def test_set_and_get_point_from_wkt
              klass_ = populate_ar_class(:latlon_point)
              obj_ = klass_.new
              assert_nil(obj_.latlon)
              obj_.latlon = 'SRID=1000;POINT(1 2)'
              assert_equal(@factory.point(1, 2), obj_.latlon)
              assert_equal(1000, obj_.latlon.srid)
            end


            def test_save_and_load_point
              klass_ = populate_ar_class(:latlon_point)
              obj_ = klass_.new
              obj_.latlon = @factory.point(1, 2)
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(@factory.point(1, 2), obj2_.latlon)
              assert_equal(3785, obj2_.latlon.srid)
            end


            def test_save_and_load_point_from_wkt
              klass_ = populate_ar_class(:latlon_point)
              obj_ = klass_.new
              obj_.latlon = 'SRID=1000;POINT(1 2)'
              obj_.save!
              id_ = obj_.id
              obj2_ = klass_.find(id_)
              assert_equal(@factory.point(1, 2), obj2_.latlon)
              assert_equal(1000, obj2_.latlon.srid)
            end


            def test_readme_example
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test, :options => 'ENGINE=MyISAM') do |t_|
                t_.column(:latlon, :point, :null => false)
                t_.line_string(:path)
                t_.geometry(:shape)
              end
              klass_.connection.change_table(:spatial_test) do |t_|
                t_.index(:latlon, :spatial => true)
              end
              klass_.class_eval do
                self.rgeo_factory_generator = ::RGeo::Geos.method(:factory)
                set_rgeo_factory_for_column(:latlon, ::RGeo::Geographic.spherical_factory)
              end
              rec_ = klass_.new
              rec_.latlon = 'POINT(-122 47)'
              loc_ = rec_.latlon
              assert_equal(47, loc_.latitude)
              rec_.shape = loc_
              assert_equal(true, ::RGeo::Geos.is_geos?(rec_.shape))
            end


            def test_create_simple_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.geometry 'latlon'
              end
              assert_equal(::RGeo::Feature::Geometry, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_point_geometry_using_shortcut
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.point 'latlon'
              end
              assert_equal(::RGeo::Feature::Point, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('latlon'))
            end


            def test_create_geometry_using_limit
              klass_ = create_ar_class
              klass_.connection.create_table(:spatial_test) do |t_|
                t_.spatial 'geom', :limit => {:type => :line_string}
              end
              assert_equal(::RGeo::Feature::LineString, klass_.columns.last.geometric_type)
              assert(klass_.cached_attributes.include?('geom'))
            end

          end

        end
      end
    end
  end
end
