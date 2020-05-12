# test_remote_channels_pids.jl

@info("NOT TESTED YET!!!")

using Pkg
Pkg.activate(".")

# remove old stuff
cmd = `rm test2_invoicing.sqlite test2_ledger.txt test2_journal.txt`
run(cmd)

# start docker containers
cmd = `docker start test_sshd`
run(cmd)

cmd = `docker start test_sshd2`
run(cmd)

cmd = `docker ps`
run(cmd)

# enable distrbuted computing
using Distributed

addprocs(4; exeflags=`--project=$(Base.active_project())`)
#addprocs([("rob@172.17.0.2", 1), ("rob@172.17.0.3", 1)]; exeflags=`--project=$(Base.active_project())`)
#addprocs([("rob@192.168.2.77:2222", :auto)]; exeflags=`--project=$(Base.active_project())`)

p = 2 # accounts receivable (orders/bankstatements)
q = 3 # general ledger

# activate the packages
@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliAR
end;

# get tasks
include("./api/myfunctions_pids.jl")

# start dispatcher
rx = dispatcher()

# start application
put!(rx, "START")

# processing the uppaid invoices
stms = AppliAR.read_bank_statements(PATH_CSV)
put!(rx, stms)

# unkown type
test = "Test unkown type"
put!(rx, test)
