using Pages
using JSON

@async Pages.start()

Endpoint("/hello") do request::HTTP.Request
    data = String(request.body)
    println("Parameters: $(data)")
    "Hello stranger!"
end

r = HTTP.request("GET", "http://192.168.2.11:8000/hello?id=abc")

println(String(r.body))

result = ""
Endpoint("/test", POST) do request::HTTP.Request
    data = String(request.body)
    #println("Parameters: $(data)")
    global result = data
    response = JSON.json(Dict(:data => data))
end

r = HTTP.request("POST", "http://192.168.2.11:8000/test", [], "12345.pdf")

println(String(r.body))
