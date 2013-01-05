# coding: utf-8

require './biographyconnector'

use Rack::Session::Cookie, :secret => "test", :domain => "127.0.0.1"
use Rack::Static, :urls => ["/js", "/img"], :root => "public"
run BiographyConnector.new
