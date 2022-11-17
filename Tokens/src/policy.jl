module Policy

using Base: @kwdef

import ..Serializable

abstract type AbstractPolicy <: Serializable end

@kwdef mutable struct TokenPolicy <: AbstractPolicy
    secrets_path::String
    issuer::String
    scope::Vector{String}
    extra_request_args::Dict{Symbol, String}
end

@kwdef mutable struct ExecutionPolicy <: AbstractPolicy
    pidfile_timeout::Int64 = 60
    collect_global_logger::Bool = false
    set_global_logger::Bool = false
    logger::Function
end

export AbstractPolicy, TokenPolicy, ExecutionPolicy

end