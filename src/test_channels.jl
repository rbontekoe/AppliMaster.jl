# test_remote_channels.jl

# Still PROBLEMS with running processes remote. I created myfunctions2 and removed @fetch

# activate the packages (before the processes are created)
using AppliSales
using AppliGeneralLedger
using AppliInvoicing
#@everywhere using SQLite

# get tasks and dispatcher
include("./api/myfunctions2.jl");
@info("Loaded ./api/myfunctions2.jl")

@info("running test_remote_channel.jl")

# start dispatcher
rx = dispatcher()
@info("Dispatcher started")

#runcode(channel) = begin
# start the application
@info("The Master will start the process and asks for test orders from the AppliSales module")
put!(rx, "START")

# processing the uppaid invoices
#@info("Master will read file with 2 bank statements")
stms = AppliInvoicing.read_bank_statements(PATH_CSV)
@info("Master got $(length(stms)) bank statements")
@info("Master will put $(length(stms)) bank statements on rx channel")
put!(rx, stms)

#unkown type
test = "Test unkown type"
put!(rx, test)
#end

#runcode(rx);

#stm = `rm invoicing.sqlite ledger.sqlite log_master.txt`
stm = `rm invoicing.sqlite ledger.sqlite`
run(stm)
