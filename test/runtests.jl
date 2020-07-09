# runtests.jl

using AppliMaster

using Test

using AppliAR, AppliSales, AppliGeneralLedger

using Query

using DataFrames

using Dates

@testset "Test AppliSales" begin
    orders = AppliSales.process()
    @test length(orders) == 3
    @test length(orders[1].students) == 1
    @test length(orders[2].students) == 2
    @test length(orders[3].students) == 1
    @test orders[1].training.price == 1000
end

@testset " Test AppliAR - unpaid invoices" begin
    orders = AppliSales.process()
    AppliAR.process(orders)
    unpaid_invoices = retrieve_unpaid_invoices()
    @test length(unpaid_invoices) == 3
    @test id(unpaid_invoices[1]) == "A1001"
    cmd = `rm test_invoicing.txt invoicenbr.txt`
    run(cmd)
end

@testset "Test AppliAR - entries unpaid invoices" begin
    orders = AppliSales.process()
    entries = AppliAR.process(orders)
    @test length(entries) == 3
    @test entries[1].from == 1300
    @test entries[1].to == 8000
    @test entries[1].debit == 1000
    @test entries[1].credit == 0
    @test entries[1].vat == 210.0
    cmd = `rm test_invoicing.txt invoicenbr.txt`
    run(cmd)
end

@testset "Test GeneralLedger - accounts receivable, bank, vat, sales" begin
    orders = AppliSales.process()

    journal_entries_unpaid_invoices = AppliAR.process(orders)
    AppliGeneralLedger.process(journal_entries_unpaid_invoices)

    unpaid_invoices = AppliAR.retrieve_unpaid_invoices()
    stm1 = BankStatement(Date(2020-01-15), "Duck City Chronicals Invoice A1002", "NL39INGB", 2420.0)
    stm2 = BankStatement(Date(2020-01-15), "Donalds Hardware Store Bill A1003", "NL39INGB", 1210.0)
    stms = [stm1, stm2]

    journal_entries_paid_invoices = AppliAR.process(unpaid_invoices, stms)
    AppliGeneralLedger.process(journal_entries_paid_invoices)

    df = DataFrame(AppliGeneralLedger.read_from_file("./test_ledger.txt"))

    df2 = df |> @filter(_.accountid == 1300) |> DataFrame
    @test sum(df2.debit - df2.credit) == 1210

    df2 = df |> @filter(_.accountid == 1150) |> DataFrame # bank
    @test sum(df2.debit - df2.credit) == 3630

    df2 = df |> @filter(_.accountid == 4000) |> DataFrame # vat
    @test sum(df2.credit - df2.debit) == 840

    df2 = df |> @filter(_.accountid == 8000) |> DataFrame # sales
    @test sum(df2.credit - df2.debit) == 4000

    @test sum(df.debit - df.credit) == 0.0

    cmd = `rm test_invoicing.txt test_journal.txt test_ledger.txt invoicenbr.txt`
    run(cmd)
end
