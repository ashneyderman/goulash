defmodule GoulashClient.Mixfile do
  use Mix.Project

  def project do
    [ app: :goulash_client,
      version: "0.0.1",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 0.14.0",
      deps: deps,
      escript: [
        main_module: Tunnel.Cli,
        app: :goulash_client,
        name: :ts_client ] ]
  end

  # Configuration for the OTP application
  def application do
    [   
      mod: { GoulashClient, [] }, 
      applications: [ :goulash_control ],
    ]
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
      {:goulash_control, in_umbrella: true},
      {:xmlrpc, git: "git://github.com/etnt/xmlrpc.git", branch: "master"},
      {:uuid, git: "git://gitorious.org/avtobiff/erlang-uuid.git", branch: "master"}
    ]
  end
end
