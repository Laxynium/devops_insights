FROM elixir:1.16.2

RUN apt update

RUN apt-get install -y inotify-tools
RUN mix local.hex
RUN mix archive.install hex phx_new