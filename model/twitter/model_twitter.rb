require 'sqlite3'

include SQLite3

class ModelTwitter

    DB = Database.new("./db")

    def initialize(id)
        @id = id
    end
    def get_oauth_request_token
        token, secret = DB.execute("select token, secret from TwitterOAuthRequest where id = ?", @id)[0]
        { :token => token, :secret => secret }
    end
    def set_oauth_request_token(token)
        DB.execute("insert into TwitterOAuthRequest values (?, ?, ?)", @id, token[:token], token[:secret])
    end
    def get_oauth_access_token
        token, secret = DB.execute("select token, secret from TwitterOAuthAccess where id = ?", @id)[0]
        { :token => token, :secret => secret }
    end
    def set_oauth_access_token(token)
        DB.execute("insert into TwitterOAuthAccess values (?, ?, ?)", @id, token[:token], token[:secret])
    end
end
