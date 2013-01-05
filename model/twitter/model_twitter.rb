require 'pg'

class ModelTwitter

    DB = PG::connect(:host => "ec2-54-243-243-176.compute-1.amazonaws.com", :user => "ygbclkxexdfglp", :password => "yq-Nx0zTQ-dxiDFJSllc-5FEkj", :dbname => "d4tk4tf7tdi5v2")

    def initialize(id)
        @id = id
    end
    def get_oauth_request_token
        res = DB.exec("select * from twitter_oauth_request where id = $1::bigint;", [@id])
        if res.values.empty?
            { :token => nil, :secret => nil }
        else
            { :token => res[0]["token"], :secret => res[0]["secret"] }
        end
    end
    def set_oauth_request_token(token)
        DB.exec("insert into twitter_oauth_request values ($1::bigint, $2::text, $3::text);", [@id, token[:token], token[:secret]])
    end
    def get_oauth_access_token
        res = DB.exec("select * from twitter_oauth_access where id = $1::bigint;", [@id])
        if res.values.empty?
            { :token => nil, :secret => nil }
        else
            { :token => res[0]["token"], :secret => res[0]["secret"] }
        end
    end
    def set_oauth_access_token(token)
        DB.exec("insert into twitter_oauth_access values ($1::bigint, $2::text, $3::text);", [@id, token[:token], token[:secret]])
    end
end
