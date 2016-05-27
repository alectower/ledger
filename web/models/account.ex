defmodule Ledger.Account do
  use Ledger.Web, :model

  schema "accounts" do
    field :name, :string
    field :balance, :integer
    field :type, :integer

    timestamps
  end

  @required_fields ~w(name)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:name, name: "accounts_name_type_index")
  end
end
