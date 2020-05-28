defmodule RappelWeb.SessionController do
	use RappelWeb, :controller

  alias Rappel.Rappel.Session

	def index(conn, params) do
		IO.inspect(params, label: "params")
		session = GenServer.call(Session, :get_session)

		text conn, session
	end

end