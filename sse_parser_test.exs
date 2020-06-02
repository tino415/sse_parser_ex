defmodule SseParserTest do
  import SseParser

  use ExUnit.Case
  use ExUnitProperties

  doctest SseParser

  @tag unit: true
  test "parse partly incomplete stream" do
    assert {:ok, [], rest} = feed("event: put\ndata:")
    assert {:ok, [], rest} = feed(rest <> "the data part")
    assert {:ok, [], rest} = feed(rest <> "\n")
    assert {:ok, [attributes], rest} = feed(rest <> "\n")

    assert {
             :event,
             [
               field: [name: "event", value: "put"],
               field: [name: "data", value: "the data part"]
             ]
           } == attributes
  end

  @tag unit: true
  test "parse multiple name onli streams" do
    assert {:ok, [event: e1, event: e2], rest} = feed("event1\n\nevent2\n\n")
    assert [field: [name: "event1"]] == e1
    assert [field: [name: "event2"]] == e2
  end

  @tag unit: true
  test "parse comment" do
    assert {:ok, [event: e1, event: e2], rest} = feed(":test\n\n:test2\n\n")
    assert [comment: "test"] == e1
    assert [comment: "test2"] == e2
  end

  @tag unit: true
  test "parse partial comment" do
    assert {:ok, [], rest} = feed(":te")
    assert {:ok, [event: e1], rest} = feed(rest <> "st\n\n")
    assert [comment: "test"] == e1
  end
end
