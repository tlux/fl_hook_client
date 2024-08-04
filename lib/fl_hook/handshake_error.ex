defmodule FLHook.HandshakeError do
  @moduledoc """
  An error that indicates that the socket connection is not a valid FLHook
  socket or the encoding is wrong.
  """

  defexception [:actual_message]

  @type t :: %__MODULE__{actual_message: term}

  def message(_error) do
    "Socket is not a valid FLHook socket"
  end
end
