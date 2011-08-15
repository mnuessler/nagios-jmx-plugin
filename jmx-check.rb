require 'java'
require 'jmx4r'
# jruby -S gem install jmx4r
JMX::MBean.establish_connection(:host => "localhost", :port => 4711)
memory = JMX::MBean.find_by_name "java.lang:type=Memory"
memory.verbose = true
memory.gc

logging = JMX::MBean.find_by_name "java.util.logging:type=Logging"
logging.logger_names.each do |logger_name|
    #logging.set_logger_level logger_name, "INFO"
    puts logger_name
end

