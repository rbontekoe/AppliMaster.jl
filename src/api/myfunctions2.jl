using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

# =================================
# task_1 - processing orders
# =================================
function task_1(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            orders = take!(tx)
            if typeof(orders) == Array{AppliSales.Order, 1}
                @info("task_1: Processing orders")
                result = @fetchfrom pid AppliInvoicing.process(PATH_DB, orders)
                put!(rx, result)
            end
        else
            wait(tx)
        end
    end
    return tx
end # test_1

# =================================
# task_2 - process journal entries
# =================================
function task_2(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            if typeof(entries) == Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_2: Processing Journal Entries")
                result = @fetchfrom pid AppliGeneralLedger.process(PATH_DB_LEDGER, entries)
                #put!(tx, result)
            end
        else
            wait(tx)
        end
    end
    return tx
end # test_2

# =================================
# task_2 - get paid journal entries
# =================================
function task_3(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            if typeof(stms) == Array{AppliInvoicing.BankStatement,1}
                @info("task_3: Processing unpaid invoices")
                result = @fetchfrom pid begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                put!(rx, result)
            end
        else
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

    tx1 = task_1(rx, p) # process orders
    tx2 = task_2(rx, q) # process journal entries
    tx3 = task_3(rx, r) # process unpaid invoices

    @async while true
        if isready(rx)
            value = take!(rx)
            @info("Type: $(typeof(value))")
            if typeof(value) == Array{AppliSales.Order, 1}
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
