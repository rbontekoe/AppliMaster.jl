# myfunctions.jl

using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

# =================================
# task_1 - processing orders
# =================================
function task_master(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            start = take!(tx)
            @info("task_master received $(typeof(start))")
            if start == "START"
                @info("task_master will start the process remotely")
                orders = @fetch AppliSales.process()
                @info("task_master will put $(length(orders)) the orders on rx channel")
                put!(rx, orders)
                @info("task_master has putted $(length(orders)) the orders on rx channel")
            end
        else
            @info("task_master is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_0

# =================================
# task_1 - processing orders
# =================================
function task_invoicing_unpaid(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            orders = take!(tx)
            @info("task_invoicing_unpaid received $(typeof(orders))")
            if typeof(orders) == Array{AppliSales.Order, 1}
                @info("task_invoicing_unpaid will process $(length(orders)) orders remotely")
                result = @fetch AppliInvoicing.process(PATH_DB, orders)
                @info("task_invoicing_unpaid will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_invoicing_unpaid is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_1

# =================================
# task_2 - process journal entries
# =================================
function task_general_ledger(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            @info("task_general_ledger received $(typeof(entries))")
            if typeof(entries) == Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_general_ledger will process $(length(entries)) journal entries remotely")
                result = @fetch AppliGeneralLedger.process(PATH_DB_LEDGER, entries)
                @info("task_general_ledger saved $(length(result)) journal entries")
                #put!(tx, result)
            end
        else
            @info("task_general_ledger is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_2

# =================================
# task_3 - get paid journal entries
# =================================
function task_invoicing_paid(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            @info("task_invoicing_paid received $(typeof(stms))")
            if typeof(stms) == Array{AppliInvoicing.BankStatement,1}
                @info("task_invoicing_paid will match unpaid invoices with bank statements")
                result = @fetch begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                @info("task_invoicing_paid will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_invoicing_paid is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_3



# =================================
# task dispatcher
# =================================
function dispatcher()
    rx = Channel(32)

    tx0 = task_master(rx) # get the orders
    tx1 = task_invoicing_unpaid(rx) # process the orders
    tx2 = task_general_ledger(rx) # process the journal entries
    tx3 = task_invoicing_paid(rx) # process the unpaid invoices

    @async while true
        if isready(rx)
            value = take!(rx)
            @info("Dispatcher received $(typeof(value))")
            if typeof(value) == String && value =="START"
                put!(tx0, "START")
            elseif typeof(value) == Array{AppliSales.Order, 1}
                put!(tx1, value)
            elseif typeof(value) == Array{AppliGeneralLedger.JournalEntry,1}
                put!(tx2, value)
            elseif typeof(value) == Array{AppliInvoicing.BankStatement,1}
                put!(tx3, value)
            else
                @warn("No task found for type $(typeof(value))")
            end
        else
            wait(rx)
        end
    end
    return rx
end # dispatcher
