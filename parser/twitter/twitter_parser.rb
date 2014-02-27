# coding: utf-8

require 'twitter'
require 'igo-ruby'


class TwitterParser

    TAGGER = Igo::Tagger.new('./parser/naistjdic')

    def initialize(access_token, access_token_secret)
        @client = Twitter::REST::Client.new do |config|
            config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
            config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
            config.access_token        = access_token
            config.access_token_secret = access_token_secret
        end
    end

    # 指定したユーザーと同じ興味を持つ知り合いを検索します
    # Param:: id ユーザー ID (文字列)
    # Param:: type 検索範囲の種類を決定
    #   :SEARCH_TYPE_FOLLOWS フォローから
    #   :SEARCH_TYPE_FOLLOWERS フォロワーから
    #   :SEARCH_TYPE_FRIENDS フォローかつフォロワーから
    #   :SEARCH_TYPE_FRIENDS フォローまたはフォロワーから
    # Return:: { "name" => ユーザー ID (文字列), "icon" => ユーザーアイコンの URL }
    #   を1ユーザーのデータとし、
    #   { "user" => id のユーザー, "bros" => {"topics"=>共通する興味の配列, "user"=>検索範囲内のユーザー} の配列 } を返す
    def find_bros(id, type = :SEARCH_TYPE_ACQUAINTANCE)
        # Twitter からデータを取得
        me = @client.user(id)
        case type
        when :SEARCH_TYPE_FRIENDS
            bros_ids = @client.friend_ids(id).collection & @client.follower_ids(id).collection
            bros = @client.users(bros_ids)
        when :SEARCH_TYPE_ACQUAINTANCE
            bros_ids = @client.friend_ids(id).collection | @client.follower_ids(id).collection
            bros = @client.users(bros_ids)
        when :SEARCH_TYPE_FOLLOWS
            bros = @client.users(@client.friend_ids(id).collection)
        when :SEARCH_TYPE_FOLLOWERS
            bros = @client.users(@client.follower_ids(id).collection)
        end

        # 興味が共通するユーザーの抽出
        me_interests = split_interests(me.description)
        bros_hashes = bros.map{|b|
            {
                "topics" => split_interests(b.description) & me_interests,
                "user" => twitter_user_to_biocon_hash(b)
            }
        }.select{|b| !b["topics"].empty?}

        # 返すハッシュ形式データの生成
        {"user" => twitter_user_to_biocon_hash(me), "bros" => bros_hashes }
    end

    private
    def split_interests(description)
        description = description || ""
        t = TAGGER.parse(description)
        t.select{|m| m.feature.split(',')[1] == "固有名詞" }.map{|m| m.surface}.uniq
    end

    def twitter_user_to_biocon_hash(user)
        {
            "name" => user.screen_name,
            "icon" => user.profile_image_url,
            "display_name" => user.name,
            "description" => user.description
        }
    end
end
