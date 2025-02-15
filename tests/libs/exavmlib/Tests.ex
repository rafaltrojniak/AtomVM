#
# This file is part of AtomVM.
#
# Copyright 2024 Davide Bettio <davide@uninstall.it>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
#

defmodule Tests do

  @compile {:no_warn_undefined, :undef}

  def start() do
    :ok = IO.puts("Running Elixir tests")
    :ok = test_enum()
    :ok = test_exception()
    :ok = IO.puts("Finished Elixir tests")
  end

  defp test_enum() do
    # list
    3 = Enum.count([1, 2, 3])
    true = Enum.member?([1, 2, 3], 1)
    false = Enum.member?([1, 2, 3], 4)
    [0, 2, 4] = Enum.map([0, 1, 2], fn x -> x * 2 end)
    6 = Enum.reduce([1, 2, 3], 0, fn x, acc -> acc + x end)
    [2, 3] = Enum.slice([1, 2, 3], 1, 2)

    # map
    2 = Enum.count(%{a: 1, b: 2})
    true = Enum.member?(%{a: 1}, {:a, 1})
    false = Enum.member?(%{a: 1}, {:b, 1})
    kw = Enum.map(%{a: 1, b: 2}, fn x -> x end)
    1 = kw[:a]
    2 = kw[:b]
    kw2 = Enum.reduce(%{a: :A, b: :B}, [], fn {k, v}, acc -> [{v, k} | acc] end)
    :a = kw2[:A]
    :b = kw2[:B]
    kw3 = Enum.slice(%{a: 1, b: 2}, 0, 1)
    true = (length(kw3) == 1) and ((kw3[:a] == 1) or (kw3[:b] == 2))

    # map set
    3 = Enum.count(MapSet.new([0, 1, 2]))
    true = Enum.member?(MapSet.new([1, 2, 3]), 1)
    false = Enum.member?(MapSet.new([1, 2, 3]), 4)
    [0, 2, 4] = Enum.map(MapSet.new([0, 1, 2]), fn x -> x * 2 end)
    6 = Enum.reduce(MapSet.new([1, 2, 3]), 0, fn x, acc -> acc + x end)
    [] = Enum.slice(MapSet.new([1, 2]), 1, 0)

    # range
    4 = Enum.count(1..4)
    true = Enum.member?(1..4, 2)
    false = Enum.member?(1..4, 5)
    [1, 2, 3, 4] = Enum.map(1..4, fn x -> x end)
    55 = Enum.reduce(1..10, 0, fn x, acc -> x + acc end)
    [6, 7, 8, 9, 10] = Enum.slice(1..10, 5, 100)

    # into
    %{a: 1, b: 2} = Enum.into([a: 1, b: 2], %{})
    %{a: 2} = Enum.into([a: 1, a: 2], %{})
    expected_mapset = MapSet.new([1, 2, 3])
    ^expected_mapset = Enum.into([1, 2, 3], MapSet.new())

    # Enum.join
    "1, 2, 3" = Enum.join(["1", "2", "3"], ", ")

    # Enum.reverse
    [4, 3, 2] = Enum.reverse([2, 3, 4])

    undef =
      try do
        Enum.map({1, 2}, fn x -> x end)
      rescue
        e -> e
      end

    case undef do
      %Protocol.UndefinedError{description: "", protocol: Enumerable, value: {1, 2}} ->
        :ok

      %UndefinedFunctionError{arity: 3, function: :reduce, module: Enumerable} ->
        # code compiled with OTP != 25 doesn't raise Protocol.UndefinedError
        :ok
    end

    :ok
  end

  defp test_exception() do
    ex1 =
      try do
        raise "This is a test"
      rescue
        e -> e
      end

    %RuntimeError{message: "This is a test"} = ex1

    ex2 =
      try do
        :undef.ined(1, 2)
      rescue
        e -> e
      end

    # TODO: match for arity: 2, function: :ined, module: :undef
    %UndefinedFunctionError{} = ex2

    ex3 =
      try do
        fact(5) + fact(-2)
      rescue
        e -> e
      end

    %ArithmeticError{} = ex3

    ex4 =
      try do
        :erlang.integer_to_list(fact(-2))
      rescue
        e -> e
      end

    %ArgumentError{} = ex4

    ex5 =
      try do
        a = fact(-1)
        b = fact(3)
        ^a = b
      rescue
        e -> e
      end

    %MatchError{} = ex5

    :ok
  end

  defp fact(n) when n < 0, do: :test
  defp fact(0), do: 1
  defp fact(n), do: fact(n - 1) * n
end
