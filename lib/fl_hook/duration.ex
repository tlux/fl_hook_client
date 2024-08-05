defmodule FLHook.Duration do
  @moduledoc """
  A struct that represents a duration.
  """

  @behaviour FLHook.Coercible

  @impl FLHook.Coercible
  def parse(value) when is_binary(value) do
    with [day, hour, minute, second] <- String.split(value, ":", parts: 4),
         {day, ""} when day >= 0 <- Integer.parse(day),
         {hour, ""} when hour in 0..23 <- Integer.parse(hour),
         {minute, ""} when minute in 0..59 <- Integer.parse(minute),
         {second, ""} when second in 0..59 <- Integer.parse(second) do
      {
        :ok,
        Duration.new!(
          day: day,
          hour: hour,
          minute: minute,
          second: second
        )
      }
    else
      _ -> :error
    end
  end

  def parse(_), do: :error
end
