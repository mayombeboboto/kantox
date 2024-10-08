defmodule KantoxTest do
  use ExUnit.Case
  doctest Kantox

  test "greets the world" do
    assert Kantox.hello() == :world
  end
end
