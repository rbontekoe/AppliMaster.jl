# runtests.jl

using Test

using AppliInvoicing, AppliSales, AppliGeneralLedger

using DataFrames

using Query

const PATH_CSV = "./bank.csv"

@testset "Test AppliSales" begin
    orders = AppliSales.process()
    @test length(orders) == 3
    @test length(orders[1].students) == 1
    @test length(orders[2].students) == 2
    @test length(orders[3].students) == 1
    @test orders[1].training.price == 1000
end

@testset " Test AppliInvoicing - unpaid invoices" begin
    #db = connect("./invoicing.sqlite")
    orders = AppliSales.process()
    AppliInvoicing.process(orders)
    unpaid_invoices = retrieve_unpaid_invoices()
    @test length(unpaid_invoices) == 3
    @test id(unpaid_invoices[1]) == "A1001"
    cmd = `rm test_invoicing.sqlite`
    run(cmd)
end

@testset "Test AppliInvoicing - paid invoices" begin
    #db = connect("./invoicing.sqlite")
    orders = AppliSales.process()
    entries = AppliInvoicing.process(orders)
    @test length(entries) == 3
    @test entries[1].from == 1300
    @test entries[1].to == 8000
    @test entries[1].debit == 1000
    @test entries[1].credit == 0
    @test entries[1].vat == 210.0
    cmd = `rm test_invoicing.sqlite`
    run(cmd)
end

@testset "Test GeneralLedger - accounts receivable, bank, vat, sales" begin

    orders = AppliSales.process()

    journal_entries_unpaid_invoices = AppliInvoicing.process(orders)
    AppliGeneralLedger.process(journal_entries_unpaid_invoices)

    unpaid_invoices = AppliInvoicing.retrieve_unpaid_invoices()

    stms = AppliInvoicing.read_bank_statements("./bank.csv")

    journal_entries_paid_invoices = AppliInvoicing.process(unpaid_invoices, stms)

    AppliGeneralLedger.process(journal_entries_paid_invoices)

    df = DataFrame(AppliGeneralLedger.read_from_file("test_ledger.txt"))

    df2 = df |> @filter(_.accountid == 1300) |> DataFrame
    @test sum(df2.debit - df2.credit) == 1210

    df2 = df |> @filter(_.accountid == 1150) |> DataFrame # bank
    @test sum(df2.debit - df2.credit) == 3630

    df2 = df |> @filter(_.accountid == 4000) |> DataFrame # vat
    @test sum(df2.credit - df2.debit) == 840

    df2 = df |> @filter(_.accountid == 8000) |> DataFrame # sales
    @test sum(df2.credit - df2.debit) == 4000

    @test sum(df.debit - df.credit) == 0.0

    cmd = `rm test_invoicing.sqlite test_journal.txt test_ledger.txt`
    run(cmd)
end
