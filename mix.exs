defmodule ArcAliyunOss.MixProject do
  use Mix.Project

  @project_host "https://github.com/GreenNerd-Labs/arc_aliyun_oss"
  @version "0.1.0"

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
      {:alixir_oss, "~ 0.1.0", git: "https://github.com/GreenNerd-Labs/alixir_oss", branch: "develop"}
    ]
  end

  defp description do
    "Aliyun OSS provider for Arc"
  end

  defp package do
    [
      name: :arc_aliyun_oss,
      files: ["libs", "mix.exs", "README", "MIT-LICENSE"],
      maintainers: ["CptBreeza"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_host}
    ]
  end
end
