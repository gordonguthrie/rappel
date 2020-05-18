defmodule RappelWeb.PageLive do
  use RappelWeb, :live_view

  alias Rappel.Rappel.Session

  @impl true
  def mount(_params, _session, socket) do
        %{lexed:  lexed,
          parsed: parsed,
          main:   main} = GenServer.call(Session, :get_listing)
    {:ok, assign(socket, main:   main,
                         lexer:  lexed,
                         parser: parsed)}
  end

  def handle_event("on_bind", args, socket) do
    # doing nothing
    IO.inspect(args)
    %{"variable_name" => varname,
      "module"        => mod,
      "function"      => func,
      "arguments"     => arguments} = args
    response = case check_validity(varname, mod, func, arguments) do
      {:ok, {m, f, a}} -> vals = for x <- apply(m, f, a), do: Kernel.inspect(x)
                          vals2 = Enum.join(vals, " ")
                          binding = {varname, {m, f, arguments}}
                          GenServer.call(Session, {:binding, {binding, vals2}});
      error            -> %{lexed:  %{},
                            parsed: %{}, 
                            main:   %{}}
      end
    %{lexed:  lexed,
      parsed: parsed,
      main:   main} = response
    {:noreply, assign(socket, main:   main, 
                              lexer:  format(lexed),
                              parser: format([parsed]))}
  end

  @impl true
  def handle_event("on_enter", %{"expression" => expression}, socket) do
    %{lexed:   lexed,
      parsed:  parsed,
      main:    main} = GenServer.call(Session, {:expression, expression})
    {:noreply, assign(socket, main:   main,
                              lexer:  format(lexed),
                              parser: format([parsed]))}
  end

  defp format(map) do
        {_, msg} = Enum.reduce(map, {0, %{}}, fn (l, {n, acc}) -> 
          {n + 1, Map.put(acc, n, Kernel.inspect(l))}
        end)
        msg
       end

  defp check_validity(varname, mod, func, args) do
        case String.match?(varname, ~r/([A-Z][a-zA-Z_¯∆⍙0-9]*)/) do
          false -> {:error, "invalid variable name"}
          true  -> {:ok, args_list, _} = :erl_scan.string(String.to_charlist(args))
                   args_list2 = make_args(args_list, [])
                   try do
                    mod2 = String.to_existing_atom(mod)
                    # if the module is not loaded the function names won't be existing atoms
                    {:module, mod2} = Code.ensure_loaded(mod2)
                    {:ok, {mod2, String.to_existing_atom(func), args_list2}}
                   rescue
                    error -> IO.puts(error, label: "apply mfa error")
                    {:error, "banjo"}

                  end
        end
      end

  defp make_args([], acc), do: Enum.reverse(acc)
  defp make_args([{:"<<", _}, {:string, _, b}, {:">>", _} | t], acc) do
   make_args(t, [to_string(b) | acc])
  end
  defp make_args([{:"-", _}, {:integer, _, n} | t], acc), do: make_args(t, [-n | acc])
  defp make_args([{:"-", _}, {:float,   _, f} | t], acc), do: make_args(t, [-f | acc])
  defp make_args([{:integer, _, n}            | t], acc), do: make_args(t, [n  | acc])
  defp make_args([{:float,   _, f}            | t], acc), do: make_args(t, [f  | acc])
  defp make_args([{:atom,    _, a}            | t], acc), do: make_args(t, [a  | acc])
  defp make_args([{:string,  _, c}            | t], acc), do: make_args(t, [c  | acc])
  defp make_args([{:",", _}                   | t], acc), do: make_args(t,       acc)

end
