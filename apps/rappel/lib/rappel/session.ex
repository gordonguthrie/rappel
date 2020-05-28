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
  def handle_call(:clear_session, _from, _session) do
    new_session = %Session{}
    reply = make_main(new_session)
    {:reply, reply, new_session}
  end

  def handle_call(:get_session, _from, %Session{bindings: b,
                                                commands: c} = session) do
    header =    ["⍝\n", "⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝ External Bindings ⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝\n", "⍝\n"]
    bs = get_bindings(b)
    seperator = ["⍝\n", "⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝ Expressions ⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝\n", "⍝\n"]
    cs = get_commands(c, [])
    reply = header ++ bs ++ seperator ++ cs
    {:reply, reply, session}
  end

  def handle_call({:binding, {{varname, {m, f, a}}, results}}, _from, %Session{bindings: bs} = session) do
    external_binding = %ExternalBinding{module:    m,
                                        function:  f,
                                        arguments: a}
    new_binding = %Binding{expression: external_binding,
                           results:    results}
    newb = Map.put(bs, varname, new_binding)
    new_session = %Session{session | bindings: newb}
    reply = make_main(new_session)
    {:reply, reply, new_session}
  end

  def handle_call({:expressions, es}, _from, %Session{bindings: bs,
                                                      commands: cs} = session) do
    {new_bs, new_cs} = run(es, bs)
    new_session = %Session{session | commands: new_cs ++ cs,
                                     bindings: new_bs}
    reply = make_main(new_session)
    {:reply, {:ok, reply}, new_session}
  end

  def handle_call(:get_listing, _from, session) do
    reply = make_main(session)
    {:reply, reply, session}
  end

  @impl true
  def handle_cast(_msg, session) do
    {:noreply, session}
  end

  defp run(string, bindings) do
    expressions = String.split(string, "\n")
    Enum.reduce(expressions, {bindings, []}, &do_run/2)
  end

  defp do_run("", {bindings, commands}) do
    {bindings, commands}
  end
  defp do_run(expr, {bindings, commands}) do
    case lex(expr) do
      # comments on lines are valid
      {:ok, []} ->
        new_c = %Command{expr:     expr,
                         results:  ''}
        {bindings, [new_c | commands]}
      {:ok, lexed} ->
        parse(lexed, expr, bindings, commands)
      {:error, errors} ->
        new_c = %Command{expr:     expr,
                         suceeded: false,
                         results:  errors}
        {bindings, [new_c | commands]}
    end
  end

  defp lex(string) do
    try do
      charlist = String.to_charlist(string)
      _lexed = :pometo_lexer.get_tokens(charlist)
    catch
      e -> Kernel.inspect(e)
    end
  end

  defp parse(tokens, expr, bindings, commands) do
    case parse2(tokens) do
      {parsed, new_bindings} ->
        repacked_bindings = case repack(new_bindings, expr) do
          []         -> bindings
          [repacked] -> merge(repacked, bindings)
        end
        results = :pometo_runtime.run_ast(parsed)
        new_c = %Command{expr:    expr,
                         results: results}
        {repacked_bindings, [new_c | commands]}
      error ->
        IO.inspect(error, label: "FIX ME: parsing failed with error")
        err = "fix up parser error"
        new_c = %Command{expr:     expr,
                         suceeded: false,
                         results:  err}
        {bindings, [new_c | commands]}
    end
  end

  defp parse2(tokenlist) do
    parsed = :pometo_parser.parse(tokenlist)
    case parsed do
      {:ok, parse}    -> parse
      {:error, error} -> IO.inspect(error, label: "FIX ME: parser error")
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
                 # if the binding failed it wouldn't be here so set to :run
                 [{:external_binding, str, :ran, to_string(results)} | acc]
               _ ->
                 acc
           end
           new_acc
          end)
          cs = Enum.reduce(c, [], fn(%Command{expr:     e,
                                              suceeded: s,
                                              results:  r}, acc) ->
              new_acc = case s do
                true ->
                  {:expression, e, :ran,         to_string(:pometo_runtime.format(r))}
                false ->
                  {:error,      e, :did_not_run, to_string(:pometo_runtime.format_errors(r))}
              end
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
    Enum.reduce(new_bindings, old_bindings, &put_bindings/2)
  end

  defp put_bindings({k, v}, bindings) do
    Map.put(bindings, k, v)
  end

  defp get_bindings(bindings) do
    Enum.map(bindings, &format_bindings/1)
  end

  defp format_bindings({var, %{expression: %ExternalBinding{module: m, function: f, arguments: a}}}) do
    var <> " ← " <> Atom.to_string(m) <> ":" <> Atom.to_string(f) <> "(" <> a <> ").\n"
  end
  defp format_bindings({_, _}), do: ""

  # commands are held in reverse order, so don't reverse the accumulator
  defp get_commands([],      acc), do: Enum.join(acc, "\n")
  defp get_commands([h | t], acc) do
    %Command{expr:     e,
             suceeded: s,
             results:  r} = h
    newacc = case s do
               true  -> [e | acc]
               false -> acc
             end
    get_commands(t, newacc)
  end

  defp comment_out([]), do: ''
  defp comment_out(x),  do: '⍝ ' ++ :pometo_runtime.format(x)

end