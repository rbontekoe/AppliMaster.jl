# TEST jld2.jl

using JLD2, AppliSales, FileIO

struct Person
    name::String
end

struct Test
    id::String
    person::Person
end

rob = Person("Rob")

wil = Person("Wil")

marleen = Person("Marleen")

persons = [rob, wil, marleen]

@save "persons.jld2" persons

persons = nothing

@load "persons.jld2" persons

println(persons)

daisy = Person("Daisy")

donald = Person("Donald")

persons = union(persons, [daisy, donald])

println(persons)

@save "persons.jld2" persons

persons = nothing

println(persons)

@load "persons.jld2" persons

println(persons)

persons = nothing

f = jldopen("persons.jld2", "r")

f["persons"]

close(f)

goofy = Person("Goofy")

@load "persons.jld2" persons

persons = append!(persons, [goofy])

@save "persons.jld2" persons

@load "persons.jld2" persons

println(persons)
