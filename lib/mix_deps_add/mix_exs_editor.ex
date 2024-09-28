defmodule MixDepsAdd.MixExsEditor do
  alias MixDepsAdd.MixExsEditor

  @deps_start_regex ~r/\A\s*defp deps\(*[a-z_]*\)*\s*do\z/
  @deps_end_regex ~r/\A\s*end\z/
  @dep_regex ~r/\A\s+\[?\{(.*)\}[\],]?\z/
  @square_brackets_regex ~r/\A\s+[\[\]]{1,2}\z/
  @mix_new_comments_regex ~r/\A\s+# {:dep_from_.*\z/
  @mix_comments_regex ~r/\A\s+# (.*)\z/

  defstruct results: [], before: "", deps: [], after: "", filename: "mix.exs"

  def read(filename \\ "mix.exs") do
    fixed_contents = "[line_length: 10000]"
    File.write(".formatter.exs", fixed_contents)
    Mix.Task.run("format", [filename])

    File.read!(filename)
    |> String.split("\n")
    |> Enum.filter(&!Regex.match?(@mix_comments_regex, &1)) # 移除注释，兼容平台杂乱的 mix.exs
    |> parse(filename)
  end

  def add(%{results: results, deps: deps} = state, name, version_or_path) do
    if Enum.any?(deps, &String.starts_with?(&1, ":" <> name <> ",")) do
      %{state | results: [{:name_conflict, name} | results]}
    else
      {dep, result} = format_dependency(name, version_or_path)
      %{state | deps: Enum.sort([dep | deps]), results: [result | results]}
    end
  end

  defp format_dependency(name, version: version) do
    {":#{name}, \"~> #{version}\"", {:versioned, name, version}}
  end

  defp format_dependency(name, path: path) do
    {":#{name}, path: \"#{path}\"", {:relative, name, path}}
  end

  def write(%{
        results: results,
        before: before_stuff,
        deps: deps,
        after: after_stuff,
        filename: filename
      }) do
    if success?(results) do
      deps =
        deps
        |> Enum.map(&"{#{&1}}")
        |> Enum.join(",\n      ")

      content =
        [before_stuff, "    [\n      #{deps}\n    ]", after_stuff]
        |> Enum.join("\n")

      File.write!(filename, content)
      :ok
    else
      {:error, results}
    end
  end

  def success?(results) do
    Enum.all?(results, fn
      {:versioned, _, _} -> true
      {:relative, _, _} -> true
      _ -> false
    end)
  end

  defp parse(lines, filename) do
    with dsi when is_number(dsi) <- deps_start_index(lines),
         dei when is_number(dei) <- deps_end_index(lines, dsi),
         deps_lines <-
           Enum.slice(lines, (dsi + 1)..(dei - 1)),
         deps when is_list(deps) <- parse_deps(deps_lines) do
      %MixExsEditor{
        before: Enum.slice(lines, 0..dsi) |> Enum.join("\n"),
        deps: deps,
        after: Enum.slice(lines, dei..-1) |> Enum.join("\n"),
        filename: filename
      }
    else
      {:error, error} -> %MixExsEditor{results: [error], filename: filename}
    end
  end

  defp deps_start_index(lines) do
    result =
      lines
      |> Enum.with_index()
      |> Enum.filter(&Regex.match?(@deps_start_regex, elem(&1, 0)))
      |> debug_inspect(label: "deps_start_regex lines")
      |> Enum.map(fn {_, i} -> i end)
      |> exactly_one(:no_deps, :ambiguous_deps)
    result
  end

  defp exactly_one([x], _, _), do: x
  defp exactly_one([], none_error, _), do: {:error, none_error}
  defp exactly_one(_, _, too_many_error), do: {:error, too_many_error}

  defp deps_end_index(lines, start_index) do
    with(
      lines <- Enum.slice(lines, start_index..-1),
      end_index when not is_nil(end_index) <-
        Enum.find_index(lines, &Regex.match?(@deps_end_regex, &1)),
      do: start_index + end_index
    ) ||
      {:errors, :no_deps_end}
  end

  defp parse_deps(lines, acc \\ [])
  defp parse_deps([], acc), do: acc

  defp parse_deps([line | rest], acc) do
    cond do
      Regex.match?(@mix_new_comments_regex, line) -> parse_deps(rest, acc)
      Regex.match?(@dep_regex, line) -> parse_deps(rest, [parse_dep(line) | acc])
      Regex.match?(@square_brackets_regex, line) -> parse_deps(rest, acc)
      true -> {:error, :unparsable_deps}
    end
  end

  defp parse_dep(line) do
    String.replace(line, @dep_regex, "\\1")
  end

  defp debug_inspect(value, opts) do
    if Mix.debug?() do
      IO.inspect(value, opts)
    else
      value
    end
  end
end
