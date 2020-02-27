defmodule WraftDocWeb.Api.V1.LayoutController do
  use WraftDocWeb, :controller
  use PhoenixSwagger

  action_fallback(WraftDocWeb.FallbackController)
  alias WraftDoc.{Document, Document.Layout}

  def swagger_definitions do
    %{
      LayoutRequest:
        swagger_schema do
          title("Layout Request")
          description("Create layout request.")

          properties do
            name(:string, "Layout's name", required: true)
            description(:string, "Layout's description")
            width(:float, "Width of the layout")
            height(:float, "Height of the layout")
            unit(:string, "Unit of dimensions")
            slug(:string, "Name of the slug to be used for the layout")
            engine_id(:integer, "ID of the engine selected")
          end

          example(%{
            name: "Official Letter",
            description: "An official letter",
            width: 40.0,
            height: 20.0,
            unit: "cm",
            slug: "Pandoc",
            engine_id: "1232148nb3478"
          })
        end,
      LayoutAndEngine:
        swagger_schema do
          title("Layout")
          description("Layout to be used for the generation of a document.")

          properties do
            id(:string, "The ID of the layout", required: true)
            name(:string, "Layout's name", required: true)
            description(:string, "Layout's description")
            width(:float, "Width of the layout")
            height(:float, "Height of the layout")
            unit(:string, "Unit of dimensions")
            slug(:string, "Name of the slug to be used for the layout")
            engine(Schema.ref(:Engine))
            inserted_at(:string, "When was the layout created", format: "ISO-8601")
            updated_at(:string, "When was the layout last updated", format: "ISO-8601")
          end

          example(%{
            id: "1232148nb3478",
            name: "Official Letter",
            description: "An official letter",
            width: 40.0,
            height: 20.0,
            unit: "cm",
            slug: "Pandoc",
            engine: %{
              id: "1232148nb3478",
              name: "Pandoc",
              api_route: "",
              updated_at: "2020-01-21T14:00:00Z",
              inserted_at: "2020-02-21T14:00:00Z"
            },
            updated_at: "2020-01-21T14:00:00Z",
            inserted_at: "2020-02-21T14:00:00Z"
          })
        end,
      Engine:
        swagger_schema do
          title("Render engine")
          description("A render engine to be used for document generation")

          properties do
            id(:string, "The ID of the engine", required: true)
            name(:string, "Engine's name", required: true)
            api_route(:string, "API route to be used")
            inserted_at(:string, "When was the engine inserted", format: "ISO-8601")
            updated_at(:string, "When was the engine last updated", format: "ISO-8601")
          end

          example(%{
            id: "1232148nb3478",
            name: "Pandoc",
            api_route: "",
            updated_at: "2020-01-21T14:00:00Z",
            inserted_at: "2020-02-21T14:00:00Z"
          })
        end
    }
  end

  @doc """
  Create a layout.
  """
  swagger_path :create do
    post("/layouts")
    summary("Create layout")
    description("Create layout API")

    parameters do
      layout(:body, Schema.ref(:LayoutRequest), "Layout to be created", required: true)
    end

    response(200, "Ok", Schema.ref(:LayoutAndEngine))
    response(422, "Unprocessable Entity", Schema.ref(:Error))
    response(401, "Unauthorized", Schema.ref(:Error))
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, params) do
    current_user = conn.assigns[:current_user]

    with %Layout{} = layout <- Document.create_layout(current_user, params) do
      conn
      |> render("create.json", doc_layout: layout)
    end
  end
end
