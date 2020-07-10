# test_with_actors2.jl

# Basically the same as with test_local_channels.jl

using Pkg; Pkg.activate(".")

@info("remove old stuff")
cmd = `rm test_invoicing.txt test_invoicing_paid.txt test_ledger.txt test_journal.txt invoicenbr.txt`
run(cmd)

using Rocket, AppliSales, AppliAR, AppliGeneralLedger, CSV, Query, DataFrames

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



r2 = AppliGeneralLedger.read_from_file("./test_ledger.txt")
df = DataFrame(r2)
println("\nGeneral Ledger mutations\n========================")
show(df)

r = DataFrame(report())
println("\nUnpaid invoices\n$("="^15)")
println(r)

df2 = r2 |> @filter(_.accountid == 1300) |> DataFrame
balance_1300 = sum(df2.debit - df2.credit)

df2 = df |> @filter(_.accountid == 8000) |> DataFrame
balance_8000 = sum(df2.credit - df2.debit)

df2 = df |> @filter(_.accountid == 1150) |> DataFrame
balance_1150 = sum(df2.debit - df2.credit)

df2 = df |> @filter(_.accountid == 4000) |> DataFrame
balance_4000 = sum(df2.credit - df2.debit)

println("")
println("Balance Accounts Receivable is $balance_1300. Should be 1210..")
println("Sales is $balance_8000. Should be 4000.0.")
println("Balance bank is $balance_1150. Should be 3630.0.")
println("Balance VAT is $balance_4000. Shouldbe 840.0.")

# end
