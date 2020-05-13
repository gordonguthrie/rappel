defmodule RappelWeb.PageLive do
  use RappelWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, main: %{}, lexer: %{}, parser: %{}, query: "")}
  end

  @impl true
  def handle_event("on_type", %{"q" => query}, socket) do
    # doing nothing
    {:noreply, assign(socket, main: %{}, lexer: %{}, parser: %{}, query: query)}
  end

  @impl true
  def handle_event("on_enter", %{"q" => query}, socket) do
    IO.inspect(query, label: "got an enter")
    lexed   = lex(query)
    IO.inspect(lexed, label: "lexed")
    parsed  = parse(lexed)
    IO.inspect(parsed, label: "parsed")
    results = :pometo_runtime.run_ast(parsed, [])
    IO.inspect(results, label: "results")
    {:noreply, assign(socket, main: results, lexer: format(lexed), parser: format([parsed]), query: query)}
  end

  defp lex(string) do
      try do
        charlist = String.to_charlist(string)
        lexed = :pometo_lexer.get_tokens(charlist)
      catch
        e -> Kernel.inspect(e)
      end
  end

  defp parse(tokenlist) do
        parsed = :pometo_parser.parse(tokenlist)
        case parsed do
            {:ok, parse}    -> parse
            {:error, error} -> IO.puts(error, label: "parser error")
                               "error"
        end
  end

  defp format(map) do
        {_, msg} = Enum.reduce(map, {0, %{}}, fn (l, {n, acc}) -> 
          {n + 1, Map.put(acc, n, Kernel.inspect(l))}
        end)
        msg
      end
end
