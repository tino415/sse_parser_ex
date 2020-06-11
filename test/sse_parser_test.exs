defmodule SseParserTest do
  alias SseParser.{Event, Stream}
  import SseParser

  use ExUnit.Case

  doctest SseParser

  describe "documentation cases" do
    test "sample feed interpret stream" do
      result =
        SseParser.feed_interpret_stream(
          "id: 1\nevent: put\ndata: test\n\nevent: patch\n",
          %Stream{}
        )

      expected = [
        %Event{
          id: "1",
          event: "put",
          data: "test"
        }
      ]

      assert {:ok, expected, "event: patch\n", %Stream{last_event_id: "1"}} == result
    end

    test "sample feed and interpret" do
      result = SseParser.feed_and_interpret("event: put\ndata: {\"name\": \"Testovic\"}\n\n")

      expected = [
        %Event{
          event: "put",
          data: "{\"name\": \"Testovic\"}"
        }
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
        %Event{
          event: "put",
          data: "{\"name\": \"Testovic\"}"
        }
      ]

      assert expected == result
    end

    test "sample streamify" do
      result =
        SseParser.streamify(%Stream{}, [%SseParser.Event{event: "put", id: "1", data: "test"}])

      expected = {
        [
          %SseParser.Event{
            event: "put",
            id: "1",
            data: "test"
          }
        ],
        %Stream{last_event_id: "1"}
      }

      assert result == expected
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
    assert "patch" == event1.event
    assert "d1\nd2" == event1.data
    assert "id" == event1.id
    assert 10 == event1.retry
    assert "second" == event2.event
  end

  test "streamify events" do
    events = [
      %Event{
        id: "test1",
        event: "put",
        data: "test 1"
      },
      %Event{
        event: "patch",
        retry: 1234
      },
      %Event{
        data: "jojoj"
      },
      %Event{
        id: "test2",
        event: "aaa",
        data: "less"
      },
      %Event{
        event: "+"
      }
    ]

    stream = %Stream{}

    {result_events, result_stream} = SseParser.streamify(stream, events)

    expected_events = [
      %Event{
        id: "test1",
        event: "put",
        data: "test 1",
        retry: nil
      },
      %Event{
        id: "test1",
        event: "patch",
        data: nil,
        retry: 1234
      },
      %Event{
        id: "test1",
        event: nil,
        data: "jojoj",
        retry: nil
      },
      %Event{
        id: "test2",
        event: "aaa",
        data: "less",
        retry: nil
      },
      %Event{
        id: "test2",
        event: "+",
        data: nil,
        retry: nil
      }
    ]

    assert expected_events == result_events
    assert %Stream{last_event_id: "test2", retry: 1234} == result_stream
  end

  test "feed_interpret_stream/2" do
    stream = %Stream{}
    feed = "id: 1\nevent: test\n\nretry: 3\n\nevent: put\ndata: test\n\n"

    expected_events = [
      %Event{
        id: "1",
        event: "test"
      },
      %Event{
        id: "1",
        retry: 3
      },
      %Event{
        id: "1",
        event: "put",
        data: "test"
      }
    ]

    assert {:ok, result_events, "", result_stream} = SseParser.feed_interpret_stream(feed, stream)
    assert expected_events == result_events
    assert %Stream{last_event_id: "1", retry: 3} == result_stream
  end
end
