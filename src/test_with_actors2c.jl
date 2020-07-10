# test_with_actors2.jl

# Basically the same as with test_local_channels.jl

using Pkg
Pkg.activate(".")
Pkg.precompile()

using Rocket
using DataFrames

# start docker containers
cmd = `docker start test_sshd`
run(cmd)

cmd = `docker start test_sshd2`
run(cmd)

cmd = `docker ps`
run(cmd)

sleep(5)

# enable distrbuted computing
using Distributed

#addprocs(4; exeflags=`--project=$(Base.active_project())`)
addprocs([("rob@172.17.0.2", 1), ("rob@172.17.0.3", 1)]; exeflags=`--project=$(Base.active_project())`, tunnel=true, dir="/home/rob")

#addprocs([("pi@192.168.2.3", 1)]; exename=`/home/pi/julia/julia-1.3.1/bin/julia`, dir="/home/pi")

# remove processes > 3
while length(procs()) ≥ 4
    rmprocs(procs()[length(procs())])
end

gl_pid = procs()[2] # general ledger
ar_pid = procs()[3] # accounts receivable (orders/bankstatements)

# activate the packages
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliAR
    using Query
end;

struct StmActor <: Actor{String}
    ar_pid::Int64
    StmActor(ar_pid::Int) = new(ar_pid)
end
Rocket.on_next!(actor::StmActor, data::String) = begin
    if data == "READ_STMS"
        stms = AppliAR.read_bank_statements("./bank.csv")
        unpaid_inv = @fetchfrom actor.ar_pid retrieve_unpaid_invoices()
        entries = @fetchfrom actor.ar_pid AppliAR.process(unpaid_inv, stms)
        subscribe!(from(entries), gl_actor)
    end
end
Rocket.on_complete!(actor::StmActor) = @info("StmActor completed!")
Rocket.on_error!(actor::StmActor, err) = @info(error(err))

struct SalesActor <: Actor{String} end
Rocket.on_next!(actor::SalesActor, data::String) = begin
    if data == "START"
        #ar_actor = ARActor()
        orders = @fetch AppliSales.process()
        subscribe!(from(orders), ar_actor)
    end
end
Rocket.on_complete!(actor::SalesActor) = @info("SalesActor completed!")
Rocket.on_error!(actor::SalesActor, err) = @info(error(err))

struct ARActor <: Actor{AppliSales.Order}
    values::Vector{AppliGeneralLedger.JournalEntry}
    ar_pid::Int64
    gl_pid::Int64
    ARActor(ar_pid, gl_pid) = new(Vector{AppliGeneralLedger.JournalEntry}(), ar_pid, gl_pid)
end
Rocket.on_next!(actor::ARActor, data::AppliSales.Order) = begin
        d = @fetchfrom actor.ar_pid AppliAR.process([data])
        push!(actor.values, d[1])
end
Rocket.on_complete!(actor::ARActor) = begin
    #println(actor.values)
    @info(typeof(actor.values))
    subscribe!(from(actor.values), gl_actor)
    @info("ARActor Completed!")
end
Rocket.on_error!(actor::ARActor, err) = @info(error(err))

struct GLActor <: Actor{Any}
    gl_pid::Int64
    GLActor(gl_pid) = new(gl_pid)
end
Rocket.on_next!(actor::GLActor, data::Any) = begin
    if data isa AppliGeneralLedger.JournalEntry
        result = @fetchfrom actor.gl_pid AppliGeneralLedger.process([data])
    end
end
Rocket.on_complete!(actor::GLActor) = @info("GLActor completed!")
Rocket.on_error!(actor::GLActor, err) = @info(error(err))

sales_actor = SalesActor()
ar_actor = ARActor(ar_pid, gl_pid)
gl_actor = GLActor(gl_pid)
stm_actor = StmActor(ar_pid)

subscribe!(from(["START"]), sales_actor)

subscribe!(from(["READ_STMS"]), stm_actor)

# print aging report
r1 = @fetchfrom ar_pid report()
result = DataFrame(r1)
println("\nUnpaid invoices\n===============")
show(result)

# print general ledger
r2 = @fetchfrom gl_pid AppliGeneralLedger.read_from_file("./test_ledger.txt")
df = DataFrame(r2)
println("\nGeneral Ledger mutations\n========================")
show(df)

df2 = r2 |> @filter(_.accountid == 1300) |> DataFrame
println("\nAccounts receivable\n===================")
show(df2)

println("\nBalance Accounts Receivable: $(sum(df2.debit) - sum(df2.credit))")

# open shell in container
cmd = `ssh rob@172.17.0.2`
@info("after run(cmd) is activated: goto console, press Enter, and rm test3_* files. Leave the container with Ctrl-D")
run(cmd)

# open shell in container
cmd = `ssh rob@172.17.0.3`
@info("after run(cmd) is activated: goto console, press Enter, and rm test3_invoicing.sqlite*. Leave the container with Ctrl-D")
run(cmd)
@info("Ctrl-L to clean the consule. Close julia with Ctrl-D.")

# end
