require 'pp'
require 'savon'

#http://10.1.3.76:8676/?wsdl

@server_address = '10.1.3.76'
@server_port = 8676

def server_address; @server_address end
def server_port; @server_port end

wsdl_path = "http://#{server_address}:#{server_port}/?wdl"
@client = Savon.client(:wsdl => wsdl_path,
                       #:endpoint => endpoint,
                       :log => true )
def client; @client end
#client.logger.log_level = 0
pp client.operations
