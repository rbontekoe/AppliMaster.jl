# test_local_channels_pids.jl

@info("NOT FULLY TESTED YET!!!")

using Pkg
Pkg.activate(".")
Pkg.precompile()

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

# get tasks
include("./api/api3.jl")

# start dispatcher
rx = dispatcher(gl_pid, ar_pid)

# start application
put!(rx, "START")

# processing the uppaid invoices
stms = AppliAR.read_bank_statements(PATH_CSV)
sleep(15)
put!(rx, stms)
sleep(15)

# unkown type
test = "Test unkown type"
put!(rx, test)

# print aging report
using DataFrames
r1 = @fetchfrom ar_pid report(;path=PATH_DB)
result = DataFrame(r1)
println("\nUnpaid invoices\n===============")
show(result)

# print general ledger
r2 = @fetchfrom gl_pid AppliGeneralLedger.read_from_file(PATH_LEDGER)
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
