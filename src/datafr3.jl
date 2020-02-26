# =====

# See also: https://discourse.julialang.org/t/save-and-restore-dataframe-and-serialize-deserialize/9699/9

#=
julia> row = 4
julia> a = a[setdiff(1:end, row), :]
=#

using Serialization

using DataFrames

function read_from_file(file::String)
    io = open(file, "r")

    r = []
    while !eof(io)
        push!(r, deserialize(io))
    end

    close(io)

    return r
end

function add_to_file(file::String, data::Array{T, 1} where T <: Any)
    io = open(file, "a+")

    [serialize(io, r) for r in data]

    close(io)
end

struct Person
    name::String
end

# =====

rob = Person("Rob")

wil = Person("Wil")

persons = [rob, wil]

add_to_file("test.txt", persons)

marleen = Person("Marleen")

add_to_file("test.txt", [marleen])

r = read_from_file("test.txt")

cmd = `rm test.txt`

run(cmd)
