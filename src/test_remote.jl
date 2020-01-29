# test2.jl

using Distributed

# this shoiuld be the next step
addprocs(4)
p = 3 # invoicing
q = 4 # general ledger

# then define the packages
@everywhere using Dates
@everywhere using AppliSales
@everywhere using AppliGeneralLedger
@everywhere using AppliInvoicing

# the functions
@everywhere function test(channel, value)
    println(value)
    while true
        if isready(channel)
            s = take!(channel)
            try
                println(s)
            catch e
                println("Hm... $e")
            end
        else
            wait(channel)
        end
    end
end

@everywhere function updatetable(channel, file, table)
    #println(Threads.threadid())
    println(table)
    db = connect(file)
    while true
        if isready(channel)
            s = take!(channel)
            try
                gg = gather(db, table, "key == '$(s.id)'") # find s
                if isempty(gg) # not found
                    create(db, table, [s])
                else
                    update(db, table, [s]) # found
                end
            catch
                # first time when table has not been created
                create(db, table, [s])
            end
        else
            wait(channel)
        end
    end
end

# init
#c1 = RemoteChannel(() -> Channel(32))

#remote_do(test, p, c1, "Hello")

#daisy = createSubscriber("Daisy")

#put!(c1, daisy)

#db = connect("rbo.sqlite")

#remote_do(updatetable, q, c1, "./rbo.sqlite", "subscribers")

#put!(c1, daisy)

#r = gather(connect("./rbo.sqlite"), "subscribers")
#println(r)

orders = AppliSales.process()

const PATH_DB = "./invoicing.sqlite"

const PATH_CSV = "./bank.csv"

result = @spawnat p begin
           AppliInvoicing.process(PATH_DB, orders)
end

journal_entries_1 = fetch(result)

# get Bank statemnets and unpaid invoices
stms = AppliInvoicing.read_bank_statements(PATH_CSV)

unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)

result = @spawnat p begin
           AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
end

journal_entries_2 = fetch(result)

# =============================

const PATH_DB_LEDGER = "./ledger.sqlite"

result = @spawnat p begin
           AppliGeneralLedger.process(PATH_DB_LEDGER, journal_entries_1)
end

fetch(result)

result = @spawnat p begin
           AppliGeneralLedger.process(PATH_DB_LEDGER, journal_entries_2)
end

fetch(result)

# =============================


using AppliSQLite

db2 = connect(PATH_DB_LEDGER)

r = retrieve(db2, "LEDGER")

println(r)

# get status of accouts receivable
r = retrieve(db2, "LEDGER", "accountid = 1300")

account_receivable = sum(r.debit - r.credit)
@info("Balance of accounts receivable is $(account_receivable). Should be 1200")

println("Status accounts receivable: € $account_receivable") # should be € 1210.0

# get status of sales
r = retrieve(db2, "LEDGER", "accountid = 8000")

sales = sum(r.credit - r.debit) # should return € 4000.0
@info("Sales is $(sales). Should be 4000.")

println("Sales: € $sales")

# cleanup
stm = `rm invoicing.sqlite ledger.sqlite`

run(stm)
