#
# This file is part of elixir-lang.
#
# Copyright 2012-2019 Elixir Contributors
# https://github.com/elixir-lang/elixir/commits/v1.10.1/lib/elixir/lib/enum.ex
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
# SPDX-License-Identifier: Apache-2.0
#

defmodule Enum do
  # This avoids crashing the compiler at build time
  @compile {:autoload, false}

  @type t :: Enumerable.t()
  @type index :: integer
  @type element :: any

  require Stream.Reducers, as: R

  defmacrop next(_, entry, acc) do
    quote(do: [unquote(entry) | unquote(acc)])
  end

  def reduce(enumerable, acc, fun) when is_list(enumerable) do
    :lists.foldl(fun, acc, enumerable)
  end

  def reduce(%_{} = enumerable, acc, fun) do
    reduce_enumerable(enumerable, acc, fun)
  end

  def reduce(%{} = enumerable, acc, fun) do
    :maps.fold(fn k, v, acc -> fun.({k, v}, acc) end, acc, enumerable)
  end

  def reduce(enumerable, acc, fun) do
    reduce_enumerable(enumerable, acc, fun)
  end

  defp reduce_enumerable(enumerable, acc, fun) do
    Enumerable.reduce(enumerable, {:cont, acc}, fn x, acc -> {:cont, fun.(x, acc)} end) |> elem(1)
  end

  def all?(enumerable, fun) when is_list(enumerable) do
    all_list(enumerable, fun)
  end

  def any?(enumerable, fun) when is_list(enumerable) do
    any_list(enumerable, fun)
  end

  @doc """
  Returns the size of the enumerable.

  ## Examples

      iex> Enum.count([1, 2, 3])
      3

  """
  @spec count(t) :: non_neg_integer
  def count(enumerable) when is_list(enumerable) do
    length(enumerable)
  end

  def count(enumerable) do
    case Enumerable.count(enumerable) do
      {:ok, value} when is_integer(value) ->
        value

      {:error, module} ->
        enumerable |> module.reduce({:cont, 0}, fn _, acc -> {:cont, acc + 1} end) |> elem(1)
    end
  end

  def each(enumerable, fun) when is_list(enumerable) do
    :lists.foreach(fun, enumerable)
    :ok
  end

  def filter(enumerable, fun) when is_list(enumerable) do
    filter_list(enumerable, fun)
  end

  def find(enumerable, default, fun) when is_list(enumerable) do
    find_list(enumerable, default, fun)
  end

  def find_index(enumerable, fun) when is_list(enumerable) do
    find_index_list(enumerable, 0, fun)
  end

  def find_value(enumerable, default, fun) when is_list(enumerable) do
    find_value_list(enumerable, default, fun)
  end

  @doc """
  Returns a list where each element is the result of invoking
  `fun` on each corresponding element of `enumerable`.

  For maps, the function expects a key-value tuple.

  ## Examples

      iex> Enum.map([1, 2, 3], fn x -> x * 2 end)
      [2, 4, 6]

      iex> Enum.map([a: 1, b: 2], fn {k, v} -> {k, -v} end)
      [a: -1, b: -2]

  """
  @spec map(t, (element -> any)) :: list
  def map(enumerable, fun)

  def map(enumerable, fun) when is_list(enumerable) do
    :lists.map(fun, enumerable)
  end

  def map(enumerable, fun) do
    reduce(enumerable, [], R.map(fun)) |> :lists.reverse()
  end

  @doc """
  Maps and joins the given enumerable in one pass.

  `joiner` can be either a binary or a list and the result will be of
  the same type as `joiner`.
  If `joiner` is not passed at all, it defaults to an empty binary.

  All items returned from invoking the `mapper` must be convertible to
  a binary, otherwise an error is raised.

  ## Examples

      iex> Enum.map_join([1, 2, 3], &(&1 * 2))
      "246"

      iex> Enum.map_join([1, 2, 3], " = ", &(&1 * 2))
      "2 = 4 = 6"

  """
  @spec map_join(t, String.t(), (element -> String.Chars.t())) :: String.t()
  def map_join(enumerable, joiner \\ "", mapper)

  def map_join(enumerable, joiner, mapper) when is_binary(joiner) do
    reduced =
      reduce(enumerable, :first, fn
        entry, :first -> entry_to_string(mapper.(entry))
        entry, acc -> [acc, joiner | entry_to_string(mapper.(entry))]
      end)

    if reduced == :first do
      ""
    else
      IO.iodata_to_binary(reduced)
    end
  end

  @doc """
  Checks if `element` exists within the enumerable.

  Membership is tested with the match (`===/2`) operator.

  ## Examples

      iex> Enum.member?(1..10, 5)
      true
      iex> Enum.member?(1..10, 5.0)
      false

      iex> Enum.member?([1.0, 2.0, 3.0], 2)
      false
      iex> Enum.member?([1.0, 2.0, 3.0], 2.000)
      true

      iex> Enum.member?([:a, :b, :c], :d)
      false

  """
  @spec member?(t, element) :: boolean
  def member?(enumerable, element) when is_list(enumerable) do
    :lists.member(element, enumerable)
  end

  def member?(enumerable, element) do
    case Enumerable.member?(enumerable, element) do
      {:ok, element} when is_boolean(element) ->
        element

      {:error, module} ->
        module.reduce(enumerable, {:cont, false}, fn
          v, _ when v === element -> {:halt, true}
          _, _ -> {:cont, false}
        end)
        |> elem(1)
    end
  end

  def reject(enumerable, fun) when is_list(enumerable) do
    reject_list(enumerable, fun)
  end

  ## all?

  defp all_list([h | t], fun) do
    if fun.(h) do
      all_list(t, fun)
    else
      false
    end
  end

  defp all_list([], _) do
    true
  end

  ## any?

  defp any_list([h | t], fun) do
    if fun.(h) do
      true
    else
      any_list(t, fun)
    end
  end

  defp any_list([], _) do
    false
  end

  ## filter

  defp filter_list([head | tail], fun) do
    if fun.(head) do
      [head | filter_list(tail, fun)]
    else
      filter_list(tail, fun)
    end
  end

  defp filter_list([], _fun) do
    []
  end

  ## find

  defp find_list([head | tail], default, fun) do
    if fun.(head) do
      head
    else
      find_list(tail, default, fun)
    end
  end

  defp find_list([], default, _) do
    default
  end

  ## find_index

  defp find_index_list([head | tail], counter, fun) do
    if fun.(head) do
      counter
    else
      find_index_list(tail, counter + 1, fun)
    end
  end

  defp find_index_list([], _, _) do
    nil
  end

  ## find_value

  defp find_value_list([head | tail], default, fun) do
    fun.(head) || find_value_list(tail, default, fun)
  end

  defp find_value_list([], default, _) do
    default
  end

  @doc """
  Inserts the given `enumerable` into a `collectable`.

  ## Examples

      iex> Enum.into([1, 2], [0])
      [0, 1, 2]

      iex> Enum.into([a: 1, b: 2], %{})
      %{a: 1, b: 2}

      iex> Enum.into(%{a: 1}, %{b: 2})
      %{a: 1, b: 2}

      iex> Enum.into([a: 1, a: 2], %{})
      %{a: 2}

  """
  @spec into(Enumerable.t(), Collectable.t()) :: Collectable.t()
  def into(enumerable, collectable) when is_list(collectable) do
    collectable ++ to_list(enumerable)
  end

  def into(%_{} = enumerable, collectable) do
    into_protocol(enumerable, collectable)
  end

  def into(enumerable, %_{} = collectable) do
    into_protocol(enumerable, collectable)
  end

  def into(%{} = enumerable, %{} = collectable) do
    Map.merge(collectable, enumerable)
  end

  def into(enumerable, %{} = collectable) when is_list(enumerable) do
    Map.merge(collectable, :maps.from_list(enumerable))
  end

  def into(enumerable, %{} = collectable) do
    reduce(enumerable, collectable, fn {key, val}, acc ->
      Map.put(acc, key, val)
    end)
  end

  def into(enumerable, collectable) do
    into_protocol(enumerable, collectable)
  end

  defp into_protocol(enumerable, collectable) do
    {initial, fun} = Collectable.into(collectable)

    into(enumerable, initial, fun, fn entry, acc ->
      fun.(acc, {:cont, entry})
    end)
  end

  @doc """
  Inserts the given `enumerable` into a `collectable` according to the
  transformation function.

  ## Examples

      iex> Enum.into([2, 3], [3], fn x -> x * 3 end)
      [3, 6, 9]

      iex> Enum.into(%{a: 1, b: 2}, %{c: 3}, fn {k, v} -> {k, v * 2} end)
      %{a: 2, b: 4, c: 3}

  """
  @spec into(Enumerable.t(), Collectable.t(), (term -> term)) :: Collectable.t()

  def into(enumerable, collectable, transform) when is_list(collectable) do
    collectable ++ map(enumerable, transform)
  end

  def into(enumerable, collectable, transform) do
    {initial, fun} = Collectable.into(collectable)

    into(enumerable, initial, fun, fn entry, acc ->
      fun.(acc, {:cont, transform.(entry)})
    end)
  end

  defp into(enumerable, initial, fun, callback) do
    try do
      reduce(enumerable, initial, callback)
    catch
      kind, reason ->
        fun.(initial, :halt)
        :erlang.raise(kind, reason, __STACKTRACE__)
    else
      acc -> fun.(acc, :done)
    end
  end

  @doc """
  Joins the given enumerable into a binary using `joiner` as a
  separator.

  If `joiner` is not passed at all, it defaults to the empty binary.

  All items in the enumerable must be convertible to a binary,
  otherwise an error is raised.

  ## Examples

      iex> Enum.join([1, 2, 3])
      "123"

      iex> Enum.join([1, 2, 3], " = ")
      "1 = 2 = 3"

  """
  @spec join(t, String.t()) :: String.t()
  def join(enumerable, joiner \\ "")

  def join(enumerable, joiner) when is_binary(joiner) do
    reduced =
      reduce(enumerable, :first, fn
        entry, :first -> entry_to_string(entry)
        entry, acc -> [acc, joiner | entry_to_string(entry)]
      end)

    if reduced == :first do
      ""
    else
      IO.iodata_to_binary(reduced)
    end
  end

  ## reject

  defp reject_list([head | tail], fun) do
    if fun.(head) do
      reject_list(tail, fun)
    else
      [head | reject_list(tail, fun)]
    end
  end

  defp reject_list([], _fun) do
    []
  end

  @doc """
  Returns a list of elements in `enumerable` in reverse order.

  ## Examples

      iex> Enum.reverse([1, 2, 3])
      [3, 2, 1]

  """
  @spec reverse(t) :: list
  def reverse(enumerable)

  def reverse([]), do: []
  def reverse([_] = list), do: list
  def reverse([item1, item2]), do: [item2, item1]
  def reverse([item1, item2 | rest]), do: :lists.reverse(rest, [item2, item1])
  def reverse(enumerable), do: reduce(enumerable, [], &[&1 | &2])

  @doc """
  Returns a subset list of the given enumerable, from `range.first` to `range.last` positions.

  Given `enumerable`, it drops elements until element position `range.first`,
  then takes elements until element position `range.last` (inclusive).

  Positions are normalized, meaning that negative positions will be counted from the end
  (e.g. `-1` means the last element of the enumerable).
  If `range.last` is out of bounds, then it is assigned as the position of the last element.

  If the normalized `range.first` position is out of bounds of the given enumerable,
  or this one is greater than the normalized `range.last` position, then `[]` is returned.

  ## Examples

      iex> Enum.slice(1..100, 5..10)
      [6, 7, 8, 9, 10, 11]

      iex> Enum.slice(1..10, 5..20)
      [6, 7, 8, 9, 10]

      # last five elements (negative positions)
      iex> Enum.slice(1..30, -5..-1)
      [26, 27, 28, 29, 30]

      # last five elements (mixed positive and negative positions)
      iex> Enum.slice(1..30, 25..-1)
      [26, 27, 28, 29, 30]

      # out of bounds
      iex> Enum.slice(1..10, 11..20)
      []

      # range.first is greater than range.last
      iex> Enum.slice(1..10, 6..5)
      []

  """
  @doc since: "1.6.0"
  @spec slice(t, Range.t()) :: list
  def slice(enumerable, first..last) do
    {count, fun} = slice_count_and_fun(enumerable)
    corr_first = if first >= 0, do: first, else: first + count
    corr_last = if last >= 0, do: last, else: last + count
    amount = corr_last - corr_first + 1

    if corr_first >= 0 and corr_first < count and amount > 0 do
      fun.(corr_first, Kernel.min(amount, count - corr_first))
    else
      []
    end
  end

  @doc """
  Returns a subset list of the given enumerable, from `start` position with `amount` of elements if available.

  Given `enumerable`, it drops elements until element position `start`,
  then takes `amount` of elements until the end of the enumerable.

  If `start` is out of bounds, it returns `[]`.

  If `amount` is greater than `enumerable` length, it returns as many elements as possible.
  If `amount` is zero, then `[]` is returned.

  ## Examples

      iex> Enum.slice(1..100, 5, 10)
      [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

      # amount to take is greater than the number of elements
      iex> Enum.slice(1..10, 5, 100)
      [6, 7, 8, 9, 10]

      iex> Enum.slice(1..10, 5, 0)
      []

      # out of bound start position
      iex> Enum.slice(1..10, 10, 5)
      []

      # out of bound start position (negative)
      iex> Enum.slice(1..10, -11, 5)
      []

  """
  @spec slice(t, index, non_neg_integer) :: list
  def slice(_enumerable, start, 0) when is_integer(start), do: []

  def slice(enumerable, start, amount)
      when is_integer(start) and is_integer(amount) and amount >= 0 do
    slice_any(enumerable, start, amount)
  end

  @doc """
  Splits the `enumerable` in two lists according to the given function `fun`.

  Splits the given `enumerable` in two lists by calling `fun` with each element
  in the `enumerable` as its only argument. Returns a tuple with the first list
  containing all the elements in `enumerable` for which applying `fun` returned
  a truthy value, and a second list with all the elements for which applying
  `fun` returned a falsy value (`false` or `nil`).

  The elements in both the returned lists are in the same relative order as they
  were in the original enumerable (if such enumerable was ordered, e.g., a
  list); see the examples below.

  ## Examples

      iex> Enum.split_with([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end)
      {[4, 2, 0], [5, 3, 1]}

      iex> Enum.split_with(%{a: 1, b: -2, c: 1, d: -3}, fn {_k, v} -> v < 0 end)
      {[b: -2, d: -3], [a: 1, c: 1]}

      iex> Enum.split_with(%{a: 1, b: -2, c: 1, d: -3}, fn {_k, v} -> v > 50 end)
      {[], [a: 1, b: -2, c: 1, d: -3]}

      iex> Enum.split_with(%{}, fn {_k, v} -> v > 50 end)
      {[], []}

  """
  @doc since: "1.4.0"
  def split_with(enumerable, fun) do
    {acc1, acc2} =
      reduce(enumerable, {[], []}, fn entry, {acc1, acc2} ->
        if fun.(entry) do
          {[entry | acc1], acc2}
        else
          {acc1, [entry | acc2]}
        end
      end)

    {:lists.reverse(acc1), :lists.reverse(acc2)}
  end

  @doc """
  Converts `enumerable` to a list.

  ## Examples

      iex> Enum.to_list(1..3)
      [1, 2, 3]

  """
  @spec to_list(t) :: [element]
  def to_list(enumerable) when is_list(enumerable), do: enumerable
  def to_list(%_{} = enumerable), do: reverse(enumerable) |> :lists.reverse()
  def to_list(%{} = enumerable), do: Map.to_list(enumerable)
  def to_list(enumerable), do: reverse(enumerable) |> :lists.reverse()

  # helpers

  @compile {:inline, entry_to_string: 1, reduce: 3}

  defp entry_to_string(entry) when is_binary(entry), do: entry

  ## drop

  defp drop_list(list, 0), do: list
  defp drop_list([_ | tail], counter), do: drop_list(tail, counter - 1)
  defp drop_list([], _), do: []

  ## slice

  defp slice_any(enumerable, start, amount) when start < 0 do
    {count, fun} = slice_count_and_fun(enumerable)
    start = count + start

    if start >= 0 do
      fun.(start, Kernel.min(amount, count - start))
    else
      []
    end
  end

  defp slice_any(list, start, amount) when is_list(list) do
    list |> drop_list(start) |> take_list(amount)
  end

  defp slice_any(enumerable, start, amount) do
    case Enumerable.slice(enumerable) do
      {:ok, count, _} when start >= count ->
        []

      {:ok, count, fun} when is_function(fun) ->
        fun.(start, Kernel.min(amount, count - start))

      {:error, module} ->
        slice_enum(enumerable, module, start, amount)
    end
  end

  defp slice_enum(enumerable, module, start, amount) do
    {_, {_, _, slice}} =
      module.reduce(enumerable, {:cont, {start, amount, []}}, fn
        _entry, {start, amount, _list} when start > 0 ->
          {:cont, {start - 1, amount, []}}

        entry, {start, amount, list} when amount > 1 ->
          {:cont, {start, amount - 1, [entry | list]}}

        entry, {start, amount, list} ->
          {:halt, {start, amount, [entry | list]}}
      end)

    :lists.reverse(slice)
  end

  defp slice_count_and_fun(enumerable) when is_list(enumerable) do
    length = length(enumerable)
    {length, &Enumerable.List.slice(enumerable, &1, &2, length)}
  end

  defp slice_count_and_fun(enumerable) do
    case Enumerable.slice(enumerable) do
      {:ok, count, fun} when is_function(fun) ->
        {count, fun}

      {:error, module} ->
        {_, {list, count}} =
          module.reduce(enumerable, {:cont, {[], 0}}, fn elem, {acc, count} ->
            {:cont, {[elem | acc], count + 1}}
          end)

        {count, &Enumerable.List.slice(:lists.reverse(list), &1, &2, count)}
    end
  end

  defp take_list([head | _], 1), do: [head]
  defp take_list([head | tail], counter), do: [head | take_list(tail, counter - 1)]
  defp take_list([], _counter), do: []
end
