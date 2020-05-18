defmodule Rappel.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Rappel.PubSub},
      # Start a worker by calling: Rappel.Worker.start_link(arg)
      # {Rappel.Worker, arg}
      {Rappel.Rappel.Session, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Rappel.Supervisor)
  end
end
