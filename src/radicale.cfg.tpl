[server]
hosts = {{ ( ds "config" ).server.host }}:{{ ( ds "config" ).server.port }}

[auth]
type = htpasswd
htpasswd_filename = data/.htpasswd

[storage]
filesystem_folder = data/storage/

[logging]
level = info
