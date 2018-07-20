defmodule Game.Channel.Gossip do
  @moduledoc """
  Callback module for Gossip
  """

  require Logger

  alias Game.Channel
  alias Game.Channels
  alias Game.Character
  alias Game.Message
  alias Game.Session

  @behaviour Gossip.Client

  @impl true
  def user_agent() do
    ExVenture.version()
  end

  @impl true
  def channels() do
    Enum.map(Channels.gossip_channels(), &(&1.gossip_channel))
  end

  @impl true
  def players() do
    Session.Registry.connected_players()
    |> Enum.map(&(&1.user.name))
  end

  @impl true
  def message_broadcast(message) do
    with {:ok, channel} <- Channels.gossip_channel(message.channel),
         true <- Raft.node_is_leader?() do
      message = Message.gossip_broadcast(channel, message)
      Channel.broadcast(channel.name, message)

      :ok
    else
      _ ->
        :ok
    end
  end

  @impl true
  def player_sign_in(game_name, player_name) do
    Logger.info(fn ->
      "Gossip - new player sign in #{player_name}@#{game_name}"
    end)

    case Raft.node_is_leader?() do
      true ->
        Session.Registry.connected_players()
        |> Enum.each(fn %{user: user} ->
          Character.notify({:user, user}, {"gossip/player-online", game_name, player_name})
        end)

      false ->
        :ok
    end
  end

  @impl true
  def player_sign_out(game_name, player_name) do
    Logger.info(fn ->
      "Gossip - new player sign out #{player_name}@#{game_name}"
    end)

    case Raft.node_is_leader?() do
      true ->
        Session.Registry.connected_players()
        |> Enum.each(fn %{user: user} ->
          Character.notify({:user, user}, {"gossip/player-offline", game_name, player_name})
        end)

      false ->
        :ok
    end
  end

  @impl true
  def players_status(game_name, player_names) do
    Logger.debug(fn ->
      "Received update for game #{game_name} - #{inspect(player_names)}"
    end)
  end

  @impl true
  def tell_received(from_game, from_player, to_player, message) do
    Logger.info(fn ->
      "Received a new tell from #{from_player}@#{from_game} to #{to_player} - #{message}"
    end)

    case Session.Registry.find_player(to_player) do
      {:ok, player} ->
        player_name = "#{from_player}@#{from_game}"
        Channel.tell({:user, player}, {:gossip, player_name}, Message.tell(%{name: player_name}, message))

        :ok

      {:error, :not_found} ->
        :ok
    end
  end
end
