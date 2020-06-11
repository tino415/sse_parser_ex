defmodule SseParser.Stream do
  @moduledoc """
  Hold structure to represent single event
  """

  @moduledoc since: "3.1.0"

  use TypedStruct
  use TsAccess

  typedstruct do
    field :last_event_id, String.t()
    field :retry, integer()
  end
end
