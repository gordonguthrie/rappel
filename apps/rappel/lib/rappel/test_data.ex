defmodule Rappel.TestData do

	def get_integers() do
		[rand_int(), rand_int(), rand_int()]
	end

	def get_integers(n) when is_integer(n) do
		IO.inspect(n)
		get_i(n, [])
	end

	defp get_i(0, acc), do: acc
	defp get_i(n, acc), do: get_i(n - 1, [rand_int() | acc])

	defp rand_int(), do: Enum.random(1..255) - 124

	def get_floats() do
		[rand_f(), rand_f(), rand_f()]
	end

	def get_floats(n) when is_integer(n) do
		get_f(n, [])
	end

	defp get_f(0, acc), do: acc
	defp get_f(n, acc), do: get_f(n - 1, [rand_f() | acc])

	defp rand_f(), do: (:random.uniform() * 255) - 124

end