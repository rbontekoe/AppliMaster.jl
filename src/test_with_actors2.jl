# test_with_actors2.jl

# Basically the same as with test_local_channels.jl

using Pkg; Pkg.activate(".")

using Rocket, AppliSales, AppliAR, AppliGeneralLedger, CSV, Query

struct StmActor <: Actor{String} end
Rocket.on_next!(actor::StmActor, data::String) = begin
    if data == "READ_STMS"
        stms = AppliAR.read_bank_statements("./bank.csv")
        unpaid_inv = retrieve_unpaid_invoices()
        entries = AppliAR.process(unpaid_inv, stms)
        #println(entries)
        subscribe!(from(entries), gl_actor)
    end
end
Rocket.on_complete!(actor::StmActor) = println("StmActor completed!")
Rocket.on_error!(actor::StmActor, err) = error(err)

struct SalesActor <: Actor{String} end
Rocket.on_next!(actor::SalesActor, data::String) = begin
    if data == "START"
        #ar_actor = ARActor()
        orders = AppliSales.process()
        subscribe!(from(orders), ar_actor)
    end
end
Rocket.on_complete!(actor::SalesActor) = println("SalesActor completed!")
Rocket.on_error!(actor::SalesActor, err) = error(err)

struct ARActor <: Actor{AppliSales.Order}
    values::Vector{AppliGeneralLedger.JournalEntry}
    ARActor() = new(Vector{AppliGeneralLedger.JournalEntry}())
end
Rocket.on_next!(actor::ARActor, data::AppliSales.Order) = begin
        d = AppliAR.process([data])
        push!(actor.values, d[1])
end
Rocket.on_complete!(actor::ARActor) = begin
    #println(actor.values)
    println(typeof(actor.values))
    subscribe!(from(actor.values), gl_actor)
    println("ARActor Completed!")
end
Rocket.on_error!(actor::ARActor, err) = error(err)

struct GLActor <: Actor{Any} end
Rocket.on_next!(actor::GLActor, data::Any) = begin
    if data isa AppliGeneralLedger.JournalEntry
        AppliGeneralLedger.process([data])
    end
end
Rocket.on_complete!(actor::GLActor) = println("GLActor completed!")
Rocket.on_error!(actor::GLActor, err) = error(err)

sales_actor = SalesActor()
ar_actor = ARActor()
gl_actor = GLActor()
stm_actor = StmActor()

subscribe!(from(["START"]), sales_actor)

subscribe!(from(["READ_STMS"]), stm_actor)

r = AppliAR.retrieve_unpaid_invoices()[1]
println(r)

println("")
include("check_general_ledger.jl")

r2 = AppliGeneralLedger.read_from_file("./test_ledger.txt")
df = DataFrame(r2)
println("\nGeneral Ledger mutations\n========================")
show(df)

df2 = r2 |> @filter(_.accountid == 1300) |> DataFrame
println("\nAccounts receivable\n===================")
show(df2)

# end
