defmodule Kantox.MainTest do
  use ExUnit.Case

  alias Kantox.Main

  describe "add to cart" do
    test "add one product at a time to cart" do
      assert {:ok, _pid} = start_supervised(Main)
      assert 3.11 == Main.add_to_cart("GR1")
      assert 8.11 == Main.add_to_cart("SR1")
      assert 8.11 == Main.add_to_cart("GR1")
      assert 11.22 == Main.add_to_cart("GR1")

      assert %{
               "GR1" => %{qty: 3, total: 6.22},
               "SR1" => %{qty: 1, total: 5.0}
             } = Main.get_cart()

      stop_supervised(Main)
    end

    for {products, expected_price} <- [
          {["GR1", "SR1", "GR1", "GR1", "CF1"], 22.45},
          {["GR1", "GR1"], 3.11},
          {["SR1", "SR1", "GR1", "SR1"], 16.61},
          {["GR1", "CF1", "SR1", "CF1", "CF1"], 30.57}
        ] do
      test "add #{products} products to cart" do
        assert {:ok, _pid} = start_supervised(Main)

        assert unquote(expected_price) ==
                 Enum.reduce(unquote(products), 0, fn product, _acc ->
                   Main.add_to_cart(product)
                 end)

        stop_supervised(Main)
      end
    end
  end
end
