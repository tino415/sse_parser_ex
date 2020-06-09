# SseParser

Module to parse server sent event as spicified in 
[SSE standard](https://www.w3.org/TR/2009/WD-eventsource-20090421/#parsing-an-event-stream)

Full documentation can be found at [https://hexdocs.pm/sse_parser](https://hexdocs.pm/sse_parser).

## Installation

The package can be installed
by adding `sse_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:sse_parser, "~> 3.0.0"}
  ]
end
```

## Usage

Simplest way to use this librari is using `SseParser.feed_and_interpret/1` interface. You pass
chunk from `SSE` source and it will return parsed and reduced events

```elixir
iex> SseParser.feed_and_interpret("event: put\ndata: {\"name\": \"Testovic\"}\n\n")
{:ok, [
  %SseParser.Event{
    event: "put",
    data: "{\"name\": \"Testovic\"}"
  }
], ""}
```

It is also posible to use this interface partiali, because interpret 
step could remove a lot of information

```elixir
iex> SseParser.feed(":Put event\nevent: put\ndata: {\"name\": \"Testovic\"}\n\n")
{:ok, [
  "Put event", 
  {"event", "put"}, 
  {"data", "{\"name\": \"Testovic\"}"}
], ""}
```

```elixir
iex> SseParser.interpret([["Put event", {"event", "put"}, {"data", "{\"name\": \"Testovic\"}"}]])
[
  %SseParser.Event{
    event: "put",
    data: "{\"name\": \"Testovic\"}"
  }
]
```

