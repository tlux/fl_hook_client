defmodule FLHook.Duration do
  @moduledoc """
  A struct that represents a duration.
  """

  @behaviour FLHook.ParamType

  defstruct days: 0, hours: 0, minutes: 0, seconds: 0

  @type t :: %__MODULE__{
          days: non_neg_integer,
          hours: non_neg_integer,
          minutes: non_neg_integer,
          seconds: non_neg_integer
        }

  @impl true
  def parse(value) when is_binary(value) do
    with [days, hours, minutes, seconds] <- String.split(value, ":", parts: 4),
         {days, ""} when days >= 0 <- Integer.parse(days),
         {hours, ""} when hours in 0..23 <- Integer.parse(hours),
         {minutes, ""} when minutes in 0..59 <- Integer.parse(minutes),
         {seconds, ""} when seconds in 0..59 <- Integer.parse(seconds) do
      {:ok,
       %__MODULE__{
         days: days,
         hours: hours,
         minutes: minutes,
         seconds: seconds
       }}
    else
      _ -> :error
    end
  end

  def parse(_), do: :error
end
