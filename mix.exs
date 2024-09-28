defmodule MixDepsAdd.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_static_code_rules,
     version: "0.1.4",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :inets, :ssl]]
  end

  # Note that we don't have a deps/0 function here; as a Mix task, we can't
  # really have dependencies, plus it means that we'll refuse to operate on
  # our own mix.exs file.
end
