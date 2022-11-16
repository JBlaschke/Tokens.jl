module Auth

using Base: @kwdef

using HTTP
using JSON
using TimeZones
using Dates

include("util.jl")
import .Util: filter, map


function check_response(response)
    if response.status != 200
        error("Server did not respond with 200!")
    end

    date = response.headers |> filter(h->"Date" in h) |> map(h->h[2])

    if isempty(date)
        error("Server did not include date in response in headers!")
    end

    if length(date) > 1
        error("Server responsed with multiple 'Date' headers!")
    end

    date = String(date[1])
    body = JSON.parse(String(response.body), dicttype=Dict{Symbol,Any})

    return date, body
end


function boostrap_token!()
    s = load_secret()

    url = HTTP.URI(
        scheme = "https",
        host = "oauth2.googleapis.com",
        path = "/token",
        query = Dict(
            "grant_type"    => "authorization_code",
            "access_type"   => "offline",
            "client_id"     => s.client_id,
            "client_secret" => s.client_secret,
            "code"          => s.code,
            "redirect_uri"  => s.redirect_uri
        )
    )

    response = HTTP.request(
        :POST, string(url), [
            "Content-Type" => "application/x-www-form-urlencoded"
        ],
    )

    date, body = check_response(response)
    t = OAuthToken(; body ...)

    update_token!(t, date)
end


function update_token!(token, date)
    if isfile(joinpath("secrets", "oauth2_token.lock"))
        error("Lock Exists!")
    end

    open(joinpath("secrets", "oauth2_token.lock"), "w") do io
        println(io, "locked")
    end

    open(joinpath("secrets", "oauth2_token.json"), "w") do io
        JSON.print(io, Dict(:token=>token, :date=>date), 4)
    end

    rm(joinpath("secrets", "oauth2_token.lock"))
end


function load_token()
    response = open(joinpath("secrets", "oauth2_token.json")) do io
        JSON.parse(io, dicttype=Dict{Symbol,Any})
    end
    return response[:date], OAuthToken(;response[:token] ...)
end


function is_valid(date, token)
    zdt = ZonedDateTime(date, "e, d u y H:M:S Z")
    return zdt + Second(token.expires_in) > now(localzone())
end


function refresh!()
    d, last = load_token()
    if is_valid(d, last)
        return false, last
    end

    s = load_secret()

    url = HTTP.URI(
        scheme = "https",
        host = "oauth2.googleapis.com",
        path = "/token",
        query = Dict(
            "grant_type"    => "refresh_token",
            "client_id"     => s.client_id,
            "client_secret" => s.client_secret,
            "refresh_token" => last.refresh_token
        )
    )

    response = HTTP.request(
        :POST, string(url), [
            "Content-Type" => "application/x-www-form-urlencoded"
        ],
    )

    date, new_token = check_response(response)
    new_token[:refresh_token] = last.refresh_token
    t = OAuthToken(;new_token ... )

    update_token!(t, date)

    return true, t
end


function get!()
    refreshed, auth = refresh!()
    return auth.access_token
end


end