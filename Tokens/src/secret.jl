module Secret

using Pidfile
using JSON

using ..Policy: TokenPolicy, ExecutionPolicy
using ..IO: save, load
import ..Serializable

abstract type AbstractSecret <: Serializable end

function claim_token!(
        name::AbstractString, constructor::DataType,
        token_policy::TokenPolicy, execution_policy::ExecutionPolicy
    )
    lock = Pidfile.mkpidlock(
        joinpath(token_policy.secrets_path, name) * ".pid";
        stale_age = execution_policy.pidfile_timeout
    )

    response = open(joinpath(token_policy.secrets_path, name) * ".json") do io
        JSON.parse(io, dicttype=Dict{Symbol,Any})
    end

    return lock, response[:date], constructor(;response[:token] ...)
end

function update_token!(
        token::Serializable, date::AbstractString, name::AbstractString,
        lock::Pidfile.LockMonitor, token_policy::TokenPolicy
    )
    open(joinpath(token_policy.secrets_path, name) * ".json", "w") do io
        JSON.print(io, Dict(:token=>token, :date=>date))
    end

    close(lock)
end

end