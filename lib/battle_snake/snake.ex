defmodule BattleSnake.Snake do
  alias __MODULE__
  alias BattleSnake.{Point}

  @max_health_points 100

  @type health :: :ok | {:error, any}

  @type t :: %Snake{
    id: reference,
    color: String.t,
    coords: [Point.t],
    head_url: String.t,
    name: String.t,
    taunt: String.t,
    url: String.t,
    health: health,
  }

  defstruct [
    :id,
    color: "",
    coords: [],
    head_url: "",
    name: "",
    taunt: "",
    url: "",
    health: {:error, :init},
    health_points: @max_health_points,
  ]

  def dead?(%{coords: [%{y: y, x: x} |_]}, %{width: w, height: h})
  when not y in 0..(w-1) or not x in 0..(h-1),
  do: true

  def dead?(snake, world) do
    head = hd snake.coords
    stream = Stream.flat_map(world.snakes, & tl(&1.coords))
    Enum.member? stream, head
  end

  def grow(snake, size) do
    update_in snake.coords, fn coords ->
      last = List.last coords
      new_segments = List.duplicate(last, size)
      coords ++ new_segments
    end
  end

  def len(snake) do
    length snake.coords
  end

  def head(snake) do
    hd body snake
  end

  def tail(snake) do
    tl body snake
  end

  def body(snake) do
    snake.coords
  end

  @doc "Set this snake's health_points to #{@max_health_points}"
  @spec reset_health_points(t) :: t
  def reset_health_points(snake) do
    put_in(snake.health_points, @max_health_points)
  end

  def resolve_head_to_head(snakes, acc \\ [])

  def resolve_head_to_head([], acc) do
    acc
  end

  def resolve_head_to_head(snakes, _acc) do
    snakes
    |> Enum.group_by(& hd(&1.coords))
    |> Enum.map(fn
       {_, [snake]} ->
         snake

       {_, snakes} ->
         snakes = snakes
         |> Enum.map(& {len(&1), &1})
         |> Enum.sort_by(& - elem(&1, 0))

         case snakes do
           [{size, _}, {size, _} | _] ->
             # one or more are the same size
             # all die
             nil
           [{_, snake} | victims] ->
             growth = victims
             |> Enum.map(& elem(&1, 0))
             |> Enum.sum
             growth = round(growth / 2)
             grow(snake, growth)
         end
    end) |> Enum.reject(& &1 == nil)
  end

  @doc """
  Update the snake by moving the snake's cooridinates by the vector "move".
  """
  @spec move(t, Point.t) :: t
  def move(snake, move) do
    body = body snake
    head = head snake
    body = List.delete_at(body, -1)
    body = [Point.add(head, move) | body]
    put_in(snake.coords, body)
  end
end

defimpl Poison.Encoder, for: BattleSnake.Snake do
  def encode(snake, opts) do
    attrs = [
      :url,
      :name,
      :coords
    ]

    map = %{
    }

    map = snake
    |> Map.take(attrs)
    |> Map.merge(map)

    Poison.encode!(map, opts)
  end
end
