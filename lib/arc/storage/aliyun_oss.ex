defmodule Arc.Storage.AliyunOSS do
  @moduledoc """
  Aliyun OSS implementation for `Arc`.

  ACL is not supported yet.
  """

  @default_expire_time 60*5

  alias Alixir.OSS
  alias Alixir.OSS.Env
  alias Alixir.OSS.FileObject

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})

    alioss_bucket = alioss_bucket(definition)
    alioss_key = Path.join(destination_dir, file.file_name)

    file
    |> do_put({alioss_bucket, alioss_key})
    |> handle_common_results(file)
  end

  # Put binary file in memory
  defp do_put(%Arc.File{binary: file_binary}, {alioss_bucket, alioss_key}) when is_binary(file_binary),
    do: OSS.put_object(%FileObject{bucket: alioss_bucket, object_key: alioss_key, object: file_binary}) |> Alixir.request
  # Put file stored in disk
  defp do_put(%Arc.File{path: path}, {alioss_bucket, alioss_key}),
    do: OSS.put_object(%FileObject{bucket: alioss_bucket, object_key: alioss_key, object: File.read!(path)}) |> Alixir.request

  def url(definition, version, file_and_scope, options \\ []) do
    case Keyword.get(options, :signed, false) do
      false -> build_url(definition, version, file_and_scope, options)
      true -> build_signed_url(definition, version, file_and_scope, options)
    end
  end

  defp build_url(definition, version, file_and_scope, _) do
    definition
    |> host
    |> Path.join(alioss_key(definition, version, file_and_scope))
    |> URI.encode
  end

  defp build_signed_url(definition, version, file_and_scope, options) do
    file = %FileObject{
      bucket: definition.bucket(),
      object_key: alioss_key(definition, version, file_and_scope)
    }

    OSS.presigned_url(:get, file, options)
  end

  def delete(definition, version, file_and_scope) do
    %FileObject{
      bucket: alioss_bucket(definition),
      object_key: alioss_key(definition, version, file_and_scope)
    }
    |> OSS.delete_object()
    |> Alixir.request()

    :ok
  end

  # helper funcitons

  defp handle_common_results(result, file) do
    case result do
      {:ok, 200, _} -> {:ok, file.file_name}
      {:ok, _, message} -> {:error, to_string(message)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp alioss_key(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Arc.Definition.Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
  end

  defp host(definition) do
    # FIXME
    # Support only https at present
    "https://#{alioss_bucket(definition)}.#{Env.oss_endpoint}"
  end

  defp alioss_bucket(definition) do
    case definition.bucket() do
      {:system, env_var} when is_binary(env_var) -> System.get_env(env_var)
      name -> name
    end
  end
end
