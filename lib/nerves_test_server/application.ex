defmodule NervesTestServer.Application do
  use Application

  @producer Application.get_env(:nerves_test_server, :producer)
  @producer_opts Application.get_env(:nerves_test_server, @producer)

  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, [name: NervesTestServer.PubSub]},
      {NervesTestServer.Repo, []},
      {NervesTestServerWeb.Endpoint, []},
      {@producer, [@producer_opts]}
    ]

    opts = [strategy: :one_for_one, name: NervesTestServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
