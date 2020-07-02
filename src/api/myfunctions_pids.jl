# myfunctions_pids.jl

using Distributed

const PATH_DB = "./test3_invoicing.txt"
const PATH_DB_PAID = "./test3_invoicing_paid.txt"
const PATH_CSV = "./bank.csv"
const PATH_JOURNAL = "./test3_journal.txt"
const PATH_LEDGER = "./test3_ledger.txt"

# =================================
# task_0 - get orders from Sales
# =================================
function task_0(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            start = take!(tx)
            @info("task_0 (master): $(typeof(start)) - $start - $(start == "START")")
            if start == "START"
                @info("task_0 (master) will start the process")
                orders = @fetchfrom pid AppliSales.process()
                @info("task_0 (master) will put $(length(orders)) the orders on rx channel")
                put!(rx, orders)
                @info("task_0 (master) has put $(length(orders)) the orders on rx channel")
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
function task_1(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            orders = take!(tx)
            @info("task 1 (process the orders): $(typeof(orders))")
            if orders isa Array{AppliSales.Order, 1}
                @info("task_1 (process the orders) will process $(length(orders)) orders remotely")
                result = @fetchfrom pid AppliAR.process(orders; path=PATH_DB)
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
function task_2(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            entries = take!(tx)
            @info("task_2 (process journal entries): $(typeof(entries))")
            if entries isa Array{AppliGeneralLedger.JournalEntry,1}
                @info("task_2 (process journal entries) will process $(length(entries)) journal entries remotely")
                result = @fetchfrom pid AppliGeneralLedger.process(entries; path_journal=PATH_JOURNAL, path_ledger=PATH_LEDGER)
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
function task_3(rx, pid)
    tx = Channel(32)
    @async while true
        if isready(tx)
            stms = take!(tx)
            @info("task_3 (process payments): $(typeof(stms))")
            if stms isa Array{AppliAR.BankStatement,1}
                @info("task_3 (process payments) will match unpaid invoices with bank statements")
                result = @fetchfrom pid begin
                    unpaid_invoices = retrieve_unpaid_invoices(; path=PATH_DB)
                    try
                        AppliAR.process(unpaid_invoices, stms; path=PATH_DB_PAID)
                    catch e
                        @info(e)
                    end
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
function dispatcher(p, q)
    rx = Channel(32)

    # instantiate tasks
    tx0 = task_0(rx, p) # get the orders
    tx1 = task_1(rx, q) # process the orders
    tx2 = task_2(rx, p) # process the journal entries
    tx3 = task_3(rx, q) # process the unpaid invoices

    # definition Holy traits pattern Dispatcher in domain.jl
    dispatch(x::T) where {T} = dispatch(Dispatcher(T), x)

    dispatch(::T0, x) = put!(tx0, x)
    dispatch(::T1, x) = put!(tx1, x)
    dispatch(::T2, x) = put!(tx2, x)
    dispatch(::T3, x) = put!(tx3, x)
    # dispatch(::T4, x) = put!(tx0, x)

    @async while true
        if isready(rx)
            value = take!(rx)
            @info("Dispatcher received $(typeof(value))")
            dispatch(value)
        else
            wait(rx)
        end
    end
    return rx
end # dispatcher
