using JSON

using Tokens


config = open(ARGS[1]) do f
    JSON.parse(f)
end


policy = Tokens.IO.load(ARGS[1], Tokens.Policy.TokenPolicy)

println(policy)

g_id, g_secret = Tokens.Google.load_secret(ARGS[2])

secret = Tokens.OAuth.OAuthSecret(
    client_id = g_id,
    client_secret = g_secret,
    redirect_uri = "http://127.0.0.1:8888/auth/login",
    scope = policy.scope,
    code = ""
)

println(secret)