# client.jl - remote client communicate through a socket

using Sockets
using Serialization
using AppliGeneralLedger, AppliInvoicing

io = connect("192.168.2.11", 8000)

# start application
serialize(io, "START")

# send bankstatemnet
stms = AppliInvoicing.read_bank_statements("./bank.csv")
serialize(io, stms)
