defmodule Toolshed.OneBeam do
  @moduledoc false

  @all_groups [:core, :nerves_runtime]
  @groups Application.compile_env(:toolshed, :only, @all_groups)

  defmacro __using__(_) do
    quote do
      require Toolshed.OneBeam
      Toolshed.OneBeam.include_all()
    end
  end

  defmacro include_all() do
    Path.wildcard("lib_src/**/*.ex")
    |> Enum.map(&parse/1)
    |> Enum.filter(&include_block?(&1, enabled_list()))
    |> Enum.map(&merge_namespace/1)
  end

  defp parse(path) do
    File.read!(path) |> Code.string_to_quoted!(file: path)
  end

  defp include_block?(
         {:defmodule, _, [{:__aliases__, _, [:Toolshed, group_caps | _]}, _]},
         enabled_list
       ) do
    group = big_to_small(group_caps)

    group in enabled_list
  end

  defp big_to_small(:Core), do: :core
  defp big_to_small(:NervesRuntime), do: :nerves_runtime

  defp merge_namespace({:defmodule, _, [_, [do: block]]}), do: block

  defp enabled_list() do
    to_trim = if Code.ensure_loaded?(Nerves.Runtime), do: [], else: [:nerves_runtime]

    @groups -- to_trim
  end
end
