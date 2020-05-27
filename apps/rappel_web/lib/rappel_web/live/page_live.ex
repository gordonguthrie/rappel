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
                         parser: parsed)}  end

  def handle_event("on_bind", args, socket) do
    # doing nothing
    %{"variable_name" => varname,
      "module"        => mod,
      "function"      => func,
      "arguments"     => arguments} = args
    response = case run_binding(varname, mod, func, arguments) do
      {:ok, {{m, f}, vals}} ->
        vals2 = Enum.join(vals, " ")
        binding = {varname, {m, f, arguments}}
        %{lexed:  lexed,
          parsed: parsed,
          main:   main} =GenServer.call(Session, {:binding, {binding, vals2}})
          {:noreply, assign(socket, main:   main,
                                    lexer:  format(lexed),
                                    parser: format([parsed]))}
      {:error, error} ->
        error_response = put_flash(socket, :error, error)
        {:noreply, error_response}
      end
  end

  @impl true
  def handle_event("on_enter", %{"expression" => expression} = args, socket) do
    case GenServer.call(Session, {:expression, expression}) do
      {:ok, response} ->
            %{lexed:   lexed,
              parsed:  parsed,
              main:    main} = response
              reply = assign(socket, main:   main,
                                     lexer:  format(lexed),
                                     parser: format([parsed]))
              {:noreply, reply}
    {:error, response} ->
            %{lexed:   lexed,
              parsed:  parsed,
              main:    main} = response
              error_reply = put_flash(socket, :error, "invalid expression")
              {:noreply, assign(error_reply, main:   main,
                                             lexer:  format(lexed),
                                             parser: format([parsed]))}
    end
  end

  defp format(map) do
        {_, msg} = Enum.reduce(map, {0, %{}}, fn (l, {n, acc}) ->
          {n + 1, Map.put(acc, n, Kernel.inspect(l))}
        end)
        msg
       end

  defp run_binding(varname, mod, func, args) do
      {:ok, varrec} = :pometo_lexer.get_tokens(String.to_charlist(varname))
        case varrec do
          [{:var, _, _, _, _var}]  ->
            {:ok, args_list, _} = :erl_scan.string(String.to_charlist(args))
            args_list2 = make_args(args_list, [])
            try do
              mod2 = String.to_existing_atom(mod)
              # if the module is not loaded the function names won't be existing atoms
              {:module, mod2} = Code.ensure_loaded(mod2)
              func2 = String.to_existing_atom(func)
              vals = for x <- apply(mod2, func2, args_list2), do: Kernel.inspect(x)
              {:ok, {{mod2, func2}, vals}}
            rescue
              error ->
                case error do
                  %MatchError{term: {:error, :nofile}} ->
                    {:error, "no file"}
                  %ArgumentError{message: msg} ->
                    {:error, msg}
                  _ ->
                    {:error, error}
                end
            end
          _ -> {:error, "invalid variable name"}
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

  defp is_set(map, key), do: Map.put(%{}, key, Map.has_key?(map, key))

end
