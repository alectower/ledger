require IEx
defmodule Ledger.PageView do
  use Ledger.Web, :view

  def display_balance(%Ledger.Account{} = model), do: display_balance(model.balance)
  def display_balance(num) do
    case is_integer(num) do
      true ->
        [dollars, cents] = num / 100
                           |> to_string
                           |> String.split(".")
        dollars = dollars
                  |> to_char_list
                  |> Enum.reverse
                  |> Enum.chunk(3, 3, [])
                  |> Enum.join(",")
                  |> String.reverse

        {cents, _} = cents |> Integer.parse
        if cents < 10 do
          cents = cents * 10
        end

        "$#{dollars}.#{cents}"
      false -> "N/A"
    end
  end
end
