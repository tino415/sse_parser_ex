defmodule SseParser.Event do
  @moduledoc """
  Hold structure to represent single event
  """

  @moduledoc since: "2.0.0"

  use TypedStruct
  use TsAccess

  typedstruct do
    field :id, String.t()
    field :event, String.t()
    field :data, String.t()
    field :retry, integer()
  end
end
