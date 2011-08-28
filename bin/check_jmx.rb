#!/usr/bin/env jruby --ng
#
# Copyright (c) 2011 Matthias Nuessler <m.nuessler@web.de>
#
require 'java'
require 'rubygems'
require 'jmx4r' # install with: jruby -S gem install jmx4r
require 'optparse'

class String
  def to_underscore!
    self.gsub!(/[a-z][A-Z]+/) do |s|
      s.insert(1, '_').downcase!
    end
    self
  end
  def to_underscore
    self.clone.to_underscore!
  end
end

module NagiosJMX
  PLUGIN_VERSION = '0.1-beta'

  OK = 0
  WARNING = 1
  CRITICAL = 2
  UNKNOWN = 3

  def NagiosJMX.parse_options
    options = {:verbosity => 0}
    optparse = OptionParser.new do|opts|
      opts.on('-c', '--critical threshold', Integer, 'Critical threshold') do |c|
        options[:critical] = c
      end

      opts.on('-w', '--warning threshold', Integer, 'Warning threshold') do |w|
        options[:warning] = w
      end

      opts.on('-H', '--hostname HOST', 'MBean server hostname') do |h|
        options[:host] = h
      end

      opts.on('-P', '--port PORT', 'MBean server port') do |p|
        options[:port] = p
      end

      opts.on('-b', '--bean BEAN', 'Name of the MBean to query') do |b|
        options[:mbean] = b
      end

      opts.on('-a', '--attribute ATTR', 'MBean attribute or operation to query') do |a|
        options[:attribute] = a
      end

      opts.on('-u', '--username USER', 'User name for authentication  on MBean server') do |u|
        options[:username] = u
      end

      opts.on('-p', '--password PASS', 'Password for authentication on MBean server') do |p|
        options[:password] = p
      end
      
      opts.on('-v[vv]', [:v, :vv], "Run verbosely. [-v]: Single line, additional information. [-vv]: Multi line, configuration debug output. [-vvv]: Lots of detail for plugin problem diagnosis.") do |v|
        if v.nil?
          options[:verbosity] = 1
        elsif v == :v
          options[:verbosity] = 2
        elsif v == :vv
          options[:verbosity] = 3
        end
        puts "v: #{options[:verbosity]}"
      end
      
      opts.on('-V', '--version', 'Display version information') do |v|
        puts "Nagios JMX Plugin #{PLUGIN_VERSION}"
        exit UNKNOWN
      end
      
      opts.on('-h', '--help', 'Display this screen') do
        puts opts
        exit UNKNOWN
      end
    end

    begin
      optparse.parse!
      mandatory = [:critical, :warning, :host, :port, :mbean, :attribute]
      missing = mandatory.select{ |param| options[param].nil? }
      if not missing.empty?
        #        puts "Missing options: #{missing.join(', ')}"
        puts optparse
        exit UNKNOWN
      end                                                                                                                                          
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => msg
      puts msg
      puts optparse
      exit UNKNOWN
    end
    
    options
  end

  def NagiosJMX.perform_check(options = {})
    begin
      con_params = { :host => options[:host], :port => options[:port] }
      if [:username, :password].any? { |key| options.key?(key)  }
        con_params.merge(:username => options[:username], :password => options[:password])
      end
      
      JMX::MBean.establish_connection(con_params)
      mbean = JMX::MBean.find_by_name(options[:mbean])
      mbean.send(options[:attribute].to_underscore)
  
    rescue NoMethodError
      puts "No such attribute '#{options[:attribute]}' for MBean '#{options[:mbean]}'"
      if options[:verbosity == 3]
        all_attr = []
        mbean.attributes.each do |a|
          all_attr << a
        end
        puts "Existing attributes: #{all_attr.join(', ')}"
      end
      exit UNKNOWN
    rescue => msg
      puts msg
      exit UNKNOWN
    end
  end
  
  def NagiosJMX.check_status(value, warning_threshold, critical_threshold)
    status = OK
    status = WARNING if value > warning_threshold
    status = CRITICAL if value > critical_threshold
    status
  end

end

if $0 == __FILE__
  start = Time.now
  
  options = NagiosJMX.parse_options
  value = NagiosJMX.perform_check(options)
  status = NagiosJMX.check_status(value, options[:warning], options[:critical])

  status_names = {
    NagiosJMX::OK => 'OK', 
    NagiosJMX::WARNING => 'WARNING', 
    NagiosJMX::CRITICAL => 'CRITICAL', 
    NagiosJMX::UNKNOWN => 'UNKNOWN'
  }

  perf_data = "Check took #{Time.now - start} ms"
  puts "#{options[:attribute]} #{status_names[status]} - #{value}|#{perf_data}"
  exit status
  
end
