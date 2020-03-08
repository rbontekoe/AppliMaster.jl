# myfunctions.jl

using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_JOURNAL = "journal.txt"
const PATH_LEDGER = "ledger.txt"

# =================================
# task_0 - get orders from Sales
# =================================
function task_0(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            start = take!(tx)
            @info("task_0 (master): $(typeof(start))")
            if start == "START"
                @info("task_0 (master) will start the process")
                orders = @fetch AppliSales.process()
                @info("task_0 (master) will put $(length(orders)) the orders on rx channel")
                put!(rx, orders)
                @info("task_0 (master) has putted $(length(orders)) the orders on rx channel")
            end
        else
            @info("task_0 (master) is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task_0

# =================================
# task_1 - process the orders
# =================================
function task_1(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            orders = take!(tx)
            @info("task 1 (process the orders): $(typeof(orders))")
            if typeof(orders) == Array{AppliSales.Order, 1}
                @info("task_1 (process the orders) will process $(length(orders)) orders remotely")
                result = @fetch AppliInvoicing.process(PATH_DB, orders)
                @info("task_1 (process the orders) will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_1 (process the orders) is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task_1

# =================================
# task_2 - process journal entries
# =================================
function task_2(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            @info("task_2 (process journal entries): $(typeof(entries))")
            if typeof(entries) == Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_2 (process journal entries) will process $(length(entries)) journal entries remotely")
                result = @fetch AppliGeneralLedger.process(PATH_JOURNAL, PATH_LEDGER, entries)
                #@info("task_general_ledger saved $(length(result)) journal entries")
                @info("task_2 (process journal entries) saved the journal entries")
                #put!(tx, result)
            end
        else
            @info("task_2 (process journal entries) is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task2_2

# =================================
# task_3 - process payments
# =================================
function task_3(rx)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            @info("task_3 (process payments): $(typeof(stms))")
            if typeof(stms) == Array{AppliInvoicing.BankStatement,1}
                @info("task_3 (process payments) will match unpaid invoices with bank statements")
                result = @fetch begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                @info("task_3 (process payments) will put $(length(result)) journal entries on rx channel")
                put!(rx, result)
            end
        else
            @info("task_3 (process payments) is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task_3



# =================================
# task dispatcher
# =================================
function dispatcher()
    rx = Channel(32)

    # instantiate tasks
    tx0 = task_0(rx) # get orders from Sales
    tx1 = task_1(rx) # process the orders
    tx2 = task_2(rx) # process the journal entries
    tx3 = task_3(rx) # process the unpaid invoices

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
