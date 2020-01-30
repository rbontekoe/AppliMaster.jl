TIME = 1

# =================================
# test_idea
# ===============================
function test_idea1(channel, pid)
    while true
        if isready(channel)
            t = fetch(channel)
            println("test_idea1", " - ",  typeof(t))
            if typeof(t) == Array{AppliSales.Order, 1}
                println("test_idea1", " PROCESSING")
                orders = take!(channel)
                result = @fetchfrom pid AppliInvoicing.process(PATH_DB, orders)
                put!(channel, result)
            end
            sleep(TIME + 0.3)
        else
            wait(channel)
        end
    end
end # test_idea

# =================================
# test_idea2
# ===============================
function test_idea2(channel, pid)
    while true
        if isready(channel)
            t = fetch(channel)
            println("test_idea2", " - ", typeof(t))
            println( typeof(t) == Array{AppliGeneralLedger.JournalEntry,1} )
            if typeof(t) == Array{AppliGeneralLedger.JournalEntry,1}
                println("test_idea2", " PROCESSING")
                entries = take!(channel)
                result = @fetchfrom pid AppliGeneralLedger.process(PATH_DB_LEDGER, entries)
                #put!(channel, result)
            end
            sleep(TIME + 0.2)
        else
            wait(channel)
        end
    end
end # test_idea

# =================================
# test_idea3
# ===============================
function test_idea3(channel, pid)
    while true
        if isready(channel)
            t = fetch(channel)
            println("test_idea3", " - ", typeof(t))
            if typeof(t) == Array{AppliInvoicing.BankStatement,1}
                println("test_idea3", " PROCESSING")
                stms = take!(channel)
                result = @fetchfrom pid begin
                    unpaid_invoices = retrieve_unpaid_invoices(PATH_DB)
                    AppliInvoicing.process(PATH_DB, unpaid_invoices, stms)
                end
                put!(channel, result)
            else
                sleep(TIME + 0.1)
            end
        else
            wait(channel)
        end
    end
end # test_idea3
