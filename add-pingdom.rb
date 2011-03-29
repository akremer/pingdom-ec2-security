#!/usr/bin/env ruby
require 'openssl'
require 'base64'
require 'cgi'
require 'open-uri'
require 'rubygems'
require 'json'
require 'AWS'

# Set up your variables
PINGDOM_EMAIL = "your@email.com"
PINGDOM_PWD = "secret"
AWS_ACCESS_KEY_ID = "ABCDEFGHIJK"
AWS_SECRET_ACCESS_KEY = "lotsarandomchars"
SECURITY_GROUP_NAME = "mygroup"
PORT_NUMBERS = [-1]
PROTOCOL = "icmp"
# End variables

# The following can be changed, but it's just generic info
# for the Pingdom API, so you should probably leave it as-is.
PINGDOM_API_KEY = "oibyjy1yu9qn4pdkdql9h5abuuwi96i2"
PINGDOM_SERVER = "https://api.pingdom.com"
PINGDOM_API_VERSION = "2.0"

url = "#{PINGDOM_SERVER}/api/#{PINGDOM_API_VERSION}/probes"

auth_hdr = Base64.encode64("#{PINGDOM_EMAIL}:#{PINGDOM_PWD}") 

headers = {"Authorization" => "Basic #{auth_hdr}", "App-Key" => PINGDOM_API_KEY}

begin
  response = open(url, headers).read
rescue Exception => e
  puts "Caught exception opening #{url}"
  puts e.message
  puts e.backtrace.inspect
  Process.exit
rescue OpenURI::HTTPError => http_e
  puts "Received HTTP Error opening #{url}"
  puts http_e.io.status[0].to_s
  Process.exit
end

resp_hash = JSON.parse(response)

ec2 = AWS::EC2::Base.new(:access_key_id => AWS_ACCESS_KEY_ID, :secret_access_key => AWS_SECRET_ACCESS_KEY)
begin
  resp_hash["probes"].each do |probe|
    PORT_NUMBERS.each do |port|
      puts "Adding #{probe["ip"]}:#{port}"
      ec2.authorize_security_group_ingress({
        :group_name => SECURITY_GROUP_NAME,
        :ip_protocol => PROTOCOL,
        :from_port => port,
        :to_port => port,
        :cidr_ip => "#{probe["ip"]}/32"
      })
    end
  end
rescue Exception => e
  puts "Caught exception adding security groups"
  puts e.message
  Process.exit
end

puts "Security groups added successfully."