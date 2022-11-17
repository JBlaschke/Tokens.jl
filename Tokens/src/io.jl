module IO

using JSON

import ..Serializable

function save(p::Serializable, path::String)
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