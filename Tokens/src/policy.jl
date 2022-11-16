module Policy

using Base: @kwdef

import ..Serializable

abstract type AbstractPolicy <: Serializable end

@kwdef mutable struct TokenPolicy <: AbstractPolicy
    scheme::String
    secrets_path::String
    host::String
    bootstrap_path::String
    refresh_path::String
end

@kwdef mutable struct ExecutionPolicy <: AbstractPolicy
    timeout::Int64 = 60
end

export AbstractPolicy, TokenPolicy, ExecutionPolicy

end