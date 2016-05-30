// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "deps/phoenix/web/static/js/phoenix"

let socket = new Socket("/socket")

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.

socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("sync", {})
channel.join()
  .receive("ok", resp => {
    console.log("Joined succesffuly", resp);
    $('#log').empty();
  })
  .receive("error", resp => { console.log("Unabled to join", resp) })

channel.on("update", function(data) {
  $('#log').append("<div>" + data.log + "</div>");
  $('#log').scrollTop($('#log')[0].scrollHeight);
});

channel.on("balance_update", function(data) {
  var formatBalance = function(balance) {
    return "$" + (balance / 100).toFixed(2).replace(/(\d)(?=(\d{3})+\.)/, '$1,');
  };

  var account = $('#' + data.account_id + " .balance");
  if (account.length == 0) {
    var row = "<tr class='account' id='" + data.account_id + "'>" +
      "<td class='name'>" + data.name + "</td>" +
      "<td class='balance' data-balance='" + data.balance + "'>" +
      formatBalance(data.balance) + "</td>" +
      "</tr>"
    if (data.type == 0) {
      $('.assets .total').before(row);
    } else {
      $('.liabilities .total').before(row);
    }
    account = $('#' + data.account_id + " .balance");
  }
  account.html(formatBalance(data.balance));
  account.data('balance', data.balance);

  var total = 0;
  var accountTable = account.parent().parent();
  accountTable.find('.account .balance').
    each(function(i, n) { total += parseInt($(n).data('balance')); });
  accountTable.find('.total .balance').html("<b>" + formatBalance(total) + "</b");
});

$("#sync").click(function() {
  channel.push("sync_all", {});
});

export default socket
