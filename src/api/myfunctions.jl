# myfunctions.jl

using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

# =================================
# task_1 - processing orders
# =================================
function task_1(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            orders = take!(tx)
            @info("task_1 received $(typeof(orders))")
            if typeof(orders) == Array{AppliSales.Order, 1}
                @info("task_1 will process $(length(orders)) orders remote")
                result = @fetch AppliInvoicing.process(PATH_DB, orders)
                @info("task_1 will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_1 will wait for data")
            wait(tx)
        end
    end
    return tx
end # test_1

# =================================
# task_2 - process journal entries
# =================================
function task_2(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            @info("task_2 received $(typeof(entries))")
            if typeof(entries) == Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_2 will process $(length(entries)) journal entries remote")
                result = @fetch AppliGeneralLedger.process(PATH_DB_LEDGER, entries)
                @info("task_2 saved $(length(result)) journal entries")
                #put!(tx, result)
            end
        else
            @info("task_2 will wait for data")
            wait(tx)
        end
    end
    return tx
end # test_2

# =================================
# task_3 - get paid journal entries
# =================================
function task_3(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            @info("task_3 received $(typeof(stms))")
            if typeof(stms) == Array{AppliInvoicing.BankStatement,1}
                @info("task_3 will match unpaid invoices with bank statements")
                result = @fetch begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                @info("task_3 will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_3 will wait for data")
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

    tx1 = task_1(rx) # process orders
    tx2 = task_2(rx) # process journal entries
    tx3 = task_3(rx) # process unpaid invoices

    @async while true
        if isready(rx)
            value = take!(rx)
            @info("Dispatcher received $(typeof(value))")
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
