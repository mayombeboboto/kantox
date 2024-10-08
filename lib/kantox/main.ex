defmodule Kantox.Main do
  use GenServer

  require Integer

  @allowed_products ["GR1", "SR1", "CF1"]

  @type item :: %{
          type: String.t(),
          qty: non_neg_integer(),
          price: float(),
          total: float()
        }

  @type products :: %{
          optional(String.t()) => item()
        }

  # --- APIs ----
  @spec start_link(any()) :: {:ok, pid()}
  def start_link(_params) do
    GenServer.start_link(
      __MODULE__,
      nil,
      name: __MODULE__
    )
  end

  @spec add_to_cart(binary()) :: pos_integer()
  def add_to_cart(product)
      when is_binary(product) and
             product in @allowed_products do
    GenServer.call(__MODULE__, {:add_to_cart, product})
  end

  @spec get_cart() :: products()
  def get_cart(), do: GenServer.call(__MODULE__, :get_cart)

  # ---- Callbacks ----
  @impl true
  def init(_args) do
    {
      :ok,
      %{
        "GR1" => %{type: "GR1", qty: 0, price: 3.11, total: 0},
        "SR1" => %{type: "SR1", qty: 0, price: 5.0, total: 0},
        "CF1" => %{type: "CF1", qty: 0, price: 11.23, total: 0}
      }
    }
  end

  @impl true
  def handle_call({:add_to_cart, name}, _from, products) do
    product =
      products
      |> Map.fetch!(name)
      |> update_product()

    new_products = %{products | name => product}
    total_cost = get_total_cost(new_products)

    {:reply, total_cost, new_products}
  end

  def handle_call(:get_cart, _from, products) do
    {:reply, products, products}
  end

  # ---- Internal Functions ----
  def update_product(%{qty: qty} = product) do
    product
    |> Map.put(:qty, qty + 1)
    |> update_product(:ceo_discount, is_discount_active?(:ceo_discount))
    |> update_product(:coo_discount, is_discount_active?(:coo_discount))
    |> update_product(:cto_discount, true)
  end

  def update_product(
        %{type: "GR1", qty: qty, price: price} = product,
        :ceo_discount,
        true
      ) do
    total =
      cond do
        qty > 1 and Integer.is_even(qty) -> trunc(qty / 2) * price
        qty > 1 -> trunc(qty / 2) * price + price
        true -> price
      end

    %{product | total: total}
  end

  def update_product(
        %{type: "SR1", qty: qty} = product,
        :coo_discount,
        true
      ) do
    total =
      unless qty >= 3 do
        product.total + product.price
      else
        4.50 * qty
      end

    %{product | total: total}
  end

  def update_product(
        %{type: "CF1", qty: qty, price: price} = product,
        :cto_discount,
        true
      ) do
    total =
      if qty >= 3 do
        price / 3 * 2 * qty
      else
        qty * price
      end

    %{product | total: total}
  end

  def update_product(product, _, _) do
    product
  end

  # This addresses the flexibility part in a way.
  # Through config files, we can decide which update_product
  # to deactivate.
  def is_discount_active?(_type), do: true

  def get_total_cost(products) do
    products
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(& &1.total)
    |> Enum.sum()
    |> Float.round(2)
  end
end
