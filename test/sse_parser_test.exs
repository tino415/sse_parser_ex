defmodule SseParserTest do
  import SseParser

  use ExUnit.Case

  doctest SseParser

  describe "documentation cases" do
    test "sample feed and interpret" do
      result = SseParser.feed_and_interpret("event: put\ndata: {\"name\": \"Testovic\"}\n\n")

      expected = [
        [
          event: "put",
          data: "{\"name\": \"Testovic\"}"
        ]
      ]

      assert {:ok, expected, ""} == result
    end

    test "sample feed" do
      result = SseParser.feed(":Put event\nevent: put\ndata: {\"name\": \"Testovic\"}\n\n")

      expected = [
        [
          "Put event",
          {"event", "put"},
          {"data", "{\"name\": \"Testovic\"}"}
        ]
      ]

      assert {:ok, expected, ""} == result
    end

    test "sample interpret" do
      result =
        SseParser.interpret([
          ["Put event", {"event", "put"}, {"data", "{\"name\": \"Testovic\"}"}]
        ])

      expected = [
        [
          event: "put",
          data: "{\"name\": \"Testovic\"}"
        ]
      ]

      assert expected == result
    end
  end

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

  test "parse multiple name onli streams" do
    assert {:ok, [e1, e2], rest} = feed("event1\n\nevent2\n\n")
    assert [{"event1", nil}] == e1
    assert [{"event2", nil}] == e2
  end

  test "parse comment" do
    assert {:ok, [e1, e2], rest} = feed(":test\n\n:test2\n\n")
    assert ["test"] == e1
    assert ["test2"] == e2
  end

  test "parse partial comment" do
    assert {:ok, [], rest} = feed(":te")
    assert {:ok, [e1], rest} = feed(rest <> "st\n\n")
    assert ["test"] == e1
  end

  test "interpret event" do
    sample = [
      [
        "The comment",
        {"event", nil},
        {"event", "put"},
        {"event", "patch"},
        {"event", nil},
        {"data", nil},
        {"data", "d1"},
        {"data", "d2"},
        {"id", "id"},
        {"retry", "10"},
        {"retry", "ignored"},
        {"something", "value"}
      ],
      [
        {"event", "second"}
      ]
    ]

    assert [event1, event2] = SseParser.interpret(sample)
    assert 4 == length(event1)
    assert 1 == length(event2)
    assert ["patch"] == Keyword.get_values(event1, :event)
    assert ["d1\nd2"] == Keyword.get_values(event1, :data)
    assert ["id"] == Keyword.get_values(event1, :id)
    assert [10] == Keyword.get_values(event1, :retry)
    assert ["second"] == Keyword.get_values(event2, :event)
  end
end
