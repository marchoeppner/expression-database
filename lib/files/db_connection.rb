#!/usr/bin/ruby
# = DESCRIPTION
# This files handles connections to the expression database

Expression_DB_ADAPTER = 'postgresql'
Expression_DB_HOST = 'localhost'
Expression_DATABASE = ''
Expression_DB_USERNAME = 'tools'
Expression_DB_PASSWORD = 'analysis'
#Expression_DB_Port = 3306

module ExpressionDB
  
  	include ActiveRecord
  
	class DBConnection < ActiveRecord::Base
	  	self.abstract_class = true
  		self.pluralize_table_names = false
    	
    	def self.connect(version="",args={})

      		establish_connection(
                            :adapter => args[:adapter] ||= Expression_DB_ADAPTER,
                            :host => args[:host] ||= Expression_DB_HOST,
                            :database => "expression_db_#{version}" ,
                            :username => args[:username] ||= Expression_DB_USERNAME,
                            :password => args[:password] ||= Expression_DB_PASSWORD
                            #:port => args[:port] ||= Expression_DB_Port  
                          )
    	end
  
  	end
  
end
