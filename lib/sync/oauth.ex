defmodule Ledger.Sync.Oauth do
  def hmac_sha1_auth_string(url, consumer, token) do
    nonce = :base64.encode_to_string(:crypto.rand_bytes(32))
    timestamp = :os.system_time(:seconds)

    params = [
      {"oauth_consumer_key", consumer[:key]},
      {"oauth_nonce", nonce},
      {"oauth_timestamp", timestamp |> to_string},
      {"oauth_token", token[:key]},
      {"oauth_signature_method", "HMAC-SHA1"},
      {"oauth_version", "1.0"}
    ]

    consumer_secret = :base64.encode(consumer[:secret])
    token_secret = :base64.encode(token[:secret])
    sha_key = consumer_secret <> "&" <> token_secret

    sha_concat = fn (p, string) ->
      string <> :base64.encode(elem(p, 0)) <> "=" <> :base64.encode(elem(p, 1)) <> "&"
    end
    sha_text = "GET&" <>:base64.encode(url) <> "&"
    sha_text = params |> Enum.reduce(sha_text, sha_concat)

    sha1 = :crypto.hmac(:sha, sha_key, sha_text)
    signature = :base64.encode_to_string(sha1)

    string_concat = fn (p, string) ->
      string <> elem(p, 0) <> "=" <> (elem(p, 1) |> to_string) <> ", "
    end
    auth_string = "OAuth "
    auth_string = params |> Enum.reduce(auth_string, string_concat)
    auth_string = auth_string <> "oauth_signature=#{signature}"

    auth_string
  end
end
