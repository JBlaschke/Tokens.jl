module Secret

using ..Policy: TokenPolicy
import ..Serializable

abstract type AbstractSecret <: Serializable end

end