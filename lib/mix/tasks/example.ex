defmodule Mix.Tasks.Example do
  use Mix.Task

  # @deps_start_regex ~r/\A\s*defp deps\(*[a-z_]*\)*\s*do\z/
  # @mix_comments_regex ~r/\A\s+# (.*)\z/

  @shortdoc "Example Task for debug"
  def run(args) do
    # IO.puts "Hello #{args}" # Hello 2323444888
    # IO.inspect(args) # ["2323", "444", "888"]
    # Mix.shell().info(Enum.join(args, " "))
    # Enum.reduce([78, 2, 3, 4], fn x, acc -> IO.inspect(x) end)
    content = File.read!('mix.exs')
    |> String.split("\n")
    # |> Enum.filter(&!Regex.match?(@mix_comments_regex, &1))
    # |> Enum.with_index
    # |> Enum.filter(&(Regex.match?(@deps_start_regex, elem(&1, 0))))

    # alias MixDepsAdd.MixExsEditor
    # args
    # |> Enum.reduce(MixExsEditor.read("mix.exs"), fn name, state ->
    #   IO.inspect(state)
    # end)
    IO.inspect(content)
  end
end
