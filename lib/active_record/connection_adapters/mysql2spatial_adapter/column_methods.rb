module ActiveRecord
  module ConnectionAdapters
    module Mysql2SpatialAdapter
      module ColumnMethods
        def spatial(name, options = {})
          unless options[:limit][:type]
            raise "You must set a type. For example: 't.spatial limit: { type: 'point' }'"
          end

          column(name, options[:limit][:type], options)
        end

        def geography(name, options = {})
          column(name, :geography, options)
        end

        def geometry(name, options = {})
          column(name, :geometry, options)
        end

        def geometry_collection(name, options = {})
          column(name, :geometry_collection, options)
        end

        def line_string(name, options = {})
          column(name, :line_string, options)
        end

        def multi_line_string(name, options = {})
          column(name, :multi_line_string, options)
        end

        def multi_point(name, options = {})
          column(name, :multi_point, options)
        end

        def multi_polygon(name, options = {})
          column(name, :multi_polygon, options)
        end

        def point(name, options = {})
          column(name, :point, options)
        end
      end

      ConnectionAdapters::TableDefinition.include ColumnMethods
    end
  end
end
