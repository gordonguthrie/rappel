defmodule Rappel.Rappel.Session do
	
  use GenServer

  alias Rappel.Rappel.Session
  alias Rappel.Rappel.ExternalBinding
  alias Rappel.Rappel.Binding
  alias Rappel.Rappel.Command

  defstruct bindings: %{},
            commands: []


  # Callbacks

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @impl true
  def init([]) do
    {:ok, %Session{}}
  end

  @impl true
  def handle_call({:binding, {{varname, {m, f, a}}, results}}, _from, %Session{bindings: bs} = session) do
    external_binding = %ExternalBinding{module:    m,
                                        function:  f,
                                        arguments: a}
    new_binding = %Binding{expression: external_binding,
                           results:    results}
    newb = Map.put(bs, varname, new_binding)
    new_session = %Session{session | bindings: newb}
    reply = %{lexed: %{}, parsed: %{}, main: make_main(new_session)}
    {:reply, reply, new_session}
  end
  def handle_call({:expression, e}, _from, %Session{bindings: bs,
                                                    commands: c} = session) do
    lexed = lex(e)
    case parse(lexed) do
      {parsed, bindings} ->
        newbinding = %Binding{expression: e, results: bindings}
        repacked_bindings = case repack(bindings, e) do
          []         -> bs
          [repacked] -> repacked
      end
      merged_bindings = merge(repacked_bindings, bs)
      results = :pometo_runtime.run_ast(parsed)
      new_session = %Session{session | bindings: merged_bindings,
                                       commands: [{e, parsed, results} | c]}
      reply = %{lexed: lexed, parsed: parsed, main: make_main(new_session)}
      {:reply, {:ok, reply}, new_session}
    error ->
      reply = {:error, %{lexed: lexed, parsed: %{1 => "error"}, main: make_main(session)}}
      {:reply, reply, session}
    end
  end
  def handle_call(:get_listing, _from, session) do
    reply = %{lexed: %{}, parsed: %{}, main: make_main(session)}
    {:reply, reply, session}
  end

  @impl true
  def handle_cast(_msg, session) do
    {:noreply, session}
  end

  defp lex(string) do
      try do
        charlist = String.to_charlist(string)
        _lexed = :pometo_lexer.get_tokens(charlist)
      catch
        e -> Kernel.inspect(e)
      end
  end

  defp parse(tokenlist) do
        parsed = :pometo_parser.parse(tokenlist)
        case parsed do
            {:ok, parse}    -> parse
            {:error, error} -> IO.inspect(error, label: "parser error")
                               "error"
        end
  end

  defp make_main(%Session{bindings: b,
                          commands: c}) do
          bs = Enum.reduce(b, [], fn({key, value}, acc) ->
             %Binding{expression: expr,
                      results:    results} = value
             new_acc = case expr do
               %ExternalBinding{module:    m,
                                function:  f,
                                arguments: a} ->
                 str = key               <>
                       " ← apply("       <>
                       Atom.to_string(m) <>
                       ", "              <>
                       Atom.to_string(f) <>
                       ", ["             <>
                       a                 <>
                       "])"
                 [{:external_binding, str, to_string(results)} | acc]
               _ ->
                 acc
           end
           new_acc
          end)
          cs = Enum.reduce(c, [], fn({k, _expr, v}, acc) ->
              new_acc = {:expression, k, to_string(:pometo_runtime.format(v))}
              [new_acc | acc]
          end)
          bs ++ cs
  end

  defp repack(bindings, _expr) when bindings == %{}, do: []
  defp repack(bindings, expr) do
    Enum.map(bindings, fn({k, v}) -> Map.put(%{}, k, %Binding{expression: expr,
                                                              results:    v}) end)
  end

  defp merge(new_bindings, old_bindings) do
    Enum.reduce(new_bindings, old_bindings, fn({k, v}, bindings) ->  Map.put(bindings, k, v) end)
  end

end