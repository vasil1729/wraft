defmodule WraftDoc.Pipelines.Stages.Stage do
  @moduledoc """
  The pipeline stages model.
  """
  alias __MODULE__
  use WraftDoc.Schema

  schema "pipe_stage" do
    belongs_to(:content_type, WraftDoc.ContentTypes.ContentType)
    belongs_to(:pipeline, WraftDoc.Pipelines.Pipeline)
    belongs_to(:data_template, WraftDoc.DataTemplates.DataTemplate)
    belongs_to(:state, WraftDoc.Enterprise.Flow.State)
    belongs_to(:creator, WraftDoc.Account.User)
    has_one(:form_mapping, WraftDoc.Forms.FormMapping, foreign_key: :pipe_stage_id)
    has_many(:forms, through: [:form_mapping, :form])
    timestamps()
  end

  def changeset(%Stage{} = stage, attrs \\ %{}) do
    stage
    |> cast(attrs, [:content_type_id, :data_template_id, :pipeline_id, :creator_id])
    |> validate_required([
      :content_type_id,
      :pipeline_id,
      :data_template_id,
      :creator_id
    ])
    |> unique_constraint(:data_template_id,
      name: :pipe_stages_unique_index,
      message: "Already added.!"
    )
  end

  def update_changeset(%Stage{} = stage, attrs \\ %{}) do
    stage
    |> cast(attrs, [:content_type_id, :data_template_id])
    |> validate_required([
      :content_type_id,
      :data_template_id
    ])
    |> unique_constraint(:data_template_id,
      name: :pipe_stages_unique_index,
      message: "Already added.!"
    )
  end
end
