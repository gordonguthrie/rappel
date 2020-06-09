defmodule Rappel.Rappel.Session do

@moduledoc """
  This is the Session module that holds a Pometo session.

  You should note that Bindings here are implemented as records
  and not as structs

  This is for interop with the Pometo which is written in Erlang

  """

  use GenServer

  alias Rappel.Rappel.Session
  alias Rappel.Rappel.Command
  alias Rappel.Rappel.ExternalBinding
  alias Rappel.Rappel.Binding

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
    new_binding = Binding.binding(expression: external_binding,
                                  results:    results)
    newb = Map.put(bs, varname, new_binding)
    new_session = %Session{session | bindings: newb}
    reply = make_main(new_session)
    {:reply, reply, new_session}
  end

  def handle_call({:expressions, es}, _from, %Session{bindings: bs,
                                                      commands: cs} = session) do
    {new_bs, new_cs} = run(es, bs)
    new_session = %Session{session | commands: [new_cs | cs],
                                     bindings: Map.merge(bs, new_bs)}
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
    charlist = String.to_charlist(string)
    mapbindings = convert_to_maps(bindings)
    {newbindings, results} = :pometo.interpret(charlist, mapbindings)
    returnbindings = convert_to_structs(newbindings, string)
    {returnbindings, Kernel.struct(Command, results)}
  end

  defp convert_to_maps(bindings) do
    map_to_struct_fn = fn({var, b}, bs) ->
       mapped = Map.from_struct(b)
       Map.put(bs, var, mapped)
     end
     Enum.reduce(bindings, %{}, map_to_struct_fn)
  end

  defp convert_to_structs(bindings, expr) do
    map_to_struct_fn = fn({var, %{binding: b, results: results}} = x, bs) ->
      b = %Binding{binding:   b,
                  expression: expr,
                  results:    results}
      Map.put(bs, var, b)
     end
     Enum.reduce(bindings, %{}, map_to_struct_fn)
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
          cs = Enum.reduce(c, [], fn(%Command{expr:      e,
                                              succeeded: s,
                                              results:   r}, acc) ->
              new_acc = case s do
                true  -> {:expression, e, :ran,         r}
                false -> {:error,      e, :did_not_run, r}
              end
              [new_acc | acc]
          end)
          bs ++ cs
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
    %Command{expr:      e,
             succeeded: s} = h
    newacc = case s do
               true  -> [e | acc]
               false -> acc
             end
    get_commands(t, newacc)
  end

end