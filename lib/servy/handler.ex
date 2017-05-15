defmodule Servy.Handler do
    def handle(request) do
        request
        |> parse
        |> rewrite_path
        |> log
        |> route
        |> track
        |> format_response
    end

    # Parse raw request into a map
    def parse(request) do
        # Parse the request string into the map
        [ method, path, _] =
            request
            |> String.split("\n")
            |> List.first
            |> String.split(" ")

        %{ method: method, path: path, resp_body: "", status: nil}
    end

    # Generic logger
    def log(conv), do: IO.inspect conv

    #
    # Path Rewrites
    #
    def rewrite_path(%{ path: "/wildlife" } = conv) do
        %{ conv | path: "/wildthings" }
    end

    # catch all, rewrite not needed
    def rewrite_path(conv), do: conv

    #
    # Routes
    #

    # wildthings
    def route(%{ method: "GET", path: "/wildthings" } = conv) do
        %{ conv | status: 200, resp_body: "Bears, Lions, Tigers"}
    end
    # bears
    def route(%{ method: "GET", path: "/bears" } = conv) do
        %{ conv | status: 200, resp_body: "Teddy, Smokey, Paddington"}
    end
    def route(%{ method: "GET", path: "/bears/" <> id } = conv) do
        %{ conv | status: 200, resp_body: "Bear #{ id }" }
    end
    def route(%{ method: "DELETE", path: "/bears/" <> _id } = conv) do
        %{ conv | status: 403, resp_body: "Deleting a bear is forbidden!" }
    end
    # catch all route
    def route(%{ path: path } = conv) do
        %{ conv | status: 404, resp_body: "No #{ path } here!"}
    end

    # Track: Log error routes
    def track(%{ status: 404, path: path } = conv) do
        IO.puts "Warning #{ path } is on the loose!"
        conv
    end
    # catch all, tracking not needed
    def track(conv), do: conv

    # Format HTTP Resposne
    def format_response(conv) do
        # Use the values in the map to create an HTTP response string:
        """
        HTTP/1.1 #{ conv.status } #{ status_reason conv.status }
        Content-Type: text/html
        Content-Length: #{ byte_size(conv.resp_body) }

        #{ conv.resp_body }
        """
    end
    # helper function to map status codes to their message
    defp status_reason(code) do
        %{
            200 => "OK",
            201 => "Created",
            204 => "No Content",
            401 => "Unauthorized",
            403 => "Forbidden",
            404 => "Not Found",
            500 => "Internal Server Error"
        }[code]
    end
end

#
# Test Runs
#

# Sample req 1
request = """
GET /wildthings HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response

# Sample req 2
request = """
GET /bears HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response

# Sample req 3
request = """
GET /bigfoot HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response

# Sample req 4
request = """
GET /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response

# Sample req 5
request = """
DELETE /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response

# Sample req 6
request = """
GET /wildlife HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

response = Servy.Handler.handle request

IO.puts response