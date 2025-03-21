defmodule WraftDoc.TemplateAssets do
  @moduledoc """
  Context module for Template Assets.
  """

  import Ecto
  import Ecto.Query

  require Logger

  alias Ecto.Multi
  alias WraftDoc.Assets
  alias WraftDoc.Client.Minio
  alias WraftDoc.ContentTypes
  alias WraftDoc.ContentTypes.ContentType
  alias WraftDoc.DataTemplates
  alias WraftDoc.DataTemplates.DataTemplate
  alias WraftDoc.DataTemplates.DataTemplate
  alias WraftDoc.Documents
  alias WraftDoc.Documents.Engine
  alias WraftDoc.Enterprise
  alias WraftDoc.Enterprise.Flow
  alias WraftDoc.Fields.FieldType
  alias WraftDoc.Frames
  alias WraftDoc.Frames.Frame
  alias WraftDoc.Layouts
  alias WraftDoc.Layouts.Layout
  alias WraftDoc.Repo
  alias WraftDoc.TemplateAssets.TemplateAsset
  alias WraftDoc.TemplateAssets.WraftJson
  alias WraftDoc.Themes
  alias WraftDoc.Themes.Theme
  alias WraftDoc.Utils.FileHelper
  alias WraftDoc.Utils.ProsemirrorToMarkdown

  @required_items ["layout", "theme", "flow", "variant"]
  @allowed_folders ["theme", "layout", "frame"]
  @allowed_files ["template.json", "wraft.json"]
  @font_style_name ~w(Regular Italic Bold BoldItalic)

  @doc """
  Create a template asset.
  """
  # TODO - write test
  @spec create_template_asset(User.t(), map()) ::
          {:ok, TemplateAsset.t()} | {:error, Ecto.Changset.t()}
  def create_template_asset(%{current_org_id: org_id} = current_user, params) do
    params = Map.merge(params, %{"organisation_id" => org_id})

    Multi.new()
    |> Multi.insert(
      :template_asset,
      current_user |> build_assoc(:template_assets) |> TemplateAsset.changeset(params)
    )
    |> Multi.update(
      :template_asset_file_upload,
      &TemplateAsset.file_changeset(&1.template_asset, params)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{template_asset_file_upload: template_asset}} -> {:ok, template_asset}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_template_asset(_, _), do: {:error, :fake}

  @doc """
  Index of all template assets in an organisation.
  """
  # TODO - Write tests
  @spec template_asset_index(User.t(), map()) :: map()
  def template_asset_index(%{current_org_id: organisation_id}, params) do
    query =
      from(a in TemplateAsset,
        where: a.organisation_id == ^organisation_id,
        order_by: [desc: a.inserted_at]
      )

    Repo.paginate(query, params)
  end

  def template_asset_index(_, _), do: {:error, :fake}

  @doc """
  Show a template asset.
  """
  # TODO - write tests
  @spec show_template_asset(binary(), User.t()) :: TemplateAsset.t() | {:error, atom()}
  def show_template_asset(<<_::288>> = template_asset_id, user) do
    template_asset_id
    |> get_template_asset(user)
    |> Repo.preload([:creator])
  end

  @doc """
  Get a template asset from its UUID.
  """
  # TODO - Write tests
  @spec get_template_asset(binary(), User.t()) :: TemplateAsset.t() | {:error, atom()}
  def get_template_asset(<<_::288>> = id, %{current_org_id: org_id}),
    do: Repo.get_by(TemplateAsset, id: id, organisation_id: org_id)

  def get_template_asset(_, _), do: {:error, :fake}

  def get_template_asset(<<_::288>> = id),
    do: Repo.get_by(TemplateAsset, id: id)

  def get_template_asset(_), do: {:error, :fake}

  @doc """
  Update a template asset.
  """
  # TODO - Write tests
  @spec update_template_asset(TemplateAsset.t(), map()) ::
          {:ok, TemplateAsset.t()} | {:error, Ecto.Changset.t()}
  def update_template_asset(template_asset, params) do
    template_asset |> TemplateAsset.update_changeset(params) |> Repo.update()
  end

  @doc """
  Delete a template asset.
  """
  # TODO - Write tests
  @spec delete_template_asset(TemplateAsset.t()) ::
          {:ok, TemplateAsset.t()} | {:error, Ecto.Changset.t()}
  def delete_template_asset(
        %TemplateAsset{id: id, organisation_id: organisation_id} = template_asset
      ) do
    Minio.delete_file("organisations/#{organisation_id}/template_assets/#{id}")

    Repo.delete(template_asset)
  end

  @doc """
  Imports template asset.
  """
  @spec import_template(User.t(), binary(), list()) ::
          DataTemplate.t() | {:error, any()}
  def import_template(current_user, downloaded_zip_binary, opts \\ []) do
    with {:ok, entries} <- FileHelper.get_file_entries(downloaded_zip_binary),
         {:ok, template_map} <- FileHelper.get_wraft_json(downloaded_zip_binary),
         contained_items <- has_items(template_map),
         :ok <- validate_required_items(contained_items, opts) do
      prepare_template(
        template_map,
        current_user,
        downloaded_zip_binary,
        entries,
        opts
      )
    end
  end

  defp has_items(template_map) do
    Enum.filter(@required_items, fn key ->
      Map.has_key?(template_map, key)
    end)
  end

  defp validate_required_items(contained_items, opts) do
    optional_ids = [
      Keyword.get(opts, :layout_id),
      Keyword.get(opts, :theme_id),
      Keyword.get(opts, :flow_id),
      Keyword.get(opts, :content_type_id),
      Keyword.get(opts, :frame_id)
    ]

    @required_items
    |> Enum.filter(fn key ->
      key not in contained_items &&
        is_nil(Enum.at(optional_ids, Enum.find_index(@required_items, &(&1 == key))))
    end)
    |> case do
      [] ->
        :ok

      missing_items ->
        missing_items
        |> Enum.map(fn item ->
          %{
            item: item,
            message:
              "Either '#{item}' must be in the ZIP or the corresponding #{item}_id must be provided"
          }
        end)
        |> then(&{:error, %{missing_items: &1}})
    end
  end

  @doc """
  Format optional params.
  """
  @spec format_opts(map()) :: list()
  def format_opts(params) do
    Enum.reduce([:theme_id, :flow_id, :layout_id, :content_type_id, :frame_id], [], fn key, acc ->
      case Map.get(params, Atom.to_string(key)) do
        nil -> acc
        value -> [{key, value} | acc]
      end
    end)
  end

  @doc """
  Pre-import template asset returns existing and missing items.
  """
  @spec pre_import_template(binary()) :: {:ok, map()} | {:error, any()}
  def pre_import_template(downloaded_zip_binary) do
    {:ok, template_map} = FileHelper.get_wraft_json(downloaded_zip_binary)

    existing_items =
      %{
        theme: Map.get(template_map, "theme"),
        layout: Map.get(template_map, "layout"),
        frame: Map.get(template_map, "frame"),
        flow: Map.get(template_map, "flow"),
        data_template: Map.get(template_map, "data_template"),
        variant: Map.get(template_map, "variant")
      }
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    missing_items = @required_items -- has_items(template_map)

    {:ok, %{existing_items: existing_items, missing_items: missing_items}}
  end

  @doc """
  Download zip file from storage as binary.
  """
  @spec download_zip_from_storage(User.t(), Ecto.UUID.t()) :: {:error, any()} | {:ok, binary()}
  def download_zip_from_storage(current_user, template_asset_id) do
    with %TemplateAsset{zip_file: zip_file} <-
           get_template_asset(template_asset_id, current_user),
         downloaded_zip_binary <-
           Minio.get_object(
             "organisations/#{current_user.current_org_id}/template_assets/#{template_asset_id}/template_#{zip_file.file_name}"
           ) do
      {:ok, downloaded_zip_binary}
    end
  rescue
    error -> {:error, error.message}
  end

  def download_zip_from_storage(template_asset_id) do
    with %TemplateAsset{zip_file: zip_file} <-
           get_template_asset(template_asset_id),
         file_name <- get_rootname(zip_file.file_name),
         downloaded_zip_binary <-
           Minio.get_object("public/templates/#{file_name}/#{file_name}.zip") do
      {:ok, downloaded_zip_binary}
    end
  rescue
    error -> {:error, error.message}
  end

  # TODO move to zip_helper
  defp template_asset_file_list(zip_binary) do
    case FileHelper.get_file_entries(zip_binary) do
      {:ok, entries} ->
        filter_entries(entries)

      {:error, error} ->
        {:error, error}
    end
  end

  defp filter_entries(entries) do
    Enum.reduce(entries, [], fn %{file_name: file_name}, acc ->
      if Enum.any?(@allowed_folders, &String.starts_with?(file_name, "#{&1}/")) ||
           file_name in @allowed_files do
        [file_name | acc]
      else
        acc
      end
    end)
  end

  defp prepare_template(
         template_map,
         current_user,
         downloaded_file,
         entries,
         opts
       ) do
    case prepare_template_transaction(
           template_map,
           current_user,
           downloaded_file,
           entries,
           opts
         ) do
      {:ok, result} ->
        Logger.info("Theme, Layout, Flow, variant created successfully.")

        %{
          theme: Map.get(result, :theme),
          flow: Map.get(result, :flow),
          frame: Map.get(result, :frame),
          layout: Map.get(result, :layout),
          variant: Map.get(result, :content_type),
          data_template: Map.get(result, :data_template)
        }
        |> Enum.filter(fn {_key, value} -> value != nil end)
        |> Enum.into(%{})
        |> then(&{:ok, &1})

      {:error, _failed_operation, error, _changes_so_far} ->
        Logger.error("Failed to process. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  defp prepare_template_transaction(
         template_map,
         current_user,
         downloaded_file,
         entries,
         opts
       ) do
    build_multi()
    |> add_theme_step(template_map, current_user, downloaded_file, entries)
    |> add_flow_step(template_map, current_user)
    |> add_frame_step(template_map, current_user, downloaded_file, entries)
    |> add_layout_step(template_map, current_user, downloaded_file, entries, opts)
    |> add_variant_step(template_map, current_user, opts)
    |> add_data_template_step(template_map, current_user, downloaded_file, opts)
    |> Repo.transaction()
  end

  defp build_multi, do: Multi.new()

  defp add_theme_step(multi, %{"theme" => theme}, current_user, downloaded_file, entries) do
    Multi.run(multi, :theme, fn _repo, _changes ->
      theme
      |> update_conflicting_name(Theme, current_user)
      |> prepare_theme(current_user, downloaded_file, entries)
    end)
  end

  defp add_theme_step(multi, _template_map, _current_user, _downloaded_file, _entries), do: multi

  defp add_flow_step(multi, %{"flow" => flow}, %{current_org_id: org_id} = current_user) do
    flow =
      flow
      |> Map.merge(%{"organisation_id" => org_id})
      |> update_conflicting_name(Flow, current_user)

    multi
    |> Multi.insert(
      :flow,
      current_user
      |> build_assoc(:flows)
      |> Flow.changeset(flow)
    )
    |> Multi.run(:default_flow_states, fn _repo, %{flow: flow} ->
      current_user
      |> Enterprise.create_default_states(flow)
      |> then(&{:ok, &1})
    end)
  end

  defp add_flow_step(multi, _template_map, _current_user), do: multi

  defp add_layout_step(multi, %{"layout" => layout}, current_user, downloaded_file, entries, opts) do
    Multi.run(multi, :layout, fn _repo, changes ->
      frame_id = Keyword.get(opts, :frame_id, nil)
      frame = Map.get(changes, :frame, nil)

      layout
      |> update_conflicting_name(Layout, current_user)
      |> prepare_layout(downloaded_file, current_user, entries, frame_id || (frame && frame.id))
    end)
  end

  defp add_layout_step(multi, _template_map, _current_user, _downloaded_file, _entries, _opts),
    do: multi

  # TODO: update frame
  defp add_frame_step(multi, %{"frame" => frame}, current_user, downloaded_file, entries) do
    Multi.run(multi, :frame, fn _repo, _changes ->
      frame
      |> update_conflicting_name(Frame, current_user)
      |> prepare_frame(downloaded_file, current_user, entries)
    end)
  end

  defp add_frame_step(multi, _template_map, _current_user, _downloaded_file, _entries), do: multi

  defp add_variant_step(multi, %{"variant" => variant}, current_user, opts) do
    theme_id = Keyword.get(opts, :theme_id, nil)
    layout_id = Keyword.get(opts, :layout_id, nil)
    flow_id = Keyword.get(opts, :flow_id, nil)

    Multi.run(multi, :content_type, fn _repo, changes ->
      theme = Map.get(changes, :theme, nil)
      layout = Map.get(changes, :layout, nil)
      flow = Map.get(changes, :flow, nil)

      variant
      |> update_conflicting_name(ContentType, current_user)
      |> prepare_content_type(
        current_user,
        theme_id || (theme && theme.id),
        layout_id || (layout && layout.id),
        flow_id || (flow && flow.id)
      )
    end)
  end

  defp add_variant_step(multi, _template_map, _current_user, _opts), do: multi

  defp add_data_template_step(
         multi,
         %{"data_template" => data_template},
         current_user,
         downloaded_file,
         opts
       ) do
    Multi.run(multi, :data_template, fn _repo, changes ->
      changes
      |> get_content_type(opts)
      |> case do
        {:ok, %ContentType{} = content_type} ->
          data_template
          |> update_conflicting_name(DataTemplate, current_user)
          |> then(&prepare_data_template(current_user, &1, downloaded_file, content_type))

        error ->
          error
      end
    end)
  end

  defp add_data_template_step(multi, _template_map, _current_user, _downloaded_file, _opts),
    do: multi

  defp get_content_type(changes, opts) do
    changes
    |> Map.get(:content_type, nil)
    |> case do
      nil ->
        opts
        |> Keyword.get(:content_type_id)
        |> get_content_type_from_id()

      content_type ->
        {:ok, content_type}
    end
  end

  defp get_content_type_from_id(nil), do: {:error, "content type id not found"}

  defp get_content_type_from_id(id), do: {:ok, ContentTypes.get_content_type_from_id(id)}

  defp get_engine(engine) do
    # TODO multiple engines selection
    [engine1, _engine2] = String.split(engine, "/")

    case Repo.get_by(Engine, name: String.capitalize(engine1)) do
      nil -> Logger.warning("No engine found with the name #{engine1}")
      engine -> engine.id
    end
  end

  defp prepare_theme(theme, current_user, downloaded_file, entries) do
    with asset_ids <- prepare_theme_assets(entries, downloaded_file, current_user),
         params <- prepare_theme_attrs(theme, asset_ids),
         %Theme{} = theme <- Themes.create_theme(current_user, params) do
      {:ok, theme}
    end
  end

  defp prepare_theme_assets(entries, downloaded_file, current_user) do
    entries
    |> get_theme_font_file_entries()
    |> extract_and_save_fonts(downloaded_file, current_user)
  end

  defp prepare_theme_attrs(%{"name" => name, "colors" => colors, "fonts" => fonts}, asset_ids) do
    font_name =
      fonts
      |> List.first()
      |> Map.get("fontName", name)
      |> Path.rootname()
      |> String.replace(~r/[-\s]/, "")

    Map.merge(colors, %{
      "name" => name,
      "font" => font_name,
      "primary_color" => colors["primaryColor"],
      "secondary_color" => colors["secondaryColor"],
      "body_color" => colors["bodyColor"],
      "assets" => asset_ids
    })
  end

  defp get_theme_font_file_entries(entries) do
    Enum.filter(entries, fn entry ->
      case Regex.run(~r/^theme\/.*-(?<style>\w+)\.(otf|ttf)$/i, entry.file_name) do
        [_, style, _] when style in @font_style_name -> true
        _ -> false
      end
    end)
  end

  defp extract_and_save_fonts(entries, downloaded_zip_file, current_user) do
    entries
    |> Task.async_stream(&create_theme_asset(&1, downloaded_zip_file, current_user),
      timeout: 60_000,
      max_concurrency: 4
    )
    |> Enum.reduce("", fn
      {:ok, <<_::288>> = asset_id}, "" ->
        "#{asset_id}"

      {:ok, <<_::288>> = asset_id}, acc ->
        "#{acc},#{asset_id}"

      {:ok, {:error, _reason}}, acc ->
        acc

      {:exit, reason}, acc ->
        Logger.error("Saving font failed with reason: #{inspect(reason)}")
        acc
    end)
  end

  defp create_theme_asset(entry, downloaded_zip_file, current_user) do
    with {:ok, content} <- FileHelper.extract_file_content(downloaded_zip_file, entry.file_name),
         {:ok, temp_file_path} <- write_temp_file(content),
         asset_params = prepare_theme_asset_params(entry, temp_file_path, current_user),
         {:ok, asset} <- Assets.create_asset(current_user, asset_params) do
      asset.id
    else
      error ->
        Logger.error("""
        Failed to create theme asset: #{inspect(entry.file_name)}.
        Error: #{inspect(error)}.
        """)

        {:error, error}
    end
  end

  defp write_temp_file(content) do
    temp_file_path = Briefly.create!()
    File.write(temp_file_path, content)
    {:ok, temp_file_path}
  end

  defp prepare_theme_asset_params(entry, temp_file_path, current_user) do
    %{
      "name" => Path.basename(entry.file_name),
      "type" => "theme",
      "file" => %Plug.Upload{
        filename: Path.basename(entry.file_name),
        content_type: get_file_type(entry.file_name),
        path: temp_file_path
      },
      "creator_id" => current_user.id
    }
  end

  defp get_file_type(filename) do
    case Path.extname(filename) do
      ".otf" -> "font/otf"
      ".ttf" -> "font/ttf"
      ".pdf" -> "application/pdf"
      ".tex" -> "application/x-tex"
      _ -> "application/octet-stream"
    end
  end

  defp prepare_layout(layouts, downloaded_file, current_user, entries, frame_id) do
    # filter engine name
    engine_id = get_engine(layouts["engine"])

    with asset_id <- prepare_layout_assets(entries, downloaded_file, current_user),
         params <- prepare_layout_attrs(layouts, engine_id, asset_id, frame_id),
         %Engine{} = engine <- Documents.get_engine(params["engine_id"]),
         %Layout{} = layout <- Layouts.create_layout(current_user, engine, params) do
      {:ok, layout}
    end
  end

  defp prepare_layout_assets(entries, downloaded_file, current_user) do
    entries
    |> get_layout_file_entries()
    |> extract_and_prepare_layout_asset(downloaded_file, current_user)
  end

  defp prepare_layout_attrs(layout, engine_id, asset_id, frame_id) do
    %{
      "name" => layout["name"],
      "meta" => layout["meta"],
      "description" => layout["description"],
      "slug" => layout["slug"],
      "engine_id" => engine_id,
      "assets" => asset_id,
      "width" => 40,
      "height" => 40,
      "unit" => "cm",
      "frame_id" => frame_id
    }
  end

  defp get_layout_file_entries(entries) do
    Enum.filter(entries, fn entry ->
      entry.file_name =~ ~r/^layout\/.*\.pdf$/i
    end)
  end

  defp extract_and_prepare_layout_asset(entries, downloaded_zip_file, current_user) do
    entry = List.first(entries)

    with {:ok, content} <- FileHelper.extract_file_content(downloaded_zip_file, entry.file_name),
         {:ok, temp_file_path} <- write_temp_file(content),
         asset_params <- prepare_layout_asset_params(entry, temp_file_path, current_user),
         {:ok, asset} <- Assets.create_asset(current_user, asset_params) do
      asset.id
    else
      error ->
        Logger.error(
          "Failed to process entry: #{inspect(entry.file_name)}. Error: #{inspect(error)}"
        )

        nil
    end
  end

  defp prepare_layout_asset_params(entry, temp_file_path, current_user) do
    %{
      "name" => Path.basename(entry.file_name),
      "type" => "layout",
      "file" => %Plug.Upload{
        filename: Path.basename(entry.file_name),
        content_type: get_file_type(entry.file_name),
        path: temp_file_path
      },
      "creator_id" => current_user.id
    }
  end

  defp prepare_frame(frame, downloaded_file, current_user, entries) do
    with {:ok, attrs, content} <-
           prepare_frame_attrs(frame, current_user, downloaded_file, entries),
         {:ok, frame} <- Frames.create_frame(current_user, attrs) do
      frame
      |> local_frame_path()
      |> File.write!(content)

      {:ok, frame}
    end
  end

  defp prepare_frame_attrs(frame, _current_user, downloaded_file, entries) do
    with {:ok, entry} <- get_frame_file_entry(entries),
         {:ok, content} <- FileHelper.extract_file_content(downloaded_file, entry.file_name),
         {:ok, temp_file_path} <- write_temp_file(content) do
      frame
      |> Map.merge(%{
        "frame_file" => %Plug.Upload{
          filename: Path.basename(entry.file_name),
          content_type: get_file_type(entry.file_name),
          path: temp_file_path
        }
      })
      |> then(&{:ok, &1, content})
    end
  end

  defp get_frame_file_entry(entries) do
    entries
    |> Enum.filter(fn entry ->
      entry.file_name =~ ~r/^frame\/.*\.tex$/i
    end)
    |> List.first()
    |> case do
      nil -> {:error, "frame file entries not found"}
      entry -> {:ok, entry}
    end
  end

  defp local_frame_path(%Frame{name: name, organisation_id: organisation_id}) do
    :wraft_doc
    |> :code.priv_dir()
    |> Path.join("slugs/organisation/#{organisation_id}/#{name}/.")
    |> File.exists?()
    |> case do
      true ->
        :wraft_doc
        |> :code.priv_dir()
        |> Path.join("slugs/organisation/#{organisation_id}/#{name}/.")

      false ->
        slugs_dir =
          :wraft_doc
          |> :code.priv_dir()
          |> Path.join("slugs/organisation/#{organisation_id}/#{name}/.")

        File.mkdir_p!(slugs_dir)
        Path.join(slugs_dir, "template.tex")
    end
  end

  defp prepare_content_type(variant, current_user, theme_id, layout_id, flow_id) do
    with params <-
           prepare_content_type_attrs(variant, current_user, theme_id, layout_id, flow_id),
         %ContentType{} = content_type <- ContentTypes.create_content_type(current_user, params) do
      {:ok, content_type}
    end
  end

  defp prepare_content_type_attrs(
         %{
           "name" => name,
           "description" => description,
           "color" => color,
           "prefix" => prefix
         } = content_type,
         current_user,
         theme_id,
         layout_id,
         flow_id
       ) do
    # TODO use this for common
    field_types = Repo.all(from(ft in FieldType, select: {ft.name, ft.id}))
    field_type_map = Map.new(field_types)

    fields =
      Enum.map(content_type["fields"], fn field ->
        field_type = String.capitalize(field["type"])

        %{
          "field_type_id" => Map.get(field_type_map, field_type),
          "key" => field["name"],
          "name" => field["name"]
        }
      end)

    %{
      "name" => name,
      "description" => description,
      "color" => color,
      "prefix" => prefix,
      "layout_id" => layout_id,
      "flow_id" => flow_id,
      "theme_id" => theme_id,
      "fields" => fields,
      "organisation_id" => current_user.current_org_id,
      "creator_id" => current_user.id
    }
  end

  defp prepare_data_template(current_user, template_map, downloaded_file, content_type) do
    with params when is_map(params) <-
           prepare_data_template_attrs(template_map, downloaded_file, content_type.id),
         {:ok, %DataTemplate{} = data_template} <-
           DataTemplates.create_data_template(current_user, content_type, params) do
      {:ok, data_template}
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp prepare_data_template_attrs(template_map, downloaded_file, content_type_id) do
    case get_data_template_prosemirror(downloaded_file) do
      {:ok, serialized_prosemirror_data} ->
        markdown_data =
          serialized_prosemirror_data
          |> Jason.decode!()
          |> ProsemirrorToMarkdown.convert()

        %{
          "c_type_id" => content_type_id,
          "title" => template_map["title"],
          "title_template" => template_map["title_template"],
          "data" => markdown_data,
          "serialized" => %{"data" => serialized_prosemirror_data}
        }

      {:error, error} ->
        Logger.error("Failed to prepare data template. Error: #{inspect(error)}")
        {:error, error}
    end
  end

  # Not using now for future use
  # defp get_data_template_md(downloaded_file) do
  #   case FileHelper.get_file_entries(downloaded_file) do
  #     {:ok, entries} ->
  #       template_md = Enum.find(entries, fn entry -> entry.file_name =~ ~r/^.*\.md$/i end)
  #       template_md.file_name
  #     _ ->
  #       Logger.error(" template data not found")
  #   end
  # end

  defp get_data_template_prosemirror(downloaded_file) do
    with {:ok, template_json} <-
           FileHelper.extract_file_content(downloaded_file, "template.json"),
         serialized_prosemirror <- Jason.decode!(template_json) do
      {:ok, serialized_prosemirror["data"]}
    end
  end

  defp template_zip_validator(zip_binary, file_entries_in_zip) do
    with true <- validate_file_entries(file_entries_in_zip),
         {:ok, wraft_json} <- FileHelper.get_wraft_json(zip_binary),
         true <- validate_wraft_json(wraft_json),
         :ok <- validate_wraft_json_folders(file_entries_in_zip, wraft_json) do
      :ok
    else
      {:error, error} ->
        {:error, error}
    end
  end

  defp validate_file_entries(entries) do
    files_in_zip = extract_files(entries)
    missing_files = @allowed_files -- files_in_zip

    case missing_files do
      [] ->
        true

      _ ->
        {:error, "Required items not found in this zip file: #{Enum.join(missing_files, ", ")}"}
    end
  end

  defp validate_wraft_json(wraft_json) do
    %WraftJson{}
    |> WraftJson.changeset(wraft_json)
    |> case do
      %{valid?: true} -> true
      %{valid?: false} = changeset -> {:error, "wraft.json: #{extract_errors(changeset)}"}
    end
  end

  defp extract_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> format_errors()
  end

  defp format_errors(errors, prefix \\ "") do
    Enum.map_join(errors, "; ", fn
      {field, sub_errors} when is_map(sub_errors) ->
        new_prefix = if prefix == "", do: to_string(field), else: "#{prefix}.#{field}"
        format_errors(sub_errors, new_prefix)

      {field, messages} ->
        field_name = if prefix == "", do: to_string(field), else: "#{prefix}.#{field}"
        "#{field_name}: #{Enum.join(messages, ", ")}"
    end)
  end

  defp extract_files(entries) do
    Enum.filter(entries, &(!String.ends_with?(&1, "/")))
  end

  defp validate_wraft_json_folders(file_entries, wraft_json) do
    @required_items
    |> Enum.filter(fn item ->
      Map.get(wraft_json, item) != nil and item in @allowed_folders
    end)
    |> Enum.reject(fn folder ->
      Enum.any?(file_entries, &String.starts_with?(&1, "#{folder}/"))
    end)
    |> case do
      [] ->
        :ok

      missing_folders ->
        {:error, "Missing required folders for: #{Enum.join(missing_folders, ", ")}"}
    end
  end

  @doc """
  Processes a template asset by extracting and validating the contents of a ZIP file or URL, returning
  a modified parameters map with extracted data, the binary content of the ZIP, and a list of file entries.
  """
  @spec process_template_asset(map(), :file | :url, Plug.Upload.t() | String.t()) ::
          {:ok, map(), binary()} | {:error, any()}
  def process_template_asset(params, source_type, source_value) do
    with {:ok, zip_binary} <- get_zip_binary(source_type, source_value),
         file_entries_in_zip <- template_asset_file_list(zip_binary),
         :ok <- template_zip_validator(zip_binary, file_entries_in_zip),
         {:ok, wraft_json} <- FileHelper.get_wraft_json(zip_binary) do
      params
      |> Map.merge(%{
        "wraft_json" => wraft_json,
        "file_entries" => file_entries_in_zip
      })
      |> then(&{:ok, &1, zip_binary})
    end
  end

  @doc """
  Adds a ZIP file to the params map as a `Plug.Upload` struct.
  """
  @spec add_file_to_params(map(), binary(), String.t()) :: {:ok, map()}
  def add_file_to_params(params, zip_binary, zip_url) do
    file_path = Briefly.create!()
    File.write!(file_path, zip_binary)
    file_name = zip_url |> URI.parse() |> Map.get(:path) |> Path.basename()

    file = %Plug.Upload{
      filename: file_name,
      content_type: "application/zip",
      path: file_path
    }

    params
    |> Map.put("zip_file", file)
    |> then(&{:ok, &1})
  end

  defp get_zip_binary_from_url(url) do
    case HTTPoison.get(url, [], follow_redirect: true) do
      {:ok, %{status_code: 200, body: binary}} ->
        {:ok, binary}

      {:ok, %{status_code: status_code}} ->
        {:error, "Failed to fetch file. Received status code: #{status_code}."}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request failed: #{reason}"}
    end
  end

  defp get_zip_binary(:file, %Plug.Upload{
         path: file_path
       }),
       do: FileHelper.read_file_contents(file_path)

  defp get_zip_binary(:url, url), do: get_zip_binary_from_url(url)

  @doc """
  Prepare all the nessecary files and format for zip export.
  """
  def prepare_template_format(theme, layout, c_type, data_template, current_user) do
    folder_path = data_template.title
    File.mkdir_p!(folder_path)

    case create_wraft_json(theme, layout, c_type, data_template, folder_path, current_user) do
      :ok ->
        template_name = "#{data_template.title}.zip"
        {:ok, zip_path} = zip_folder(folder_path, template_name)

        File.rm_rf(folder_path)
        {:ok, zip_path}

      {:error, reason} ->
        File.rm_rf(folder_path)
        {:error, "Failed to prepare template: #{reason}"}
    end
  end

  def create_wraft_json(theme, layout, c_type, data_template, folder_path, current_user) do
    wraft_data = build_wraft_json(theme, layout, c_type, data_template, folder_path, current_user)

    wraft_path = Path.join(folder_path, "wraft.json")

    with {:ok, json} <- Jason.encode(wraft_data, pretty: true),
         :ok <- File.write(wraft_path, json) do
      :ok
    else
      {:error, reason} -> {:error, "Failed to create wraft.json: #{reason}"}
    end
  end

  defp zip_folder(folder_path, template_name) do
    zip_path = Path.join(System.tmp_dir!(), "#{template_name}.zip")
    :zip.create(String.to_charlist(zip_path), [String.to_charlist(folder_path)])
    {:ok, zip_path}
  end

  def build_wraft_json(theme, layout, c_type, data_template, file_path, current_user) do
    %{
      "theme" => build_theme(theme, file_path, current_user),
      "layout" => build_layout(layout, file_path, current_user),
      "variant" => build_c_type(c_type),
      "data_template" => %{
        "title" => data_template.title,
        "title_template" => data_template.title_template
      }
    }
  end

  defp build_theme(theme, file_path, current_user) do
    theme = Repo.preload(theme, :assets)

    %{
      "name" => theme.name,
      "fonts" =>
        Enum.map(theme.assets, fn asset ->
          %{
            "fontName" => asset.name,
            "filePath" => download_file(asset.id, current_user, file_path, "otf", "theme")
          }
        end),
      "color" => %{
        "body_color" => theme.body_color,
        "primary_color" => theme.primary_color,
        "secondary_color" => theme.secondary_color
      }
    }
  end

  defp build_layout(layout, file_path, current_user) do
    layout = Repo.preload(layout, :assets)
    [asset | _] = layout.assets

    %{
      "name" => layout.name,
      "slug" => make_slug(layout.slug, file_path),
      "slug_file" => download_file(asset.id, current_user, file_path, "pdf", "layout"),
      "meta" => "fields",
      "description" => layout.description,
      "engine" => "pandoc/latex"
    }
  end

  defp build_c_type(c_type) do
    c_type = Repo.preload(c_type, [:theme, :layout, [fields: [:field_type]]])

    %{
      "name" => c_type.name,
      "color" => c_type.color,
      "description" => c_type.description,
      "prefix" => c_type.prefix,
      "fields" =>
        Enum.map(c_type.fields, fn field ->
          %{
            "name" => field.name,
            "description" => field.description,
            "type" => field.field_type.name
          }
        end)
    }
  end

  defp make_slug(slug, file_path) do
    path = :wraft_doc |> :code.priv_dir() |> Path.join("slugs/#{slug}/.")
    System.cmd("cp", ["-a", path, file_path <> "/" <> slug])
    slug
  end

  defp download_file(
         asset_id,
         %{current_org_id: org_id} = _current_user,
         file_path,
         format,
         folder_name
       ) do
    file = Minio.download("organisations/#{org_id}/assets/#{asset_id}")
    asset = Assets.get_asset(asset_id, %{current_org_id: org_id})
    path = "#{file_path}/#{folder_name}/#{asset.name}.#{format}"
    File.mkdir_p(Path.dirname(path))
    File.write!(path, file)
    "#{folder_name}/#{asset.name}.#{format}"
  end

  defp update_conflicting_name(%{"title" => title} = map, DataTemplate, current_user) do
    title
    |> unique_name(DataTemplate, current_user)
    |> then(&put_in(map, ["title"], &1))
  end

  defp update_conflicting_name(%{"name" => name} = map, type, current_user) do
    name
    |> unique_name(type, current_user)
    |> then(&put_in(map, ["name"], &1))
  end

  defp increment_name(name) do
    case Regex.run(~r/^(.*?)(\d+)$/, name, capture: :all_but_first) do
      [base, num] -> "#{String.trim(base)} #{String.to_integer(num) + 1}"
      _ -> "#{name} 2"
    end
  end

  defp unique_name(name, type, current_user) do
    name
    |> build_uniqueness_query(type, current_user)
    |> Repo.exists?()
    |> case do
      true ->
        name
        |> increment_name()
        |> unique_name(type, current_user)

      false ->
        name
    end
  end

  defp build_uniqueness_query(name, DataTemplate, current_user) do
    from(f in DataTemplate, where: f.title == ^name and f.creator_id == ^current_user.id)
  end

  defp build_uniqueness_query(name, type, current_user) do
    from(f in type,
      where: f.name == ^name and f.organisation_id == ^current_user.current_org_id
    )
  end

  defp get_rootname(path) do
    path
    |> Path.basename()
    |> Path.rootname()
  end

  @doc """
  Index of all public template assets.
  """
  @spec public_template_asset_index() :: {:ok, list()}
  def public_template_asset_index do
    query =
      from(t in TemplateAsset,
        where: is_nil(t.organisation_id) and is_nil(t.creator_id),
        order_by: [desc: t.inserted_at]
      )

    query
    |> Repo.all()
    |> Enum.map(fn template_asset ->
      rootname = get_rootname(template_asset.zip_file.file_name)

      %{
        id: template_asset.id,
        name: template_asset.name,
        description: template_asset.description,
        file_name: rootname,
        file_size: template_asset.zip_file_size,
        zip_file_url: Path.join(storage_url(), "public/templates/#{rootname}/#{rootname}.zip"),
        thumbnail_url: Path.join(storage_url(), "public/templates/#{rootname}/thumbnail.png")
      }
    end)
    |> then(&{:ok, &1})
  end

  defp storage_url, do: Path.join(System.get_env("MINIO_URL"), System.get_env("MINIO_BUCKET"))

  @doc """
  Download template from storage.
  """
  @spec download_public_template(String.t()) :: {:ok, binary()} | {:error, String.t()}
  def download_public_template(template_name) do
    template_name
    |> then(&"public/templates/#{&1}/#{&1}.zip")
    |> Minio.generate_url()
    |> then(&{:ok, &1})
  end
end
