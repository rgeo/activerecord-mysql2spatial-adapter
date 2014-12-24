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


# The activerecord-mysql2spatial-adapter gem installs the *mysql2spatial*
# connection adapter into ActiveRecord.

module ActiveRecord


  # ActiveRecord looks for the mysql2spatial_connection factory method in
  # this class.

  class Base


    # Create a mysql2spatial connection adapter.

    def self.mysql2spatial_connection(config_)
      config_[:username] = 'root' if config_[:username].nil?
      if ::Mysql2::Client.const_defined?(:FOUND_ROWS)
        config_[:flags] = ::Mysql2::Client::FOUND_ROWS
      end
      client_ = ::Mysql2::Client.new(config_.symbolize_keys)
      options_ = [config_[:host], config_[:username], config_[:password], config_[:database], config_[:port], config_[:socket], 0]
      ::ActiveRecord::ConnectionAdapters::Mysql2SpatialAdapter::MainAdapter.new(client_, logger, options_, config_)
    end


  end


  # All ActiveRecord adapters go in this namespace.
  module ConnectionAdapters

    # The Mysql2Spatial adapter
    module Mysql2SpatialAdapter

      # The name returned by the adapter_name method of this adapter.
      ADAPTER_NAME = 'Mysql2Spatial'.freeze

    end

  end


end


require 'active_record/connection_adapters/mysql2spatial_adapter/version.rb'
require 'active_record/connection_adapters/mysql2spatial_adapter/main_adapter.rb'
require 'active_record/connection_adapters/mysql2spatial_adapter/spatial_column.rb'
require 'active_record/connection_adapters/mysql2spatial_adapter/arel_tosql.rb'
require 'active_record/type/spatial.rb'
