defmodule GoulashControl.Mixfile do
  use Mix.Project

  def project do
    [ app: :goulash_control,
      version: "0.0.1",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 0.12.5",
      deps: deps ] ++ options(Mix.env)
  end

  defp options(env) when env in [:dev, :test] do
    [exlager_level: :debug, exlager_truncation_size: 8096]
  end

  # Configuration for the OTP application
  def application do
    [registered: [
      :"Goulash.ControlServer",
      :"Goulash.InstanceSup" ],
      mod: { Goulash.Control, [] },
      env: []]
  end

  # Returns the list of dependencies in the format:
  # { :foobar, git: "https://github.com/elixir-lang/foobar.git", tag: "0.1" }
  #
  # To specify particular versions, regardless of the tag, do:
  # { :barbat, "~> 0.1", github: "elixir-lang/barbat" }
  #
  # You can depend on another app in the same umbrella with:
  # { :other, in_umbrella: true }
  defp deps do
    [
      {:exlager, ~r".*", [github: "khia/exlager"]}
    ]
  end
end
