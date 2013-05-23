# coding: utf-8

require 'rack/request'
require 'rack/response'
require 'erb'
require 'oauth'
require './parser/twitter/twitter_parser'
require './parser/twitter/twitter_o_auth_key'
require './model/twitter/model_twitter'

include Rack
include OAuth
include TwitterOAuthKey

class BiographyConnector

    ROOT_URL = "http://biographyconnector.herokuapp.com/"
    PUB_DIR = "./public"

    def call(env)
        req = Request.new(env)
        session = req.session
        session["id"] ||= (rand(2 ** 32) - 2 ** 31).to_i
        model = ModelTwitter.new(session["id"])
        case req.path
        when "/result/twitter.html"
            twitter_id = req.params['twitter_id'] || session["twitter_id"]
            token = model.get_oauth_access_token
            if token[:token] and token[:secret]
                body = ERB.new(File.read(PUB_DIR + "/result/twitter.html")).result(binding)
            else
                session["twitter_id"] = twitter_id
                cons = Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com")
                req_token = cons.get_request_token(:oauth_callback => ROOT_URL + "authorize/callback")
                model.set_oauth_request_token({:token => req_token.token, :secret => req_token.secret})
                return Response.new { |res|
                    res.redirect(req_token.authorize_url, 303)
                }.finish
            end
        when "/result/twitter.json"
            twitter_id = req.params['twitter_id']
            begin
                token = model.get_oauth_access_token
                body = {
                    "type" => "success",
                    "data" => TwitterParser.new(token[:token], token[:secret]).find_bros(twitter_id)
                    }.to_json
            rescue Twitter::Error::TooManyRequests => e
                body = {
                    "type" => "error",
                    "time" => e.rate_limit.reset_in.to_s
                    }.to_json
            end
        when "/authorize/callback"
            token = model.get_oauth_request_token
            cons = Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, :site => "https://twitter.com/")
            req_token = RequestToken.new(cons, token[:token], token[:secret])
            twitter_id = session['twitter_id']
            access_token = req_token.get_access_token(
                {},
                :oauth_token => req.params["oauth_token"],
                :oauth_verifier => req.params["oauth_verifier"])
            model.set_oauth_access_token({:token => access_token.token, :secret => access_token.secret})
            return Response.new { |res|
                res.redirect("/result/twitter.html?twitter_id=#{twitter_id}", 303)
            }.finish
        else
            return Response.new { |res| res.redirect("/index.html", 303) }.finish
        end
        Response.new { |res|
            res.status = 200
            res['Content-Type'] = "text/html;charset=utf-8"
            res.write body
        }.finish
    end
end
