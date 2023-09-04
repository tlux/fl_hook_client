defmodule FLHook.FieldErrorTest do
  use ExUnit.Case, async: true

  alias FLHook.FieldError

  describe "message/1" do
    test "get error message" do
      assert Exception.message(%FieldError{
               key: "foo"
             }) == "invalid or missing field (foo)"
    end
  end
end
