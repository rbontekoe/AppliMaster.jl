using Distributed

np = addprocs(4; exeflags=`--project=$(Base.active_project())`)

@everywhere begin
    using AppliSales
    using AppliGeneralLedger
    using AppliInvoicing
end

@everywhere include("./src/api/myfunctions.jl");


@everywhere function test(a)
    io = open("test2.txt", "a+")
    serialize(io, a)
    close(io)
end
