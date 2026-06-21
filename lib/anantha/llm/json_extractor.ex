defmodule Anantha.LLM.JsonExtractor do
  @moduledoc """
  Extracts and parses JSON from LLM responses.
  """

  @json_code_block_regex ~r/```(?:json)?\s*\n?([\s\S]*?)```/i
  @any_code_block_regex ~r/```\s*\n?([\s\S]*?)```/i

  @doc """
  Extracts the longest JSON object string from content.

  Tries markdown code blocks first (```json or ```), then falls back to
  finding the outermost valid JSON object via balanced brace matching.
  Returns `""` if no JSON is found.
  """
  @spec extract(String.t() | nil) :: String.t()
  def extract(nil), do: ""

  def extract(content) when is_binary(content) do
    content
    |> do_extract()
    |> String.trim()
  end

  def extract(_), do: ""

  @doc """
  Extracts the longest (outermost) valid JSON object from content.
  """
  @spec extract_last_json_object(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def extract_last_json_object(content) when is_binary(content) do
    case all_valid_json_strings(content) do
      [] ->
        {:error, :no_valid_json_found}

      jsons ->
        jsons |> Enum.sort_by(&String.length/1, :desc) |> List.first() |> then(&{:ok, &1})
    end
  end

  def extract_last_json_object(_), do: {:error, :invalid_content}

  @doc """
  Extracts ALL valid JSON object strings found in content.

  Returns a list of raw JSON strings, from left to right,
  or an empty list if none are found.
  """
  @spec extract_all_objects(String.t()) :: list(String.t())
  def extract_all_objects(content) when is_binary(content), do: all_valid_json_strings(content)

  def extract_all_objects(_), do: []

  @doc """
  Extracts the first JSON array `[...]` from content.

  Tries markdown code blocks first, then falls back to balanced bracket
  matching. Returns the raw JSON string or `""` if none found.
  """
  @spec extract_array(String.t() | nil) :: String.t()
  def extract_array(nil), do: ""

  def extract_array(content) when is_binary(content) do
    content
    |> do_extract_array()
    |> String.trim()
  end

  def extract_array(_), do: ""

  # ── Internal helpers ──────────────────────────────────────────────────

  defp do_extract(content) do
    trimmed = String.trim(content)

    case extract_from_markdown(trimmed, @json_code_block_regex) do
      nil ->
        case extract_from_markdown(trimmed, @any_code_block_regex) do
          nil ->
            case extract_last_json_object(trimmed) do
              {:ok, json} -> json
              {:error, _} -> ""
            end

          json ->
            json
        end

      json ->
        json
    end
  end

  defp do_extract_array(content) do
    trimmed = String.trim(content)

    case extract_from_markdown(trimmed, @json_code_block_regex) do
      nil ->
        case extract_from_markdown(trimmed, @any_code_block_regex) do
          nil ->
            case extract_valid_array(trimmed) do
              {:ok, json} -> json
              {:error, _} -> ""
            end

          json ->
            json
        end

      json ->
        json
    end
  end

  defp extract_from_markdown(content, regex) do
    case Regex.run(regex, content) do
      [_, json_content] -> String.trim(json_content)
      _ -> nil
    end
  end

  # Shared helper for object extraction — scans all `{` positions and
  # returns every balanced JSON object found, left to right.
  defp all_valid_json_strings(content) do
    positions = Regex.scan(~r/\{/, content, return: :index)

    positions
    |> Enum.map(fn [{start, _}] -> extract_from_position(content, start) end)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, json} -> json end)
  end

  defp extract_from_position(content, start) do
    substr = binary_part(content, start, byte_size(content) - start)
    find_balanced_json(substr, substr, 0, 0)
  end

  defp find_balanced_json(<<c::utf8, rest::binary>>, original, count, idx) do
    new_count =
      case c do
        ?{ -> count + 1
        ?} -> count - 1
        _ -> count
      end

    if new_count == 0 and count > 0 do
      json = binary_part(original, 0, idx + 1)
      {:ok, json}
    else
      find_balanced_json(rest, original, new_count, idx + 1)
    end
  end

  defp find_balanced_json("", _, 0, _), do: {:error, :incomplete}
  defp find_balanced_json("", _, _, _), do: {:error, :unbalanced}

  # ── Array extraction helpers ──────────────────────────────────────────

  defp extract_valid_array(content) do
    positions = Regex.scan(~r/\[/, content, return: :index)

    positions
    |> Enum.map(fn [{start, _}] -> extract_array_from_position(content, start) end)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, json} -> json end)
    |> case do
      [] ->
        {:error, :no_valid_array_found}

      arrays ->
        arrays |> Enum.sort_by(&String.length/1, :desc) |> List.first() |> then(&{:ok, &1})
    end
  end

  defp extract_array_from_position(content, start) do
    substr = binary_part(content, start, byte_size(content) - start)
    find_balanced_array(substr, substr, 0, 0)
  end

  defp find_balanced_array(<<c::utf8, rest::binary>>, original, count, idx) do
    new_count =
      case c do
        ?[ -> count + 1
        ?] -> count - 1
        _ -> count
      end

    if new_count == 0 and count > 0 do
      json = binary_part(original, 0, idx + 1)
      {:ok, json}
    else
      find_balanced_array(rest, original, new_count, idx + 1)
    end
  end

  defp find_balanced_array("", _, 0, _), do: {:error, :incomplete}
  defp find_balanced_array("", _, _, _), do: {:error, :unbalanced}
end
