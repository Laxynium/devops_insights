FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt install elixir
RUN mix local.hex
RUN mix archive.install hex phx_new
RUN apt-get install inotify-tools