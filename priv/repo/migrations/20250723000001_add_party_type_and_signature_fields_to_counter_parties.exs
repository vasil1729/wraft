defmodule WraftDoc.Repo.Migrations.AddPartyTypeAndSignatureFieldsToCounterParties do
  use Ecto.Migration

  def change do
    # Add new fields to counter_parties table
    alter table(:counter_parties) do
      add(:party_type, :string, comment: "Type of party: external, vendor, current_org")
      add(:sign_order, :integer, comment: "Order in which this counterparty should sign")
    end

    create(index(:counter_parties, [:party_type]))
    create(index(:counter_parties, [:sign_order]))
  end
end
