defmodule FLHook.CodecErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.CodecError

  describe "message/1" do
    test "get decode error message" do
      assert Exception.message(%CodecError{
               direction: :decode,
               codec: :unicode,
               value: "invalid",
               reason: "Something went wrong"
             }) == "Unable to decode value in :unicode mode"
    end

    test "get encode error message" do
      assert Exception.message(%CodecError{
               direction: :encode,
               codec: :unicode,
               value: "invalid",
               reason: "Something went wrong"
             }) == "Unable to encode value in :unicode mode"
    end
  end
end
