using Pkg; Pkg.activate(".")

using Rocket, AppliSales, AppliAR, AppliGeneralLedger

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
Rocket.on_complete!(actor::ARActor) = println("ARActor Completed!")
Rocket.on_error!(actor::ARActor, err) = error(err)

sales_actor = SalesActor()
ar_actor = ARActor()
subscribe!(from(["START"]), sales_actor)

r = AppliAR.retrieve_unpaid_invoices()[1]
println(r)

# end
