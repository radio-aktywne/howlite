# Identifier of the calendar
calendar: {{ env.Getenv "HOWLITE__CALENDAR" "calendar" | strings.Quote }}

# Configuration for the credentials
credentials:
  # Password for the main user
  password: {{ env.Getenv "HOWLITE__CREDENTIALS__PASSWORD" "password" | strings.Quote }}

  # Username for the main user
  user: {{ env.Getenv "HOWLITE__CREDENTIALS__USER" "user" | strings.Quote }}

# Configuration for the server
server:
  # Host to run the server on
  host: {{ env.Getenv "HOWLITE__SERVER__HOST" "0.0.0.0" | strings.Quote }}

  # Port to run the server on
  port: {{ env.Getenv "HOWLITE__SERVER__PORT" "10520" | conv.ToInt }}
