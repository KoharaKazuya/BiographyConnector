$(function(){
    var selector = "#twitter_result_canvas";
    var juz = JuzJS(selector);
    var canvas = $(selector);

    var opened_nodes = {};

    function get_node(data, parentNode) {
        var name = data.name;
        if ( name in opened_nodes ) {
            // 生成済みのノードを取得
            return opened_nodes[name];
        } else {
            // 新規にノードを生成
            var new_node = juz.createNode({
                click: function(node) {
                    display_info(node);
                },
                dblclick: function(node) {
                    node.setIcon("/img/loading.png");
                    open_node(data.name);
                }
            });
            new_node.json_data = data;
            opened_nodes[name] = new_node;
            // 新規ノードの位置およびアイコン設定
            if ( parentNode ) {
                new_node.setX(parentNode.getX());
                new_node.setY(parentNode.getY());
            } else {
                new_node.setX(canvas.attr("width") / 2);
                new_node.setY(canvas.attr("height") / 2);
            }
            new_node.setIcon(data.icon);
            return new_node;
        }
    }

    // 指定したユーザーをさらに解析して関連ユーザーを表示する
    function open_node(id) {
        // Ajax で　JSON 形式で取得
        $.getJSON("/result/twitter.json", { twitter_id: id }, function(res) {
            if ( too_many_request_check(res) ) {
                var data = res.data;
                var parentNode = get_node(data.user);
                for (var i=0; i<data.bros.length; ++i) {
                    var new_node = get_node(data.bros[i].user, parentNode);
                    parentNode.connect(new_node, 1, data.bros[i].topics.join(" + "));
                }
                // 読込中アイコンを元に戻す
                parentNode.setIcon(data.user.icon);
            }
        });
    }

    // ユーザーの情報を表示
    function display_info(node) {
        var info = $("#twitter_result_account_info");
        var data = node.json_data;
        info.find(".account_icon").attr("src", data.icon);
        info.find(".account_url").text(data.display_name);
        info.find(".account_url").attr("href", "https://twitter.com/" + data.name);
        info.find(".account_description").text(data.description);
    }

    // リクエストが多すぎるエラーのチェック
    function too_many_request_check(res) {
        if ( res.type === "success" ) {
            return true;
        } else if ( res.type === "error" ) {
            alert("Twitter に対して一度に多くのリクエストを送信し過ぎました。しばらくお待ち下さい(" + res.time + ")");
            return false;
        }
    }

    // ルートノード（フォームに入力したユーザー）を表示
    open_node(canvas.attr("data-root"));
});
