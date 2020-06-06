defmodule SseParserTest do
  import SseParser

  use ExUnit.Case

  doctest SseParser

  @tag unit: true
  test "parse partly incomplete stream" do
    assert {:ok, [], rest} = feed("event: put\ndata:")
    assert {:ok, [], rest} = feed(rest <> "the data part")
    assert {:ok, [], rest} = feed(rest <> "\n")
    assert {:ok, [attributes], rest} = feed(rest <> "\n")

    assert [
             {"event", "put"},
             {"data", "the data part"}
           ] == attributes
  end

  @tag unit: true
  test "parse multiple name onli streams" do
    assert {:ok, [e1, e2], rest} = feed("event1\n\nevent2\n\n")
    assert [{"event1", nil}] == e1
    assert [{"event2", nil}] == e2
  end

  @tag unit: true
  test "parse comment" do
    assert {:ok, [e1, e2], rest} = feed(":test\n\n:test2\n\n")
    assert ["test"] == e1
    assert ["test2"] == e2
  end

  @tag unit: true
  test "parse partial comment" do
    assert {:ok, [], rest} = feed(":te")
    assert {:ok, [e1], rest} = feed(rest <> "st\n\n")
    assert ["test"] == e1
  end
end
