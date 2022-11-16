module Util

using JSON
using Chain
using Dates

# Allow filter and map piping:
# https://discourse.julialang.org/t/function-chaining-with-and-filter-function/17060/4
import Base: filter, map
filter(f::Function)::Function = x -> filter(f, x)
map(f::Function)::Function    = x -> map(f, x)

export filter, map

now_epoch() = @chain begin
    now()
    datetime2unix(_)
end

now_epoch_int() = @chain begin
    now_epoch()
    floor(Int64, _)
end

end