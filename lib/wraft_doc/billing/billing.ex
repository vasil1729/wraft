defmodule WraftDoc.Billing do
  @moduledoc """
  The billing module for wraft subscription management.
  """
  import Ecto.Query

  alias __MODULE__.PaddleApi
  alias __MODULE__.Subscription
  alias __MODULE__.SubscriptionHistory
  alias __MODULE__.Transaction
  alias Ecto.Multi
  alias WraftDoc.Account.User
  alias WraftDoc.Enterprise
  alias WraftDoc.Enterprise.Plan
  alias WraftDoc.Repo

  @doc """
  Get a subscription of a user's current organisation.
  """
  @spec get_subscription(%User{}) :: {:ok, Subscription.t()} | nil
  def get_subscription(%User{current_org_id: current_org_id}) do
    Subscription
    |> Repo.get_by(organisation_id: current_org_id)
    |> Repo.preload([:subscriber, :organisation, :plan])
    |> case do
      %Subscription{} = subscription -> {:ok, subscription}
      _ -> nil
    end
  end

  @doc """
  Get a subscription from its UUID.
  """
  @spec get_subscription_by_id(Ecto.UUID.t()) ::
          Subscription.t() | {:error, :invalid_id, String.t()}
  def get_subscription_by_id(<<_::288>> = subscription_id) do
    case Repo.get(Subscription, subscription_id) do
      %Subscription{} = subscription -> subscription
      _ -> {:error, :invalid_id, "Subscription"}
    end
  end

  def get_subscription_by_id(_), do: {:error, :invalid_id, "Subscription"}

  defp get_subscription_by_provider_subscription_id(provider_subscription_id) do
    Subscription
    |> Repo.get_by(provider_subscription_id: provider_subscription_id)
    |> Repo.preload([:subscriber, :organisation, :plan])
  end

  @doc """
  Get active subscription of a user's organisation.
  """
  @spec active_subscription_for(Ecto.UUID.t()) ::
          {:ok, Subscription.t()} | {:error, atom()}
  def active_subscription_for(<<_::288>> = organisation_id) do
    organisation_id
    |> active_subscription_query()
    |> Repo.one()
    |> Repo.preload([:subscriber, :organisation, :plan])
    |> case do
      %Subscription{} = subscription ->
        {:ok, subscription}

      _ ->
        {:error, :no_active_subscription}
    end
  end

  def active_subscription_for(_), do: {:error, :invalid_id, "Organisation"}

  @doc """
  Returns true  user has active subscription.
  """
  @spec has_active_subscription?(Ecto.UUID.t()) :: boolean()
  def has_active_subscription?(organisation_id) do
    organisation_id |> active_subscription_query() |> Repo.exists?()
  end

  defp active_subscription_query(organisation_id) do
    from(s in Subscription,
      where: s.organisation_id == ^organisation_id and s.status == ^"active",
      order_by: [desc: s.inserted_at],
      limit: 1
    )
  end

  @doc """
  Returns true user has a valid subscription.
  """
  @spec has_valid_subscription?(Ecto.UUID.t()) :: boolean()
  def has_valid_subscription?(organisation_id) do
    organisation_id |> valid_subscription_query() |> Repo.exists?()
  end

  defp valid_subscription_query(organisation_id) do
    from(s in Subscription,
      where: s.organisation_id == ^organisation_id,
      order_by: [desc: s.inserted_at],
      limit: 1
    )
  end

  @doc """
  Update subscription when plan changed.
  """
  @spec change_plan(Subscription.t(), User.t(), Plan.t()) :: {:ok, map()} | {:error, String.t()}

  def change_plan(
        %Subscription{plan: %{type: :free}},
        _,
        _
      ),
      do: {:error, "Can't change plan for free plan, create new subscription"}

  def change_plan(
        %Subscription{provider_plan_id: provider_plan_id},
        _,
        %{plan_id: plan_id}
      )
      when plan_id == provider_plan_id,
      do: {:error, "Already have same plan."}

  def change_plan(
        %Subscription{
          provider_subscription_id: provider_subscription_id
        },
        current_user,
        plan
      ) do
    provider_subscription_id
    |> PaddleApi.update_subscription(current_user, plan)
    |> case do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Gets preview of a plan changes.
  """
  @spec change_plan_preview(Subscription.t(), Plan.t()) :: {:ok, map()} | {:error, String.t()}
  def change_plan_preview(%Subscription{plan: %{type: :free}}, _),
    do: {:error, "Change plan preview not available for free plan."}

  def change_plan_preview(%Subscription{provider_plan_id: provider_plan_id}, %{plan_id: plan_id})
      when provider_plan_id == plan_id,
      do: {:error, "Already have same plan."}

  def change_plan_preview(
        %Subscription{provider_subscription_id: provider_subscription_id},
        plan
      ) do
    provider_subscription_id
    |> PaddleApi.update_subscription_preview(plan)
    |> case do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Cancel subscription.
  """
  @spec cancel_subscription(Subscription.t()) :: {:ok, map()} | {:error, String.t()}

  def cancel_subscription(%Subscription{plan: %{type: :free}}),
    do: {:error, "Free subscription cannot be cancelled"}

  def cancel_subscription(%Subscription{provider_subscription_id: provider_subscription_id}) do
    provider_subscription_id
    |> PaddleApi.cancel_subscription()
    |> case do
      {:ok, response} ->
        {:ok, response}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Activate trailing subscription.
  """
  @spec activate_trial_subscription(Subscription.t()) ::
          {:ok, Subscription.t()} | {:error, String.t()}
  def activate_trial_subscription(%Subscription{
        status: "trialing",
        provider_subscription_id: provider_subscription_id
      }) do
    provider_subscription_id
    |> PaddleApi.activate_trailing_subscription()
    |> case do
      {:ok, response} ->
        params = format_subscription_params(response)

        provider_subscription_id
        |> get_subscription_by_provider_subscription_id()
        |> Subscription.update_changeset(params)
        |> Repo.update()

      {:error, error} ->
        {:error, error}
    end
  end

  def activate_trial_subscription(%Subscription{status: status}),
    do: {:error, "Current status: #{status}, Only trailing subscription need be activated"}

  @doc """
  Retrieves subscription history of an organisation.
  """
  @spec subscription_index(Ecto.UUID.t(), map()) :: Scrivener.Page.t() | nil
  def subscription_index(<<_::288>> = organisation_id, params) do
    query =
      from(sh in SubscriptionHistory,
        where: sh.organisation_id == ^organisation_id,
        preload: [:subscriber, :organisation, :plan]
      )

    Repo.paginate(query, params)
  end

  def subscription_index(_organisation_id, _params), do: nil

  @doc """
  Retrieves transactions of an organisation.
  """
  @spec get_transactions(Ecto.UUID.t(), map()) :: Scrivener.Page.t() | nil
  def get_transactions(<<_::288>> = organisation_id, params) do
    query =
      from(t in Transaction,
        where: t.organisation_id == ^organisation_id,
        preload: [:organisation, :subscriber, :plan]
      )

    Repo.paginate(query, params)
  end

  def get_transactions(_organisation_id, _params), do: nil

  @doc """
  Create subscription.
  """
  @spec on_create_subscription(map()) ::
          {:ok, Subscription.t()} | {:error, Ecto.Changeset.t() | any()}
  def on_create_subscription(params) do
    params =
      params
      |> format_subscription_params()
      |> update_plan_status()

    Subscription
    |> Repo.get_by(organisation_id: params.organisation_id)
    |> Repo.preload(:plan)
    |> case do
      %Subscription{plan: %{type: :free}} = subscription ->
        Multi.new()
        |> Multi.delete(:delete_existing_subscription, subscription)
        |> Multi.insert(:new_subscription, Subscription.changeset(%Subscription{}, params))
        |> Repo.transaction()

      %Subscription{} = subscription ->
        Multi.new()
        |> Multi.insert(
          :create_history,
          SubscriptionHistory.changeset(%SubscriptionHistory{}, %{
            provider_subscription_id: subscription.provider_subscription_id,
            event_type: "plan updated",
            current_subscription_start: subscription.start_date,
            current_subscription_end: subscription.end_date,
            transaction_id: subscription.transaction_id,
            subscriber_id: subscription.subscriber_id,
            organisation_id: subscription.organisation_id,
            plan_id: subscription.plan_id
          })
        )
        |> Multi.delete(:delete_existing_subscription, subscription)
        |> Multi.insert(:new_subscription, Subscription.changeset(%Subscription{}, params))
        |> Repo.transaction()

      _ ->
        Multi.new()
        |> Multi.insert(:new_subscription, Subscription.changeset(%Subscription{}, params))
        |> Repo.transaction()
    end
    |> case do
      {:ok, %{new_subscription: subscription}} ->
        {:ok, subscription}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  defp update_plan_status(%{plan_id: plan_id} = params) do
    case Repo.get(Plan, plan_id) do
      %Plan{type: :regular} ->
        Map.put(params, :type, :regular)

      %Plan{type: :enterprise} = plan ->
        plan
        |> Plan.changeset(%{is_active?: false})
        |> Repo.update()

        Map.put(params, :type, :enterprise)

      _ ->
        params
    end
  end

  @doc """
  Update subscription.
  """
  @spec on_update_subscription(map()) ::
          {:ok, Subscription.t()} | {:error, Ecto.Changeset.t() | any()}
  def on_update_subscription(%{"status" => status} = params) when status == "active" do
    params
    |> handle_on_update_subscription()
    |> case do
      {:ok, %{update_subscription: subscription}} ->
        {:ok, subscription}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  def on_update_subscription(%{"status" => status}), do: {:error, "Invalid status: #{status}"}

  @doc """
  Cancel subscription.
  """
  @spec on_cancel_subscription(map()) ::
          {:ok, Subscription.t()} | {:error, Ecto.Changeset.t() | any()}
  def on_cancel_subscription(params) do
    subscription =
      Subscription
      |> Repo.get_by(provider_subscription_id: params["id"])
      |> Repo.preload(:subscriber)

    Multi.new()
    |> Multi.insert(
      :create_history,
      SubscriptionHistory.changeset(%SubscriptionHistory{}, %{
        provider_subscription_id: subscription.provider_subscription_id,
        event_type: "cancelled",
        current_subscription_start: subscription.start_date,
        current_subscription_end: subscription.end_date,
        transaction_id: subscription.transaction_id,
        subscriber_id: subscription.subscriber_id,
        organisation_id: subscription.organisation_id,
        plan_id: subscription.plan_id
      })
    )
    |> Multi.delete(:delete_subscription, subscription)
    |> Multi.run(
      :create_free_plan,
      fn _repo, _changes ->
        Enterprise.create_free_subscription(params["custom_data"]["organisation_id"])
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_subscription: subscription}} ->
        {:ok, subscription}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Adds completed transaction to the database.
  """
  @spec on_complete_transaction(map()) ::
          {:ok, Transaction.t()} | {:error, Ecto.Changeset.t() | any()}
  def on_complete_transaction(params) do
    params
    |> format_transaction_params()
    |> then(&Transaction.changeset(%Transaction{}, &1))
    |> Repo.insert()
    |> case do
      {:ok, transaction} ->
        # Subscription update webhook response doesn't contain transaction_id
        # updating subscription with latest transaction_id
        Subscription
        |> where(provider_subscription_id: ^transaction.provider_subscription_id)
        |> Repo.update_all(set: [transaction_id: transaction.transaction_id])

        {:ok, transaction}

      {:error, error} ->
        {:error, error}
    end
  end

  defp handle_on_update_subscription(params) do
    subscription = Repo.get_by(Subscription, provider_subscription_id: params["id"])
    irrelevant? = params["old_status"] == "paused" && params["status"] == "past_due"

    if subscription && not irrelevant? do
      params = format_subscription_params(params)

      Multi.new()
      |> Multi.insert(
        :create_history,
        SubscriptionHistory.changeset(%SubscriptionHistory{}, %{
          provider_subscription_id: subscription.provider_subscription_id,
          event_type: "plan updated",
          current_subscription_start: subscription.start_date,
          current_subscription_end: subscription.end_date,
          transaction_id: subscription.transaction_id,
          subscriber_id: subscription.subscriber_id,
          organisation_id: subscription.organisation_id,
          plan_id: subscription.plan_id
        })
      )
      |> Multi.update(
        :update_subscription,
        Subscription.update_changeset(subscription, params)
      )
      |> Repo.transaction()
    end
  end

  defp format_subscription_params(
         %{
           "items" => [%{"price" => price} | _],
           "custom_data" => custom_data
         } = params
       ) do
    %{
      provider_subscription_id: params["id"],
      provider_plan_id: price["id"],
      status: params["status"],
      start_date: get_in(params, ["current_billing_period", "starts_at"]),
      end_date: get_in(params, ["current_billing_period", "ends_at"]),
      next_bill_amount: price["unit_price"]["amount"],
      next_bill_date: params["next_billed_at"],
      currency: params["currency_code"],
      transaction_id: params["transaction_id"],
      plan_id: custom_data["plan_id"],
      subscriber_id: custom_data["user_id"],
      organisation_id: custom_data["organisation_id"]
    }
  end

  defp format_transaction_params(params) do
    %{
      transaction_id: params["id"],
      invoice_number: params["invoice_number"],
      invoice_id: params["invoice_id"],
      date: parse_datetime(params["billed_at"]),
      provider_subscription_id: params["subscription_id"],
      provider_plan_id: get_in(params, ["items", Access.at(0), "price", "id"]),
      billing_period_start: parse_datetime(params["billing_period"]["starts_at"]),
      billing_period_end: parse_datetime(params["billing_period"]["ends_at"]),
      subtotal_amount: params["details"]["totals"]["subtotal"],
      tax: params["details"]["totals"]["tax"],
      total_amount: params["details"]["totals"]["total"],
      currency: params["currency_code"],
      payment_method: get_payment_method(params),
      payment_method_details: get_payment_method_details(params),
      organisation_id: params["custom_data"]["organisation_id"],
      subscriber_id: params["custom_data"]["user_id"],
      plan_id: params["custom_data"]["plan_id"]
    }
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(datetime) do
    datetime
    |> NaiveDateTime.from_iso8601!()
    |> DateTime.from_naive!("Etc/UTC")
  end

  defp get_payment_method(params) do
    params["payments"]
    |> Enum.find(fn payment -> payment["status"] == "captured" end)
    |> then(fn payment -> payment && payment["method_details"]["type"] end)
  end

  defp get_payment_method_details(params) do
    params["payments"]
    |> Enum.find(fn payment -> payment["status"] == "captured" end)
    |> then(fn payment -> payment && payment["method_details"] end)
  end

  # may need in future
  # @doc """
  # Update subscription when payment succeeded.
  # """
  # @spec subscription_payment_succeeded(map()) :: {:ok, Subscription.t()} | {:error, any()}
  # def subscription_payment_succeeded(params) do
  #   Repo.transaction(fn ->
  #     handle_subscription_payment_succeeded(params)
  #   end)
  # end

  # defp get_subscription_by_id(subscription_id) do
  #   Repo.get_by(Subscription, provider_subscription_id: subscription_id)
  # end

  # defp handle_subscription_payment_succeeded(params) do
  #   subscription =
  #   params["subscription_id"]
  #   |> get_subscription_by_id()
  #   |> if do

  #     subscription
  #     |> Subscription.changeset(%{
  #       next_bill_amount: params["next_payment"]["amount"],
  #       next_payment_date: params["next_payment"]["date"],
  #       current_period_start: params["last_payment"]["date"]
  #     })
  #     |> Repo.update()
  #     |> Repo.preload(:subscriber)
  #   end
  # end
end
