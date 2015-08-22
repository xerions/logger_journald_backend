# LoggerJournaldBackend

This is a backend for elixir `Logger`.

It will send logs out of lager to systemd journald.

## Configuration

the `Logger.Backend.Journald` is a custom backend for the elixir `:logger` application. To configure
`lager_journald_backend` just add `Logger.Backend.Journald` the to your configuration like this:

```elixir
config :logger,
  backends: [Logger.Backend.Journald]
```

Without any other configuration, the `Logger.Backend.Journald` will use `info` as default log level
and `"[$level] $message\n"` as format for the log messages.

To provide own configuration add backends' configuration to configuration file:

```elixir
config :logger,
  backends: [Logger.Backend.Journald]

config :logger, :logger_journald_backend,
  level: :debug,
  format: "[$level] $message\n",
  metadata: [:city]
```

and use it as:

```elixir
Logger.error "TestLogMessage_Error", [city: "Berlin"]
```

And then simply check your journal for the corresponding message with the:

```
$ journalctl | sed '$!d'
Aug 20 17:55:37 localhost beam.smp[24082]: [error] TestLogMessage_Error
```

## Runtime configuration

`Logger` provides two functions: `add_backend/2` and `configure_backend/2` to add backend and configure backend in runtime.

Usage:

```elixir
Logger.add_backend(Logger.Backend.Journald, [])
Logger.configure(Logger.Backend.Journald, [level: :error, format: "$time $message"])
```

## Dependency

`logger_journald_backend` uses [ejournald](https://github.com/systemd/ejournald).
