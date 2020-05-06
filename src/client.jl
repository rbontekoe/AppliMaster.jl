# client.jl - remote client communicate through a socket

using Sockets
using Serialization

io = connect("192.168.2.11", 8000)

# start application
serialize(io, "START")

# send bankstatemnet after a while
using AppliGeneralLedger, AppliAR
sleep(30)
stms = AppliAR.read_bank_statements("./bank.csv")
serialize(io, stms)
