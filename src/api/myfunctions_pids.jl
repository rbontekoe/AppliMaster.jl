# myfunctions_pids.jl

using Distributed

const PATH_DB = "./invoicing.sqlite"
const PATH_CSV = "./bank.csv"
const PATH_DB_LEDGER = "./ledger.sqlite"

# =================================
# task_0 - processing orders
# =================================
function task_0(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            start = take!(tx)
            @info("task_0 received $(typeof(start))")
            if start == "START"
                @info("task_0 will start the process remotely")
                orders = @fetchfrom pid AppliSales.process()
                @info("task_0 will put $(length(orders)) the orders on rx channel")
                put!(rx, orders)
            end
        else
            @info("task_0 is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_0


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
                @info("Task 1 will put $(length(result)) orders on rx channel")
                put!(rx, result)
            end
        else
            @info("task_1 is waiting for data")
            wait(tx)
        end
    end
    return tx
end # test_1

# =================================
# task_2 - process journal entries
# =================================
ledger = "./ledger.txt"
journal = "./journal.txt"

function task_2(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            if typeof(entries) == Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_2: Processing journal entries")
                result = @fetchfrom pid AppliGeneralLedger.process(journal, ledger, entries)
                #put!(tx, result)
            end
        else
            @info("task_2 is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task_2(rx, pid)

# =================================
# task_3 - get paid journal entries
# =================================
function task_3(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            if typeof(stms) == Array{AppliInvoicing.BankStatement,1}
                @info("Task_3: Processing unpaid invoices")
                result = @fetchfrom pid begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    @info("Retrieved $(length(unpaid_invoices)) unpaid invoices")
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                put!(rx, result)
            end
        else
            @info("task_3 is waiting for data")
            wait(tx)
        end
    end
    return tx
end # task_3(rx, pid)


# =================================
# task dispatcher
# =================================
function dispatcher()
    rx = Channel(32)

    #=
    tx1 = task_1(rx, p) # process orders
    tx2 = task_2(rx, q) # process journal entries
    tx3 = task_3(rx, p) # process unpaid invoices
    =#

    tx0 = task_0(rx, p) # get the orders
    tx1 = task_1(rx, q) # process the orders
    tx2 = task_2(rx, p) # process the journal entries
    tx3 = task_3(rx, q) # process the unpaid invoices

    #=
    @async while true
        if isready(rx)
            value = Take!(rx)
            @info("type: $(typeof(value))")
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
=#

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
