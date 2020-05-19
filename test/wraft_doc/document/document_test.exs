defmodule WraftDoc.DocumentTest do
  use WraftDoc.DataCase, async: true
  import WraftDoc.Factory
  use ExUnit.Case
  use Bamboo.Test

  alias WraftDoc.{
    Repo,
    Document.Layout,
    Document.ContentType,
    Document.Instance,
    Document.Instance.Version,
    Document.DataTemplate,
    Document.LayoutAsset,
    Document.Counter,
    Document.BlockTemplate,
    Document.Pipeline,
    Document.Pipeline.Stage,
    Document.Theme,
    Document.Asset,
    Document.Comment,
    Document
  }

  @valid_layout_attrs %{
    "name" => "layout name",
    "description" => "layout description",
    "width" => 25.0,
    "height" => 44.0,
    "unit" => "cm",
    "slug" => "layout slug"
  }
  @valid_instance_attrs %{
    "instance_id" => "OFFR0001",
    "raw" => "instance raw",
    "serialized" => %{"body" => "body of the content", "title" => "title of the content"},
    "type" => 1
  }
  @valid_content_type_attrs %{
    "name" => "content_type name",
    "description" => "content_type description",
    "color" => "#fff",
    "prefix" => "OFFRE"
  }
  @invalid_attrs %{}

  test "create layout on valid attributes" do
    user = insert(:user)
    engine = insert(:engine)
    count_before = Layout |> Repo.all() |> length()
    layout = Document.create_layout(user, engine, @valid_layout_attrs)
    assert count_before + 1 == Layout |> Repo.all() |> length()
    assert layout.name == @valid_layout_attrs["name"]
    assert layout.description == @valid_layout_attrs["description"]
    assert layout.width == @valid_layout_attrs["width"]
    assert layout.height == @valid_layout_attrs["height"]
    assert layout.unit == @valid_layout_attrs["unit"]
    assert layout.slug == @valid_layout_attrs["slug"]
  end

  test "create layout on invalid attrs" do
    user = insert(:user)
    count_before = Layout |> Repo.all() |> length()
    engine = insert(:engine)
    {:error, changeset} = Document.create_layout(user, engine, @invalid_attrs)
    count_after = Layout |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             name: ["can't be blank"],
             description: ["can't be blank"],
             width: ["can't be blank"],
             height: ["can't be blank"],
             unit: ["can't be blank"],
             slug: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "show layout shows the layout data and preloads engine crator assets data" do
    user = insert(:user)
    engine = insert(:engine)
    asset = insert(:asset, creator: user, organisation: user.organisation)

    layout =
      insert(:layout,
        creator: user,
        engine: engine,
        creator: user,
        organisation: user.organisation
      )

    layout_asset = insert(:layout_asset, layout: layout, asset: asset, creator: user)
    s_layout = Document.show_layout(layout.uuid, user)

    assert s_layout.name == layout.name
    assert s_layout.description == layout.description
    assert s_layout.creator.name == user.name
    assert s_layout.engine.name == engine.name
  end

  test "get layout returns the layout data by uuid" do
    user = insert(:user)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    s_layout = Document.get_layout(layout.uuid, user)
    assert s_layout.name == layout.name
    assert s_layout.description == layout.description
    assert s_layout.width == layout.width
    assert s_layout.height == layout.height
    assert s_layout.unit == layout.unit
    assert s_layout.slug == layout.slug
  end

  test "get layout asset from its layout and assets uuids" do
    user = insert(:user)
    engine = insert(:engine)
    asset = insert(:asset, creator: user, organisation: user.organisation)
    layout = insert(:layout, creator: user, engine: engine)
    layout_asset = insert(:layout_asset, layout: layout, asset: asset, creator: user)
    g_layout_asset = Document.get_layout_asset(layout.uuid, asset.uuid)
    assert layout_asset.uuid == g_layout_asset.uuid
  end

  test "update layout on valid attrs" do
    user = insert(:user)
    engine = insert(:engine)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    count_before = Layout |> Repo.all() |> length()
    params = Map.put(@valid_layout_attrs, "engine_uuid", engine.uuid)

    layout = Document.update_layout(layout, user, params)
    count_after = Layout |> Repo.all() |> length()
    assert count_before == count_after
    assert layout.name == @valid_layout_attrs["name"]
    assert layout.description == @valid_layout_attrs["description"]
    assert layout.width == @valid_layout_attrs["width"]
    assert layout.height == @valid_layout_attrs["height"]
    assert layout.unit == @valid_layout_attrs["unit"]
    assert layout.slug == @valid_layout_attrs["slug"]
  end

  test "update layout on invalid attrs" do
    user = insert(:user)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    count_before = Layout |> Repo.all() |> length()

    {:error, changeset} = Document.update_layout(layout, user, @invalid_attrs)
    count_after = Layout |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             engine_id: ["can't be blank"],
             slug: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "delete layout deletes the layout and returns its data" do
    user = insert(:user)
    layout = insert(:layout)
    count_before = Layout |> Repo.all() |> length()
    {:ok, model} = Document.delete_layout(layout, user)
    count_after = Layout |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert model.name == layout.name
    assert model.description == layout.description
    assert model.width == layout.width
    assert model.height == layout.height
    assert model.unit == layout.unit
    assert model.slug == layout.slug
  end

  test "delete layout asset deletes a layouts asset and returns the data" do
    user = insert(:user)
    layout = insert(:layout)
    asset = insert(:asset)
    layout_asset = insert(:layout_asset, layout: layout, asset: asset, creator: user)
    count_before = LayoutAsset |> Repo.all() |> length()
    {:ok, l_asset} = Document.delete_layout_asset(layout_asset, user)
    count_after = LayoutAsset |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert l_asset.asset.name == asset.name
  end

  test "layout index returns the list of layouts" do
    user = insert(:user)
    engine = insert(:engine)
    l1 = insert(:layout, creator: user, organisation: user.organisation, engine: engine)
    l2 = insert(:layout, creator: user, organisation: user.organisation, engine: engine)
    layout_index = Document.layout_index(user, %{page_number: 1})

    assert layout_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ l1.name
    assert layout_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ l2.name
  end

  # test "layout file upload with slug file uploads a file to slug" do
  #   user = insert(:user)
  #   layout = insert(:layout, creator: user)

  #   params = %{
  #     "slug_file" => %Plug.Upload{path: "test/fixtures/example.png", filename: "example.png"}
  #   }

  #   u_layout = Document.layout_files_upload(layout, params)
  #   assert u_layout.slug_file.filename == "example.png"
  # end

  # test "layout file upload with screen shot files upload a file as screenshot" do
  #   user = insert(:user)
  #   layout = insert(:layout, creator: user)

  #   params = %{
  #     "screenshot" => %Plug.Upload{path: "test/fixtures/example.png", filename: "example.png"}
  #   }

  #   u_layout = Document.layout_files_upload(layout, params)
  #   assert u_layout.screenshot.filename == "example.png"
  # end

  test "create content_type on valid attributes" do
    user = insert(:user)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)

    fields = [
      insert(:content_type_field, content_type: content_type),
      insert(:content_type_field, content_type: content_type)
    ]

    flow = insert(:flow, creator: user, organisation: user.organisation)
    param = Map.put(@valid_content_type_attrs, "fields", fields)
    count_before = ContentType |> Repo.all() |> length()
    content_type = Document.create_content_type(user, layout, flow, @valid_content_type_attrs)
    count_after = ContentType |> Repo.all() |> length()
    assert count_before + 1 == count_after
    assert content_type.name == @valid_content_type_attrs["name"]
    assert content_type.description == @valid_content_type_attrs["description"]
    assert content_type.color == @valid_content_type_attrs["color"]
    assert content_type.prefix == @valid_content_type_attrs["prefix"]
  end

  test "create content_type on invalid attrs" do
    user = insert(:user)
    layout = insert(:layout, creator: user)
    flow = insert(:flow, creator: user)
    count_before = ContentType |> Repo.all() |> length()

    {:error, changeset} = Document.create_content_type(user, layout, flow, @invalid_attrs)
    count_after = ContentType |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             name: ["can't be blank"],
             description: ["can't be blank"],
             prefix: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "content_type index lists the content_type data" do
    user = insert(:user)
    c1 = insert(:content_type, creator: user, organisation: user.organisation)
    c2 = insert(:content_type, creator: user, organisation: user.organisation)
    content_type_index = Document.content_type_index(user, %{page_number: 1})

    assert content_type_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~
             c1.name

    assert content_type_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~
             c2.name
  end

  test "show content_type shows the content_type data" do
    user = insert(:user)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    flow = insert(:flow, creator: user, organisation: user.organisation)
    state_1 = insert(:state, flow: flow)
    state_2 = insert(:state, flow: flow)
    field_type = insert(:field_type)

    content_type =
      insert(:content_type,
        creator: user,
        layout: layout,
        flow: flow,
        organisation: user.organisation
      )

    content_type =
      insert(:content_type,
        organisation: user.organisation,
        creator: user,
        layout: layout,
        flow: flow
      )

    s_content_type = Document.show_content_type(user, content_type.uuid)
    assert s_content_type.name == content_type.name
    assert s_content_type.description == content_type.description
    assert s_content_type.color == content_type.color
    assert s_content_type.prefix == content_type.prefix
    assert s_content_type.layout.name == layout.name
  end

  test "get content_type shows the content_type data" do
    user = insert(:user)

    content_type = insert(:content_type, organisation: user.organisation)
    s_content_type = Document.get_content_type(user, content_type.uuid)

    assert s_content_type.name == content_type.name
    assert s_content_type.description == content_type.description
    assert s_content_type.color == content_type.color
    assert s_content_type.prefix == content_type.prefix
  end

  test "update content_type on valid attrs" do
    user = insert(:user)
    layout = insert(:layout, creator: user, organisation: user.organisation)
    flow = insert(:flow, creator: user, organisation: user.organisation)

    content_type =
      insert(:content_type,
        creator: user,
        layout: layout,
        flow: flow,
        organisation: user.organisation
      )

    count_before = ContentType |> Repo.all() |> length()

    params =
      Map.merge(@valid_content_type_attrs, %{
        "flow_uuid" => flow.uuid,
        "layout_uuid" => layout.uuid,
        "fields" => [
          insert(:content_type_field, content_type: content_type),
          insert(:content_type_field, content_type: content_type)
        ]
      })

    content_type = Document.update_content_type(content_type, user, params)
    count_after = ContentType |> Repo.all() |> length()
    assert count_before == count_after
    assert content_type.name == @valid_content_type_attrs["name"]
    assert content_type.description == @valid_content_type_attrs["description"]
    assert content_type.color == @valid_content_type_attrs["color"]
    assert content_type.prefix == @valid_content_type_attrs["prefix"]
  end

  test "update content_type on invalid attrs" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    count_before = ContentType |> Repo.all() |> length()
    params = @invalid_attrs |> Map.merge(%{name: "", description: "", prefix: ""})
    {:error, changeset} = Document.update_content_type(content_type, user, params)
    count_after = ContentType |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             name: ["can't be blank"],
             description: ["can't be blank"],
             prefix: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "delete content_type deletes the content_type data" do
    user = insert(:user)
    content_type = insert(:content_type)
    count_before = ContentType |> Repo.all() |> length()
    {:ok, s_content_type} = Document.delete_content_type(content_type, user)
    count_after = ContentType |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert s_content_type.name == content_type.name
    assert s_content_type.description == content_type.description
    assert s_content_type.color == content_type.color
    assert s_content_type.prefix == content_type.prefix
  end

  test "create instance on valid attributes and updates count of instances at counter" do
    user = insert(:user)
    content_type = insert(:content_type)
    flow = content_type.flow
    state = insert(:state, flow: flow)
    counter_count = Counter |> Repo.all() |> length()
    count_before = Instance |> Repo.all() |> length()
    instance = Document.create_instance(user, content_type, state, @valid_instance_attrs)

    count_after = Instance |> Repo.all() |> length()
    counter_count_after = Counter |> Repo.all() |> length()
    assert count_before + 1 == count_after
    assert counter_count + 1 == counter_count_after
    assert instance.raw == @valid_instance_attrs["raw"]
    assert instance.serialized == @valid_instance_attrs["serialized"]
  end

  test "create instance on invalid attrs" do
    user = insert(:user)
    count_before = Instance |> Repo.all() |> length()
    content_type = insert(:content_type)
    state = insert(:state, flow: content_type.flow)

    {:error, changeset} = Document.create_instance(user, content_type, state, @invalid_attrs)

    count_after = Instance |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             raw: ["can't be blank"],
             type: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "instance index lists the instance data" do
    user = insert(:user)
    content_type = insert(:content_type)
    i1 = insert(:instance, creator: user, content_type: content_type)
    i2 = insert(:instance, creator: user, content_type: content_type)
    instance_index = Document.instance_index(content_type.uuid, %{page_number: 1})

    assert instance_index.entries |> Enum.map(fn x -> x.raw end) |> List.to_string() =~
             i1.raw

    assert instance_index.entries |> Enum.map(fn x -> x.raw end) |> List.to_string() =~ i2.raw
  end

  test "instance index of an organisation lists instances under an organisation" do
    user = insert(:user)
    i1 = insert(:instance, creator: user)
    i2 = insert(:instance, creator: user)

    instance_index_under_organisation =
      Document.instance_index_of_an_organisation(user, %{page_number: 1})

    assert instance_index_under_organisation.entries
           |> Enum.map(fn x -> x.instance_id end)
           |> List.to_string() =~
             i1.instance_id

    assert instance_index_under_organisation.entries
           |> Enum.map(fn x -> x.raw end)
           |> List.to_string() =~ i2.raw
  end

  test "get instance shows the instance data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)
    instance = insert(:instance, creator: user, content_type: content_type)
    i_instance = Document.get_instance(instance.uuid, user)
    assert i_instance.instance_id == instance.instance_id
    assert i_instance.raw == instance.raw
  end

  test "show instance shows and preloads creator content thype layout and state instance data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)
    flow = content_type.flow
    state = insert(:state, flow: flow, organisation: user.organisation)
    instance = insert(:instance, creator: user, content_type: content_type, state: state)

    i_instance = Document.show_instance(instance.uuid, user)
    assert i_instance.instance_id == instance.instance_id
    assert i_instance.raw == instance.raw

    assert i_instance.creator.name == user.name
    assert i_instance.content_type.name == content_type.name
    assert i_instance.state.state == state.state
  end

  test "update instance on valid attrs and add a version data" do
    user = insert(:user)

    instance = insert(:instance, creator: user)
    count_before = Instance |> Repo.all() |> length()
    version_count_before = Version |> Repo.all() |> length()
    instance = Document.update_instance(instance, user, @valid_instance_attrs)
    version_count_after = Version |> Repo.all() |> length()
    count_after = Instance |> Repo.all() |> length()
    assert count_before == count_after
    assert version_count_before + 1 == version_count_after
    assert instance.instance_id == @valid_instance_attrs["instance_id"]
    assert instance.raw == @valid_instance_attrs["raw"]
    assert instance.serialized == @valid_instance_attrs["serialized"]
  end

  @invalid_instance_attrs %{raw: nil}
  test "update instance on invalid attrs" do
    user = insert(:user)

    instance = insert(:instance, creator: user)
    count_before = Instance |> Repo.all() |> length()

    {:error, changeset} = Document.update_instance(instance, user, @invalid_instance_attrs)

    count_after = Instance |> Repo.all() |> length()
    assert count_before == count_after

    assert %{raw: ["can't be blank"]} ==
             errors_on(changeset)
  end

  test "update instance state updates state of an instance to new state" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    pre_state = insert(:state, flow: content_type.flow)
    post_state = insert(:state, flow: content_type.flow)
    instance = insert(:instance, creator: user, content_type: content_type, state: pre_state)

    instance = Document.update_instance_state(user, instance, post_state)

    assert instance.state_id == post_state.id
  end

  describe "data_template_bulk_insert/4" do
    test "test bulk data template creation with valid data" do
      c_type = insert(:content_type)
      user = insert(:user)
      mapping = %{"Title" => "title", "TitleTemplate" => "title_template", "Data" => "data"}
      path = "test/helper/data_template_source.csv"
      count_before = DataTemplate |> Repo.all() |> length()

      data_templates =
        Document.data_template_bulk_insert(user, c_type, mapping, path)
        |> Enum.map(fn {:ok, x} -> x.title end)
        |> List.to_string()

      assert count_before + 3 == DataTemplate |> Repo.all() |> length()
      assert data_templates =~ "Title1"
      assert data_templates =~ "Title2"
      assert data_templates =~ "Title3"
    end

    test "test does not do bulk data template creation with invalid data" do
      count_before = DataTemplate |> Repo.all() |> length()
      response = Document.data_template_bulk_insert(nil, nil, nil, nil)
      assert count_before == DataTemplate |> Repo.all() |> length()
      assert response == {:error, :not_found}
    end
  end

  describe "create_data_template/3" do
    test "test creates data template with valid attrs" do
      user = insert(:user)
      c_type = insert(:content_type)

      params = %{
        title: "Offer letter tempalate",
        title_template: "Hi [employee], we welcome you to our [company], [address]",
        data: "Hi [employee], we welcome you to our [company], [address]"
      }

      count_before = DataTemplate |> Repo.all() |> length()
      {:ok, data_template} = Document.create_data_template(user, c_type, params)

      assert count_before + 1 == DataTemplate |> Repo.all() |> length()
      assert data_template.title == "Offer letter tempalate"

      assert data_template.title_template ==
               "Hi [employee], we welcome you to our [company], [address]"

      assert data_template.data == "Hi [employee], we welcome you to our [company], [address]"
    end

    test "test does not create data template with invalid attrs" do
      user = insert(:user)
      c_type = insert(:content_type)
      {:error, changeset} = Document.create_data_template(user, c_type, %{})

      assert %{
               title: ["can't be blank"],
               title_template: ["can't be blank"],
               data: ["can't be blank"]
             } ==
               errors_on(changeset)
    end
  end

  describe "block_template_bulk_insert/3" do
    test "test bulk block template creation with valid data" do
      user = insert(:user)
      mapping = %{"Body" => "body", "Serialised" => "serialised", "Title" => "title"}
      path = "test/helper/block_template_source.csv"
      count_before = BlockTemplate |> Repo.all() |> length()

      block_templates =
        Document.block_template_bulk_insert(user, mapping, path)
        |> Enum.map(fn x -> x.title end)
        |> List.to_string()

      assert count_before + 3 == BlockTemplate |> Repo.all() |> length()
      assert block_templates =~ "B Temp1"
      assert block_templates =~ "B Temp2"
      assert block_templates =~ "B Temp3"
    end

    test "test doesn not do bulk block template creation with invalid data" do
      count_before = BlockTemplate |> Repo.all() |> length()
      response = Document.block_template_bulk_insert(nil, nil, nil)
      assert count_before == BlockTemplate |> Repo.all() |> length()
      assert response == {:error, :not_found}
    end
  end

  describe "create_block_template/2" do
    test "test creates block template with valid attrs" do
      user = insert(:user)

      params = %{
        title: "Introduction",
        body: "Hi [employee], we welcome you to our [company], [address]",
        serialised: "Hi [employee], we welcome you to our family"
      }

      count_before = BlockTemplate |> Repo.all() |> length()
      block_template = Document.create_block_template(user, params)

      assert count_before + 1 == BlockTemplate |> Repo.all() |> length()
      assert block_template.title == "Introduction"
      assert block_template.body == "Hi [employee], we welcome you to our [company], [address]"
      assert block_template.serialised == "Hi [employee], we welcome you to our family"
    end

    test "test does not create block template with invalid attrs" do
      user = insert(:user)
      {:error, changeset} = Document.create_block_template(user, %{})

      assert %{
               title: ["can't be blank"],
               serialised: ["can't be blank"],
               body: ["can't be blank"]
             } == errors_on(changeset)
    end
  end

  describe "insert_bulk_build_work/6" do
    test "test creates bulk build backgroung job with valid attrs" do
      user = insert(:user)
      %{uuid: c_type_id} = insert(:content_type)
      %{uuid: state_id} = insert(:state)
      %{uuid: d_temp_id} = insert(:data_template)
      mapping = %{test: "map"}
      file = Plug.Upload.random_file!("test")
      tmp_file_source = "temp/bulk_build_source/" <> file
      count_before = Oban.Job |> Repo.all() |> length()

      {:ok, job} =
        Document.insert_bulk_build_work(
          user,
          c_type_id,
          state_id,
          d_temp_id,
          mapping,
          %Plug.Upload{filename: file, path: file}
        )

      assert count_before + 1 == Oban.Job |> Repo.all() |> length()

      assert job.args == %{
               c_type_uuid: c_type_id,
               state_uuid: state_id,
               d_temp_uuid: d_temp_id,
               mapping: mapping,
               user_uuid: user.uuid,
               file: tmp_file_source
             }
    end

    test "does not create bulk build backgroung job with invalid attrs" do
      response = Document.insert_bulk_build_work(nil, nil, nil, nil, nil, nil)
      assert response == nil
    end
  end

  describe "insert_data_template_bulk_import_work/4" do
    test "test creates bulk import data template backgroung job with valid attrs" do
      %{uuid: user_id} = insert(:user)
      %{uuid: c_type_id} = insert(:content_type)
      mapping = %{test: "map"}
      file = Plug.Upload.random_file!("test")
      tmp_file_source = "temp/bulk_import_source/d_template/" <> file
      count_before = Oban.Job |> Repo.all() |> length()

      {:ok, job} =
        Document.insert_data_template_bulk_import_work(user_id, c_type_id, mapping, %Plug.Upload{
          filename: file,
          path: file
        })

      assert count_before + 1 == Oban.Job |> Repo.all() |> length()

      assert job.args == %{
               user_uuid: user_id,
               c_type_uuid: c_type_id,
               mapping: mapping,
               file: tmp_file_source
             }
    end

    test "does not create bulk import data template backgroung job with invalid attrs" do
      response = Document.insert_data_template_bulk_import_work(nil, nil, nil, nil)
      assert response == nil
    end
  end

  describe "insert_block_template_bulk_import_work/3" do
    test "test creates bulk import block template backgroung job with valid attrs" do
      %{uuid: user_id} = insert(:user)
      mapping = %{test: "map"}
      file = Plug.Upload.random_file!("test")
      tmp_file_source = "temp/bulk_import_source/b_template/" <> file
      count_before = Oban.Job |> Repo.all() |> length()

      {:ok, job} =
        Document.insert_block_template_bulk_import_work(user_id, mapping, %Plug.Upload{
          filename: file,
          path: file
        })

      assert count_before + 1 == Oban.Job |> Repo.all() |> length()
      assert job.args == %{user_uuid: user_id, mapping: mapping, file: tmp_file_source}
    end

    test "does not create bulk import block template backgroung job with invalid attrs" do
      response = Document.insert_block_template_bulk_import_work(nil, nil, nil)
      assert response == nil
    end
  end

  describe "create_pipeline/2" do
    test "creates pipeline with valid attrs" do
      user = insert(:user)
      c_type = insert(:content_type, organisation: user.organisation)
      d_temp = insert(:data_template, content_type: c_type)
      state = insert(:state, organisation: user.organisation)

      attrs = %{
        "name" => "pipeline",
        "api_route" => "www.crm.com",
        "organisation_id" => user.organisation_id,
        "stages" => [
          %{
            "state_id" => state.uuid,
            "content_type_id" => c_type.uuid,
            "data_template_id" => d_temp.uuid
          }
        ]
      }

      pipeline = Document.create_pipeline(user, attrs)

      [%{content_type: content_type, data_template: data_template, state: resp_state}] =
        pipeline.stages

      assert pipeline.name == "pipeline"
      assert pipeline.api_route == "www.crm.com"
      assert content_type.name == c_type.name
      assert data_template.title == d_temp.title
      assert resp_state.state == state.state
    end

    test "returns error with invalid attrs" do
      user = insert(:user)
      {:error, changeset} = Document.create_pipeline(user, %{})
      assert %{name: ["can't be blank"], api_route: ["can't be blank"]} == errors_on(changeset)
    end
  end

  describe "pipeline_index/2" do
    test "returns list of pipelines in the users organisation only" do
      user = insert(:user)
      pipeline1 = insert(:pipeline, organisation: user.organisation)
      pipeline2 = insert(:pipeline)
      %{entries: pipelines} = Document.pipeline_index(user, %{})
      pipeline_names = pipelines |> Enum.map(fn x -> x.name end) |> List.to_string()
      assert pipeline_names =~ pipeline1.name
      refute pipeline_names =~ pipeline2.name
    end

    test "returns nil with invalid attrs" do
      response = Document.pipeline_index(nil, %{})
      assert response == nil
    end
  end

  describe "get_pipeline/2" do
    test "returns the pipeline in the user's organisation with given id" do
      user = insert(:user)
      pipe = insert(:pipeline, organisation: user.organisation)
      pipeline = Document.get_pipeline(user, pipe.uuid)
      assert pipeline.name == pipe.name
      assert pipeline.uuid == pipe.uuid
    end

    test "returns nil when pipeline does not belong to the user's organisation" do
      user = insert(:user)
      pipeline = insert(:pipeline)
      response = Document.get_pipeline(user, pipeline.uuid)
      assert response == nil
    end

    test "returns nil for non existent pipeline" do
      user = insert(:user)
      response = Document.get_pipeline(user, Ecto.UUID.generate())
      assert response == nil
    end

    test "returns nil for invalid data" do
      response = Document.get_pipeline(nil, Ecto.UUID.generate())
      assert response == nil
    end
  end

  describe "show_pipeline/2" do
    test "returns the pipeline in the user's organisation with given id" do
      user = insert(:user)
      pipe = insert(:pipeline, organisation: user.organisation)
      pipeline = Document.show_pipeline(user, pipe.uuid)
      assert pipeline.name == pipe.name
      assert pipeline.uuid == pipe.uuid
    end

    test "returns nil when pipeline does not belong to the user's organisation" do
      user = insert(:user)
      pipeline = insert(:pipeline)
      response = Document.show_pipeline(user, pipeline.uuid)
      assert response == nil
    end

    test "returns nil for non existent pipeline" do
      user = insert(:user)
      response = Document.show_pipeline(user, Ecto.UUID.generate())
      assert response == nil
    end

    test "returns nil for invalid data" do
      response = Document.show_pipeline(nil, Ecto.UUID.generate())
      assert response == nil
    end
  end

  describe "pipeline_update/3" do
    test "updates pipeline with valid attrs" do
      user = insert(:user)
      pipeline = insert(:pipeline)
      c_type = insert(:content_type, organisation: user.organisation)
      d_temp = insert(:data_template, content_type: c_type)
      state = insert(:state, organisation: user.organisation)

      attrs = %{
        "name" => "pipeline",
        "api_route" => "www.crm.com",
        "stages" => [
          %{
            "content_type_id" => c_type.uuid,
            "data_template_id" => d_temp.uuid,
            "state_id" => state.uuid
          }
        ]
      }

      pipeline = Document.pipeline_update(pipeline, user, attrs)
      [stage] = pipeline.stages
      assert pipeline.name == "pipeline"
      assert pipeline.api_route == "www.crm.com"
      assert stage.content_type.name == c_type.name
      assert stage.data_template.title == d_temp.title
      assert stage.state.state == state.state
    end

    test "returns error with invalid attrs" do
      user = insert(:user)
      {:error, changeset} = Document.create_pipeline(user, %{})
      assert %{name: ["can't be blank"], api_route: ["can't be blank"]} == errors_on(changeset)
    end
  end

  describe "delete_pipeline/2" do
    test "deletes pipeline with correct data" do
      user = insert(:user)
      pipeline = insert(:pipeline)
      count_before = Pipeline |> Repo.all() |> length()
      {:ok, deleted_pipeline} = Document.delete_pipeline(pipeline, user)
      count_after = Pipeline |> Repo.all() |> length()
      assert count_before - 1 == count_after
      assert deleted_pipeline.name == pipeline.name
      assert deleted_pipeline.api_route == pipeline.api_route
    end

    test "returns nil with invalid data" do
      response = Document.delete_pipeline(nil, nil)
      assert response == nil
    end
  end

  describe "get_pipe_stage/2" do
    test "returns the pipe stage in the user's organisation with valid IDs and user struct" do
      user = insert(:user)
      pipeline = insert(:pipeline, organisation: user.organisation)
      stage = insert(:pipe_stage, pipeline: pipeline)
      response = Document.get_pipe_stage(user, stage.uuid)
      assert response.pipeline_id == pipeline.id
      assert response.uuid == stage.uuid
    end

    test "returns nil when stage does not belong to user's organisation" do
      user = insert(:user)
      stage = insert(:pipe_stage)
      response = Document.get_pipe_stage(user, stage.uuid)
      assert response == nil
    end

    test "returns nil with non-existent IDs" do
      user = insert(:user)
      response = Document.get_pipe_stage(user, Ecto.UUID.generate())
      assert response == nil
    end

    test "returns nil invalid data" do
      response = Document.get_pipe_stage(nil, Ecto.UUID.generate())
      assert response == nil
    end
  end

  describe "delete_pipe_stage/2" do
    test "deletes stage with correct data" do
      user = insert(:user)
      stage = insert(:pipe_stage)
      count_before = Stage |> Repo.all() |> length()
      {:ok, deleted_stage} = Document.delete_pipe_stage(user, stage)
      count_after = Stage |> Repo.all() |> length()
      assert count_before - 1 == count_after
      assert deleted_stage.pipeline_id == stage.pipeline_id
      assert deleted_stage.content_type_id == stage.content_type_id
    end

    test "returns nil with invalid data" do
      response = Document.delete_pipe_stage(nil, nil)
      assert response == nil
    end
  end

  test "get content type field returns content type field data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)
    content_type_field = insert(:content_type_field, content_type: content_type)
    c_content_type_field = Document.get_content_type_field(content_type_field.uuid, user)
    assert content_type_field.name == c_content_type_field.name
    assert content_type_field.description == c_content_type_field.description
  end

  test "delete content type field deletes the content type field and returns the data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)

    content_type_field = insert(:content_type_field, content_type: content_type)
    {:ok, c_content_type_field} = Document.delete_content_type_field(content_type_field, user)
    assert content_type_field.name == c_content_type_field.name
    assert content_type_field.description == c_content_type_field.description
  end

  describe "create_or_update_counter/1" do
    test "create a row while creating an instance and write the count of instance under a content type" do
      content_type = insert(:content_type)
      {:ok, counter} = Document.create_or_update_counter(content_type)
      assert counter.count == 1
    end

    test "update counter while adding an instance on existing content type and write total count of instances under a content type" do
      content_type = insert(:content_type)

      counter = insert(:counter, subject: "ContentType:#{content_type.id}")

      {:ok, n_counter} = Document.create_or_update_counter(content_type)
      assert counter.count + 1 == n_counter.count
    end
  end

  test "get engine returns the engine data" do
    engine = insert(:engine)
    e_engine = Document.get_engine(engine.uuid)
    assert engine.name == e_engine.name
    assert engine.api_route == e_engine.api_route
  end

  @valid_theme_attrs %{
    "name" => "theme name",
    "font" => "theme font",
    "typescale" => %{"heading1" => 22, "heading2" => 16, "paragraph" => 12}
  }

  test "create theme on valid attributes" do
    user = insert(:user)
    count_before = Theme |> Repo.all() |> length()
    {:ok, theme} = Document.create_theme(user, @valid_theme_attrs)
    count_after = Theme |> Repo.all() |> length()
    count_before + 1 == count_after
    assert theme.name == @valid_theme_attrs["name"]
    assert theme.font == @valid_theme_attrs["font"]
    assert theme.typescale == @valid_theme_attrs["typescale"]
  end

  test "create theme on invalid attrs" do
    user = insert(:user)
    count_before = Theme |> Repo.all() |> length()

    {:error, changeset} = Document.create_theme(user, @invalid_attrs)
    count_after = Theme |> Repo.all() |> length()
    assert count_before == count_after

    assert %{name: ["can't be blank"], font: ["can't be blank"]} ==
             errors_on(changeset)
  end

  test "theme index lists the theme data" do
    user = insert(:user)
    t1 = insert(:theme, creator: user, organisation: user.organisation)
    t2 = insert(:theme, creator: user, organisation: user.organisation)
    theme_index = Document.theme_index(user, %{page_number: 1})

    assert theme_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ t1.name
    assert theme_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ t2.name
  end

  test "get theme returns the theme data" do
    user = insert(:user)
    theme = insert(:theme, creator: user, organisation: user.organisation)
    t_theme = Document.get_theme(theme.uuid, user)
    assert t_theme.name == theme.name
    assert t_theme.font == theme.font
  end

  test "show theme returns the theme data and preloads the creator" do
    user = insert(:user)
    theme = insert(:theme, creator: user, organisation: user.organisation)
    t_theme = Document.show_theme(theme.uuid, user)
    assert t_theme.name == theme.name
    assert t_theme.font == theme.font

    assert t_theme.creator.name == user.name
  end

  # test "update theme on valid attrs" do
  #   user = insert(:user)
  #   theme = insert(:theme, creator: user)
  #   count_before = Theme |> Repo.all() |> length()

  #   {:ok, theme} = Document.update_theme(theme, user, @valid_theme_attrs)
  #   count_after = Theme |> Repo.all() |> length()
  #   assert count_before == count_after
  #   assert theme.name == @valid_theme_attrs["name"]
  #   assert theme.font == @valid_theme_attrs["font"]
  #   assert theme.typescale == @valid_theme_attrs["typescale"]
  # end

  test "update theme on invalid attrs" do
    user = insert(:user)
    theme = insert(:theme, creator: user)
    count_before = Theme |> Repo.all() |> length()

    {:error, changeset} = Document.update_theme(theme, user, @invalid_attrs)
    count_after = Theme |> Repo.all() |> length()
    assert count_before == count_after

    %{name: ["can't be blank"], font: ["can't be blank"], typescale: ["can't be blank"]} ==
      errors_on(changeset)
  end

  test "delete theme deletes and return the theme data" do
    user = insert(:user)
    theme = insert(:theme)
    count_before = Theme |> Repo.all() |> length()
    {:ok, t_theme} = Document.delete_theme(theme, user)
    count_after = Theme |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert t_theme.name == theme.name
    assert t_theme.font == theme.font
    assert t_theme.typescale == theme.typescale
  end

  @valid_data_template_attrs %{
    "title" => "data_template title",
    "title_template" => "data_template title_template",
    "data" => "data_template data"
  }
  @invalid_data_template_attrs %{title: nil, title_template: nil, data: nil}
  test "create data_template on valid attributes" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    count_before = DataTemplate |> Repo.all() |> length()

    {:ok, data_template} =
      Document.create_data_template(user, content_type, @valid_data_template_attrs)

    count_after = DataTemplate |> Repo.all() |> length()
    count_before + 1 == count_after
    assert data_template.title == @valid_data_template_attrs["title"]
    assert data_template.title_template == @valid_data_template_attrs["title_template"]
    assert data_template.data == @valid_data_template_attrs["data"]
  end

  test "create data_template on invalid attrs" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    count_before = DataTemplate |> Repo.all() |> length()

    {:error, changeset} = Document.create_data_template(user, content_type, @invalid_attrs)
    count_after = DataTemplate |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             title: ["can't be blank"],
             title_template: ["can't be blank"],
             data: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "data_template index lists the data_template data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    d1 = insert(:data_template, creator: user, content_type: content_type)
    d2 = insert(:data_template, creator: user, content_type: content_type)
    data_template_index = Document.data_template_index(content_type.uuid, %{page_number: 1})

    assert data_template_index.entries |> Enum.map(fn x -> x.title end) |> List.to_string() =~
             d1.title

    assert data_template_index.entries |> Enum.map(fn x -> x.title end) |> List.to_string() =~
             d2.title
  end

  test "data_template index_under_organisation lists the data_template data under an organisation" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user)
    d1 = insert(:data_template, creator: user, content_type: content_type)
    d2 = insert(:data_template, creator: user, content_type: content_type)

    data_template_index =
      Document.data_templates_index_of_an_organisation(user, %{page_number: 1})

    assert data_template_index.entries |> Enum.map(fn x -> x.title end) |> List.to_string() =~
             d1.title

    assert data_template_index.entries |> Enum.map(fn x -> x.title end) |> List.to_string() =~
             d2.title
  end

  test "get data_template returns the data_template data" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)

    data_template = insert(:data_template, creator: user, content_type: content_type)
    d_data_template = Document.get_d_template(user, data_template.uuid)
    assert d_data_template.title == data_template.title
    assert d_data_template.title_template == data_template.title_template
    assert d_data_template.data == data_template.data
  end

  test "show data_template returns the data_template data and preloads creator and content type" do
    user = insert(:user)
    content_type = insert(:content_type, creator: user, organisation: user.organisation)
    data_template = insert(:data_template, creator: user, content_type: content_type)
    d_data_template = Document.show_d_template(user, data_template.uuid)
    assert d_data_template.title == data_template.title
    assert d_data_template.title_template == data_template.title_template
    assert d_data_template.data == data_template.data
    assert d_data_template.content_type.name == content_type.name
    assert d_data_template.creator.name == user.name
  end

  test "update data_template on valid attrs" do
    user = insert(:user)
    data_template = insert(:data_template, creator: user)
    count_before = DataTemplate |> Repo.all() |> length()

    data_template = Document.update_data_template(data_template, user, @valid_data_template_attrs)
    count_after = DataTemplate |> Repo.all() |> length()
    assert count_before == count_after
    assert data_template.title == @valid_data_template_attrs["title"]
    assert data_template.title_template == @valid_data_template_attrs["title_template"]
    assert data_template.data == @valid_data_template_attrs["data"]
  end

  test "update data_template on invalid attrs" do
    user = insert(:user)
    data_template = insert(:data_template, creator: user)
    count_before = DataTemplate |> Repo.all() |> length()

    {:error, changeset} =
      Document.update_data_template(data_template, user, @invalid_data_template_attrs)

    count_after = DataTemplate |> Repo.all() |> length()
    assert count_before == count_after

    %{title: ["can't be blank"], title_template: ["can't be blank"], data: ["can't be blank"]} ==
      errors_on(changeset)
  end

  test "delete data_template deletes the data_template data" do
    user = insert(:user)
    data_template = insert(:data_template, creator: user)
    count_before = DataTemplate |> Repo.all() |> length()
    {:ok, d_data_template} = Document.delete_data_template(data_template, user)
    count_after = DataTemplate |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert d_data_template.title == data_template.title
    assert d_data_template.title_template == data_template.title_template
    assert d_data_template.data == data_template.data
  end

  @valid_asset_attrs %{"name" => "asset name"}
  test "create asset on valid attributes" do
    user = insert(:user)
    organisation = user.organisation
    params = Map.put(@valid_asset_attrs, "organisation_id", organisation.id)
    count_before = Asset |> Repo.all() |> length()
    {:ok, asset} = Document.create_asset(user, @valid_asset_attrs)
    count_after = Asset |> Repo.all() |> length()
    count_before + 1 == count_after
    assert asset.name == @valid_asset_attrs["name"]
  end

  test "create asset on invalid attrs" do
    user = insert(:user)
    count_before = Asset |> Repo.all() |> length()

    {:error, changeset} = Document.create_asset(user, @invalid_attrs)
    count_after = Asset |> Repo.all() |> length()
    assert count_before == count_after
    assert %{name: ["can't be blank"]} == errors_on(changeset)
  end

  test "asset index lists the asset data" do
    user = insert(:user)
    organisation = user.organisation
    a1 = insert(:asset, creator: user, organisation: organisation)
    a2 = insert(:asset, creator: user, organisation: organisation)
    asset_index = Document.asset_index(organisation.id, %{page_number: 1})

    assert asset_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ a1.name
    assert asset_index.entries |> Enum.map(fn x -> x.name end) |> List.to_string() =~ a2.name
  end

  test "get asset returns the asset data" do
    user = insert(:user)
    asset = insert(:asset, creator: user, organisation: user.organisation)
    a_asset = Document.get_asset(asset.uuid, user)
    assert a_asset.name == asset.name
  end

  test "show asset returns the asset data and preloads" do
    user = insert(:user)
    asset = insert(:asset, creator: user, organisation: user.organisation)
    a_asset = Document.show_asset(asset.uuid, user)
    assert a_asset.name == asset.name
    assert a_asset.creator.name == user.name
  end

  # test "update asset on valid attrs" do
  #   user = insert(:user)
  #   asset = insert(:asset, creator: user)
  #   count_before = Asset |> Repo.all() |> length()

  #   asset = Document.update_asset(asset, user, @valid_asset_attrs)
  #   count_after = Asset |> Repo.all() |> length()
  #   assert count_before == count_after
  #   assert asset.name == @valid_asset_attrs["name"]
  # end

  test "update asset on invalid attrs" do
    user = insert(:user)
    asset = insert(:asset, creator: user)
    count_before = Asset |> Repo.all() |> length()

    {:error, changeset} = Document.update_asset(asset, user, @invalid_attrs)
    count_after = Asset |> Repo.all() |> length()
    assert count_before == count_after
    %{name: ["can't be blank"]} == errors_on(changeset)
  end

  test "delete asset deletes the asset data" do
    user = insert(:user)
    asset = insert(:asset, creator: user)
    count_before = Asset |> Repo.all() |> length()
    {:ok, a_asset} = Document.delete_asset(asset, user)
    count_after = Asset |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert a_asset.name == asset.name
  end

  @valid_comment_attrs %{
    "comment" => "comment comment",
    "is_parent" => true,
    "master" => "instance",
    "master_id" => "0s3df0sd03f3s03d0f3",
    "organisation_id" => 12
  }
  test "create comment on valid attributes" do
    user = insert(:user)
    organisation = user.organisation
    instance = insert(:instance, creator: user)

    params =
      Map.merge(@valid_comment_attrs, %{
        "master_id" => instance.uuid,
        "organisation_id" => organisation.id
      })

    count_before = Comment |> Repo.all() |> length()
    comment = Document.create_comment(user, params)
    count_after = Comment |> Repo.all() |> length()
    count_before + 1 == count_after
    assert comment.comment == @valid_comment_attrs["comment"]
    assert comment.is_parent == @valid_comment_attrs["is_parent"]
    assert comment.master == @valid_comment_attrs["master"]
    assert comment.master_id == instance.uuid
    assert comment.organisation_id == organisation.id
  end

  test "create comment on invalid attrs" do
    user = insert(:user)
    count_before = Comment |> Repo.all() |> length()

    {:error, changeset} = Document.create_comment(user, @invalid_attrs)
    count_after = Comment |> Repo.all() |> length()
    assert count_before == count_after

    assert %{
             comment: ["can't be blank"],
             is_parent: ["can't be blank"],
             master: ["can't be blank"],
             master_id: ["can't be blank"]
           } == errors_on(changeset)
  end

  test "get comment returns the comment data" do
    user = insert(:user)
    comment = insert(:comment, user: user, organisation: user.organisation)
    c_comment = Document.get_comment(comment.uuid, user)
    assert c_comment.comment == comment.comment
    assert c_comment.is_parent == comment.is_parent
    assert c_comment.master == comment.master
    assert c_comment.master_id == comment.master_id
  end

  test "show comment returns the comment data and preloads user and profile" do
    user = insert(:user)
    comment = insert(:comment, user: user, organisation: user.organisation)
    c_comment = Document.show_comment(comment.uuid, user)
    assert c_comment.comment == comment.comment
    assert c_comment.is_parent == comment.is_parent
    assert c_comment.master == comment.master
    assert c_comment.master_id == comment.master_id
    assert c_comment.user.id == user.id
  end

  @invalid_comment_attrs %{
    "comment" => nil,
    "is_parent" => nil,
    "master" => nil,
    "master_id" => nil,
    "organisation_id" => nil
  }

  test "update comment on invalid attrs" do
    user = insert(:user)
    comment = insert(:comment, user: user)
    count_before = Comment |> Repo.all() |> length()

    {:error, changeset} = Document.update_comment(comment, @invalid_comment_attrs)
    count_after = Comment |> Repo.all() |> length()
    assert count_before == count_after

    %{
      comment: ["can't be blank"],
      is_parent: ["can't be blank"],
      master: ["can't be blank"],
      master_id: ["can't be blank"]
    } == errors_on(changeset)
  end

  test "update comment on valid attrs" do
    user = insert(:user)
    organisation = user.organisation
    instance = insert(:instance, creator: user)

    params =
      Map.merge(@valid_comment_attrs, %{
        "master_id" => instance.uuid,
        "organisation_id" => organisation.id
      })

    comment = insert(:comment, user: user, master_id: instance.uuid)

    count_before = Comment |> Repo.all() |> length()

    comment = Document.update_comment(comment, params)
    count_after = Comment |> Repo.all() |> length()
    assert count_before == count_after
    assert comment.comment == @valid_comment_attrs["comment"]
    assert comment.is_parent == @valid_comment_attrs["is_parent"]
    assert comment.master == @valid_comment_attrs["master"]
    assert comment.master_id == instance.uuid
    assert comment.organisation_id == organisation.id
  end

  test "comment index lists the comment data" do
    user = insert(:user)
    instance = insert(:instance, creator: user)
    c1 = insert(:comment, user: user, organisation: user.organisation, master_id: instance.uuid)
    c2 = insert(:comment, user: user, organisation: user.organisation, master_id: instance.uuid)

    comment_index =
      Document.comment_index(user, %{"page_number" => 1, "master_id" => instance.uuid})

    assert comment_index.entries |> Enum.map(fn x -> x.comment end) |> List.to_string() =~
             c1.comment

    assert comment_index.entries |> Enum.map(fn x -> x.comment end) |> List.to_string() =~
             c2.comment
  end

  test "delete comment deletes the comment data" do
    user = insert(:user)
    comment = insert(:comment, user: user)
    count_before = Comment |> Repo.all() |> length()
    {:ok, c_comment} = Document.delete_comment(comment)
    count_after = Comment |> Repo.all() |> length()
    assert count_before - 1 == count_after
    assert c_comment.comment == comment.comment
    assert c_comment.is_parent == comment.is_parent
    assert c_comment.master == comment.master
  end
end
