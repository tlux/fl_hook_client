import Config

config :logger, :default_formatter,
  format: "[$level] $message $metadata\n",
  metadata: [:host, :port]

import_config "#{Mix.env()}.exs"
