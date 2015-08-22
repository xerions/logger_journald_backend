defmodule LoggerJournaldBackendTest do
  use ExUnit.Case, async: false

  require Logger

  Logger.add_backend Logger.Backend.Journald

  test "test_logger_jourand_backend" do
    Logger.remove_backend(:console)
    Logger.configure_backend(Logger.Backend.Journald, [level: :warn])
    Logger.warn "TestLogMessage_Warn"

    Logger.configure_backend(Logger.Backend.Journald, [level: :info])
    Logger.info "TestLogMessage_Info"

    Logger.configure_backend(Logger.Backend.Journald, [level: :error, metadata: [:city]])
    Logger.error "TestLogMessage_Error", [city: "Berlin"]

    logs = :ejournald.get_logs([{:direction, :descending}, {:at_most, 3}, {:message, true}])

    {_, :info, info} = List.keyfind(logs, :info, 1)
    {_, :warning, warn} = List.keyfind(logs, :warning, 1)
    {_, :error, error} = List.keyfind(logs, :error, 1)

    expected_info = "[info] TestLogMessage_Info"
    expected_warn = "[warn] TestLogMessage_Warn"
    expected_error = "[error] TestLogMessage_Error"

    assert expected_info == info
    assert expected_warn == warn
    assert expected_error == error

    #
    # Let's try to write log message with other log level
    #
    Logger.warn "TestLogMessage_Warn_again"
    logs = :ejournald.get_logs([{:direction, :descending}, {:at_most, 1}, {:message, true}])
    unexecpted_warn = "[warn] TestLogMessage_Warn_again"
    [{_, _, previous_message}] = logs
    assert unexecpted_warn != previous_message
  end
end

