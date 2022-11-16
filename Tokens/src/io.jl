module IO

using JSON

import ..Serializable

function save(p::T, path::String) where {T <: Serializable}
    open(path, "w") do io
        JSON.print(io, p, 4)
    end
end

function load(path::String, constructor::DataType)
    return constructor(;
        open(path, "r") do io
            JSON.parse(io, dicttype=Dict{Symbol, Any})
        end ...
    )
end

export save, load

end