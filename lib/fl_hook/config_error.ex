defmodule FLHook.ConfigError do
  @moduledoc """
  An error that indicates that configuration of the client is invalid.
  """

  @enforce_keys [:message]
  defexception [:message]
end
