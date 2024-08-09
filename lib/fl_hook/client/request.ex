defmodule FLHook.Client.Request do
  @moduledoc false

  @id_length 8

  @type id :: String.t()

  @spec random_id() :: id
  def random_id do
    @id_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, @id_length)
  end
end
