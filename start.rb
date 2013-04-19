#!/usr/bin/env ruby

require 'thin'
require File.dirname(__FILE__) + '/app/alert_api'

server = ::Thin::Server.new('0.0.0.0', 9876, App)
server.log_file = 'thin.log'
server.pid_file = 'thin.pid'
server.daemonize
server.start
