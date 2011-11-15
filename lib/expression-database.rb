# = DESCRIPTION
# This file handles all requirements and session managment

begin
  	require 'rubygems'
  	require 'bio'
	require 'active_record'
	require 'composite_primary_keys'
end

gem 'activerecord', '>= 3.0'
gem 'activesupport', '>= 3.0'

require File.dirname(__FILE__) + '/files/db_connection.rb'
require File.dirname(__FILE__) + '/files/activerecord.rb'
