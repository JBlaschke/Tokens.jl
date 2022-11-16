module OAuth

using Base: @kwdef
using HTTP
using Mux
using OpenIDConnect
using JWTs
using JSON
using Dates

using ..Secret: AbstractSecret
using ..Policy: TokenPolicy
using ..Util: now_epoch
import ..AbstractToken

@kwdef mutable struct OAuthSecret <: AbstractSecret
    client_id::String
    redirect_uri::String
    scope::String
    client_secret::String
    code::String
end

@kwdef mutable struct OAuthToken <: AbstractToken
    access_token::String
    expires_in::Int64
    refresh_token::String
    scope::String
    token_type::String
end

headers(req::Dict{<:Any, <:Any}) = req[:headers]

query(req::Dict{<:Any, <:Any}) = parse_query(req[:query])

function parse_query(qstr::AbstractString)
    res = Dict{String, String}()
    for qsub in split(qstr, "&")
        nv = split(qsub, "=")
        res[nv[1]] = length(nv) > 1 ? nv[2] : ""
    end
    return res
end

function generate_query(params::Dict{<:Any,<:Any})
    qstr = ""
    for x in params
        qstr = qstr * "&$(first(x))=$(last(x))"
    end
    return qstr
end

function pretty(j::Dict{<:Any, <:Any})
    iob = IOBuffer()
    JSON.print(iob, j, 4)
    return String(take!(iob))
end

function login(oidcctx::OIDCCtx)
    url = flow_request_authorization_code(oidcctx) * generate_query(
        Dict(
            "access_type" => "offline",
            "promp" => "consent")
    )

    return """
    <html>
    <head>
        <meta http-equiv="Refresh" content="0; url=$(string(url))" />
    </head>
    <body>
        <p>Please follow <a href="$(string(url))">this link</a>.</p>
    </body>
    </html>
    """
end

function show_token(oidcctx::OIDCCtx, authresp, authenticated)
    id_token = authresp["id_token"]
    jwt = JWT(;jwt=id_token)
    isvalid = flow_validate_id_token(oidcctx, string(jwt))

    token_claims = claims(jwt)

    jbox_auth = Dict(
        "Authorization" => ("Bearer " * id_token)
    )

    authenticated[] = true
    can_refresh = "refresh_token" in keys(authresp)
    refresh_link = can_refresh ? """<hr/><a href="/auth/refresh?refresh_token=$(authresp["refresh_token"])">Refresh</a>""" : ""

    return """
    <html>
    <body>
        OpenID Authentication:
        <pre>$(pretty(authresp))</pre><hr/>
        JWT Token:
        <pre>$(pretty(token_claims))</pre><hr/>
        Authentication Bearer Token:
        <pre>$(pretty(jbox_auth))</pre><hr/>
        Validation success: $isvalid 
        $(refresh_link)
    </body>
    </html>"""
end

function token(oidcctx::OIDCCtx, req, authenticated)
    resp = query(req)

    code = flow_get_authorization_code(oidcctx, resp)
    code = HTTP.URIs.unescapeuri(code)

    authresp = flow_get_token(oidcctx, code)
    @show authresp

    show_token(oidcctx, authresp, authenticated)
end

function refresh(oidcctx::OIDCCtx, req, authenticated)
    resp = query(req)
    refresh_token = resp["refresh_token"]
    authresp = flow_refresh_token(oidcctx, refresh_token)
    show_token(oidcctx, authresp, authenticated)
end

function start_server()
    config = open("settings.json") do f
            JSON.parse(f)
        end

    oidcctx = OIDCCtx(
        String(config["issuer"]),
        "http://127.0.0.1:8888/auth/login",
        String(config["client_id"]),
        String(config["client_secret"]),
        ["openid", "email"]
    )

    authenticated = Ref(false)

    @app test = (
        Mux.defaults,
        page("/", req->login(oidcctx)),
        page("/auth/login", req->token(oidcctx, req, authenticated)),
        page("/auth/refresh", req->refresh(oidcctx, req, authenticated)),
        Mux.notfound()
    )

    @info("Standalone OIDC test server starting on port 8888")
    return serve(test, 8888)

    # while config["do_refresh"] || !(authenticated[])
    #     sleep(10)
    # end
    # sleep(10)
end

end