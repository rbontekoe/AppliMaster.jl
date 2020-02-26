# test jld2

using DataFrames
using Serialization

struct Person
    id::String
    name::String
end

struct Test
    id::String
    person::Person
end

rob = Person("rbo", "Rob")

wil = Person("wfa", "Wil")

test1 = Test("test1", rob)

test2 = Test("test2", wil)

df1 = DataFrame([test1])

df2 = DataFrame([test2])

# =========

open(file -> serialize(file, df1), "my_data.jld2", "w")

r2 = deserialize(open("my_data.jld2"))

df_test = append!(df1, df2)

open(file -> serialize(file, df_test), "my_data.jld2", "w")

r3 = deserialize(open("my_data.jld2"))

using AppliSales

orders = AppliSales.process()

open(file -> serialize(file, orders), "my_orders.jld2", "w")

r4 = deserialize(open("my_orders.jld2"))
