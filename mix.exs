defmodule Epagoge.Mixfile do
  use Mix.Project

  def project do
    [app: :epagoge,
     version: "0.0.1",
     elixir: "~> 1.1-dev",
		 name: "Epagoge",
		 source_url: "https://github.com/ramsay-t/Epagoge",
		 homepage_url: "https://github.com/ramsay-t/Epagoge",
     test_coverage: [tool: Coverex.Task, log: :error],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger, :httpoison],
		 env: [z3cmd: "/Users/ramsay/Z3-str/Z3-str.py"]
		]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [{:elgar, git: "https://github.com/ramsay-t/elgar", compile: "mkdir -p deps; ln -s ../../skel deps/skel; rebar compile"},
		 {:skel, git: "https://github.com/ramsay-t/skel", app: false, override: true},
		 {:coverex, "~> 1.0.0", only: :test},
		 {:earmark, "~> 0.1", only: :dev},
		 {:ex_doc, "~> 0.6", only: :dev}]
  end
end
