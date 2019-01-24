defmodule ArcAliyunOss.MixProject do
  use Mix.Project

  @project_host "https://github.com/GreenNerd-Labs/arc_aliyun_oss"
  @version "0.2.0"

  def project do
    [
      app: :arc_aliyun_oss,
      version: @version,
      source_url: @project_host,
      homepage_url: @project_host,
      description: description(),
      package: package(),
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:alixir_oss, git: "https://github.com/leozhang37/alixir_oss.git", branch: "develop"},
      {:arc, "~> 0.11.0"},
      {:ex_arc, "~> 0.0.1", git: "https://github.com/leozhang37/ex_arc.git", branch: "develop"},
      {:httpoison, "~> 1.5.0"}
    ]
  end

  defp description do
    "Aliyun OSS provider for Arc"
  end

  defp package do
    [
      name: :arc_aliyun_oss,
      files: ["lib", "mix.exs", "README.md", "MIT-LICENSE"],
      maintainers: ["CptBreeza"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_host}
    ]
  end
end
