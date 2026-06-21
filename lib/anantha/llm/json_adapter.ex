defmodule Anantha.LLM.JsonAdapter do
  @moduledoc """
  Defensive JSON decoder that tries `JsonRemedy.repair/1` first for
  malformed LLM output, falling back to `Jason.decode/2`.

  This decouples the pipeline from the `json_remedy` dependency. If
  `json_remedy` is unavailable (e.g. not compiled), we silently fall
  back to standard JSON decoding.
  """

  @doc """
  Decodes a JSON string, attempting repair first.

  Returns `{:ok, decoded}` on success or `{:error, reason}` on failure.
  """
  @spec decode(String.t()) :: {:ok, term()} | {:error, term()}
  def decode(json_string) when is_binary(json_string) do
    case try_json_remedy(json_string) do
      {:ok, decoded} when decoded != "" ->
        {:ok, decoded}

      :fallback ->
        Jason.decode(json_string)

      {:ok, _} ->
        Jason.decode(json_string)

      {:error, _reason} ->
        Jason.decode(json_string)
    end
  end

  @doc """
  Like `decode/1` but raises on error.
  """
  @spec decode!(String.t()) :: term()
  def decode!(json_string) when is_binary(json_string) do
    case decode(json_string) do
      {:ok, decoded} -> decoded
      {:error, reason} -> raise "JsonAdapter failed: #{inspect(reason)}"
    end
  end

  defp try_json_remedy(json_string) do
    if Code.ensure_loaded?(JsonRemedy) && function_exported?(JsonRemedy, :repair, 1) do
      case JsonRemedy.repair(json_string) do
        {:ok, result, _repairs} -> {:ok, result}
        {:ok, result} -> {:ok, result}
        {:error, _reason} = error -> error
      end
    else
      :fallback
    end
  end
end
