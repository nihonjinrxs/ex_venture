defmodule Web.UserTest do
  use Data.ModelCase

  alias Game.Session
  alias Web.Room
  alias Web.User
  alias Web.Zone

  setup do
    user = create_user(%{name: "user", password: "password", flags: ["admin"]})

    {:ok, zone} = Zone.create(%{name: "The Forest"})
    {:ok, room} = Room.create(zone, room_attributes(%{}))

    %{user: user, room: room}
  end

  test "teleporting a player", %{user: user, room: room} do
    Session.Registry.register(user)

    {:ok, user} = User.teleport(user, room.id |> Integer.to_string())

    room_id = room.id

    assert user.save.room_id == room_id
    assert_receive {:"$gen_cast", {:teleport, ^room_id}}
  end

  test "teleporting a player - only updates if player not in the game", %{user: user, room: room} do
    {:ok, user} = User.teleport(user, room.id |> Integer.to_string())

    room_id = room.id

    assert user.save.room_id == room_id
    refute_receive {:"$gen_cast", {:teleport, ^room_id}}
  end
end
