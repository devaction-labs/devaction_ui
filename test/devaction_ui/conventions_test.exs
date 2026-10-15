defmodule DevactionUI.ConventionsTest do
  @moduledoc """
  What every component of the library promises, read off its own declarations so a new component cannot forget:
  it takes the caller's own HTML attributes (`data-*`, `aria-*`, `phx-*`) through a global `rest`, and every
  attribute a caller must give is documented.
  """
  use ExUnit.Case, async: true

  @modules for path <- Path.wildcard("lib/devaction_ui/*.ex"),
               name = path |> Path.basename(".ex") |> Macro.camelize(),
               do: Module.concat(DevactionUI, name)

  @without_rest []

  defp components do
    for module <- @modules,
        Code.ensure_loaded?(module),
        function_exported?(module, :__components__, 0),
        {name, component} <- module.__components__(),
        component.kind == :def,
        do: {module, name, component}
  end

  test "every component takes the caller's own attributes" do
    missing =
      for {module, name, component} <- components(),
          {module, name} not in @without_rest,
          not Enum.any?(component.attrs, &(&1.type == :global)),
          do: {module, name}

    assert missing == [],
           "these components have no `attr :rest, :global`: #{inspect(missing)}"
  end

  test "every module has a moduledoc that says what it is" do
    for module <- @modules, Code.ensure_loaded?(module) do
      assert {:docs_v1, _anno, _lang, _format, %{"en" => doc}, _meta, _entries} =
               Code.fetch_docs(module)

      assert String.length(doc) > 40, "#{inspect(module)} has no real moduledoc"
    end
  end

  test "every required attribute of a component is typed" do
    untyped =
      for {module, name, component} <- components(),
          attr <- component.attrs,
          attr.required,
          attr.type == :any and is_nil(attr.doc),
          do: {module, name, attr.name}

    assert untyped == [], "required `:any` attributes with no doc: #{inspect(untyped)}"
  end
end
