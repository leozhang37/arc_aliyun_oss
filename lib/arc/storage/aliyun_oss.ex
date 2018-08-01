defmodule Arc.Storage.AliyunOSS do
  @moduledoc """
  Aliyun OSS implementation for `Arc`.

  ACL is not supported yet.
  """

  @default_expire_time 60*5

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
    do: Alixir.OSS.put_object(alioss_bucket, alioss_key, file_binary) |> Alixir.request
  # Put file stored in disk
  defp do_put(%Arc.File{path: path}, {alioss_bucket, alioss_key}),
    do: Alixir.OSS.put_object(alioss_bucket, alioss_key, File.read!(path)) |> Alixir.request

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
    alioss_key = alioss_key(definition, version, file_and_scope)
    url = definition |> host |> Path.join(alioss_key) |> URI.encode

    now = DateTime.utc_now |> DateTime.to_unix
    expires = now + (Keyword.get(options, :expire_in) || @default_expire_time)
    string_to_sign = "GET\n\n\n#{expires}\n/#{Path.join(definition.bucket(), alioss_key)}"
    signature = string_to_sign |> sign_string
    parameters = %{"Signature" => signature, "Expires" => expires, "OSSAccessKeyId" => Alixir.OSS.Env.oss_access_key_id}

    "#{url}?#{URI.encode_query(parameters)}"
  end

  def delete(definition, version, file_and_scope) do
    definition
    |> alioss_bucket
    |> Alixir.OSS.delete_object(alioss_key(definition, version, file_and_scope))
    |> Alixir.request

    :ok
  end

  # helper funcitons

  defp handle_common_results(result, file) do
    case result do
      {:ok, 200, _} -> {:ok, file.file_name}
      {:ok, _, message} -> {:error, to_string(message)}
      {:error, _, error} -> {:error, error}
    end
  end

  defp sign_string(string) do
    :crypto.hmac(:sha, Alixir.OSS.Env.oss_access_key_secret, string) |> Base.encode64
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
    "https://#{alioss_bucket(definition)}.#{Alixir.OSS.Env.oss_endpoint}"
  end

  defp alioss_bucket(definition) do
    case definition.bucket() do
      {:system, env_var} when is_binary(env_var) -> System.get_env(env_var)
      name -> name
    end
  end
end
