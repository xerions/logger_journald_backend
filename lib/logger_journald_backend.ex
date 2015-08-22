defmodule Logger.Backend.Journald do
  use GenEvent

  @default_level  :info
  @default_format "[$level] $message\n"
  @default_metadata []

  def init(_) do
    {:ok, configure([])}
  end

  def handle_call({:configure, opts}, _state) do
    {:ok, :ok, configure(opts)}
  end

  def handle_event({level, _gl, {Logger, msg, ts, md}}, %{level: min_level} = state) do
    if is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt do
      :ok = write(level, msg, ts, md, state)
      {:ok, state}
    else
      {:ok, state}
    end
  end

  def handle_event(_event, state) do
    {:ok, state}
  end

  defp write(level, msg, ts, md, state) do
    text = Logger.Formatter.format(state.format, level, msg, ts, md) -- ["\n"]
    metadata = for {md_key, md_val} <- md do
      {md_key |> to_string |> String.upcase, :io_lib.format("~p", [md_val])}
    end

    metalist = [{'MESSAGE', text}, {'PRIORITY', level_to_num(state.level)}] ++ metadata
    :journald_api.sendv(metalist)
  end

  defp configure(opts) do
    app_env = Application.get_env(:logger, :logger_journald_backend, [])
    app_env = case opts do
                [] -> app_env
                _ ->  opts
              end
    level  = Keyword.get(app_env, :level, @default_level)
    format = Keyword.get(app_env, :format, @default_format)
    metadata = Keyword.get(app_env, :metadata, @default_metadata)
    %{level: level, format: Logger.Formatter.compile(format), metadata: metadata}
  end

  defp level_to_num(:debug), do: 7
  defp level_to_num(:info), do: 6
  defp level_to_num(:warn), do: 4
  defp level_to_num(:error), do: 3
end
