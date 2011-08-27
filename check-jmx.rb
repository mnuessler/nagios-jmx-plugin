#!/usr/bin/env jruby
require 'java'
require 'rubygems'
require 'jmx4r' # jruby -S gem install jmx4r
require 'optparse'
require 'pp'

retVals = {
  :ok => 0,
  :warning => 1,
  :critical => 2,
  :unknown => 3
}

options = {}
optparse = OptionParser.new do|opts|
  opts.on('-c', '--critical threshold', Integer, 'Critical threshold') do |c|
    options[:critical] = c
  end

  opts.on('-w', '--warning threshold', Integer, 'Warning threshold') do |w|
    options[:warning] = w
  end

  opts.on('-H', '--host HOST', 'MBean server hostname') do |h|
    options[:host] = h
  end

  opts.on('-P', '--port PORT', 'MBean server port') do |p|
    options[:port] = p
  end

  opts.on('-b', '--bean BEAN', 'Name of the MBean to query') do |b|
    options[:bean] = b
  end

  opts.on('-a', '--attribute ATTR', 'MBean attribute or operation to query') do |a|
    options[:attribute] = a
  end

  opts.on('-u', '--user USER', 'User name for authentication  on MBean server') do |u|
    options[:user] = u
  end

  opts.on('-p', '--password PASS', 'Password for authentication on MBean server')  do |p|
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit retVals[:unknown]
  end
end

optparse.parse!

pp "Options:", options
pp "ARGV:", ARGV

options.has_key? :host or exit retVals[:unknown]

begin
  JMX::MBean.establish_connection(:host => options[:host], :port => options[:port])
  bean = JMX::MBean.find_by_name options[:bean]
  value = bean.send(options[:attribute])
  puts value
  
  if value >= options[:critical]
    exit retVals[:critical]
  elsif value >= options[:warning]
    exit retVals[:warning]
  else
    exit retVals[:ok]
  end
  
rescue NoMethodError
  puts "No such attribute #{options[:attribute]} for MBean #{options[:bean]}"
  exit retVals[:unknown]
rescue => msg
  puts msg
  exit retVals[:unknown]
end
