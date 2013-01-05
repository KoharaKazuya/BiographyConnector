# coding: utf-8

require './biographyconnector'

use Rack::Session::Cookie, :secret => "noeafnleknazevn3", :domain => "biographyconnector.herokuapp.com"
use Rack::Static, :urls => ["/js", "/img"], :root => "public"
run BiographyConnector.new
