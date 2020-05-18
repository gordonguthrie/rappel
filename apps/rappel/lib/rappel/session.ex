defmodule Rappel.Rappel.Session do
	
  use GenServer

  alias Rappel.Rappel.Session
  alias Rappel.Rappel.ExternalBinding
  alias Rappel.Rappel.InternalBinding
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
    new_binding = %ExternalBinding{module:    m, 
                                   function:  f,
                                   arguments: a, 
                                   results:   results}
    newb = Map.put(bs, varname, new_binding)
    new_session = %Session{session | bindings: newb}                  
    reply = %{lexed: %{}, parsed: %{}, main: make_main(new_session)}
    {:reply, reply, new_session}
  end
  def handle_call({:expression, e}, _from, %Session{bindings: b,
                                                    commands: c} = session) do
    lexed   = lex(e)
    parsed  = parse(lexed)
    {results, new_bindings} = :pometo_runtime.run_ast(parsed, b)
    new_session = %Session{session | bindings: new_bindings,
                                     commands: [{e, parsed, results} | c]}                                     
    reply = %{lexed: lexed, parsed: parsed, main: make_main(new_session)}
    IO.inspect(new_session, label: "in expression new state is")
    {:reply, reply, new_session}
  end
  def handle_call(:get_listing, _from, session) do
    IO.puts("in get listing...")
    reply = %{lexed: %{}, parsed: %{}, main: make_main(session)}
    {:reply, reply, session}
  end
  def handle_call(msg, _from, session) do
    IO.inspect(session, label: "session is")
    IO.inspect(msg, label: "called with")
    {:reply, :banjo, session}
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
            {:error, error} -> IO.puts(error, label: "parser error")
                               "error"
        end
  end

  defp make_main(%Session{bindings: b,
                          commands: c}) do
          bs = Enum.reduce(b, [], fn({key, value}, acc) ->
             IO.inspect({key, value}, label: "mapping with key/value")
             %ExternalBinding{module:    m,
                              function:  f,
                              arguments: a,
                              results:   r} = value
           new_acc = {:external_binding, key <> " ← apply(" <> Atom.to_string(m) <> ", " <> Atom.to_string(f) <> ", [" <> a <> "])", r}
           [new_acc | acc]
          end)
          cs = Enum.reduce(c, [], fn({k, expr, v}, acc) ->

              new_acc = {:expression, k, Kernel.inspect(:pometo_runtime.format(v))}
              [new_acc | acc]
          end)
          bs ++ cs
  end

end