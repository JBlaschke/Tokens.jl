using PrettyPrint

include("./auth.jl")
using .Auth


refreshed, token = Auth.refresh!()
pprintln(token)

println("")

if refreshed
    println("The access token was refreshed")
else
    println("The access token remains valid")
end