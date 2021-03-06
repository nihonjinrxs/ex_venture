defmodule Game.OverworldTest do
  use Data.ModelCase

  alias Data.Zone
  alias Game.Color
  alias Game.Overworld

  describe "splitting up an overworld id" do
    test "pulls out zone id and x,y" do
      assert Overworld.split_id("3:1,2") == {3, %{x: 1, y: 2}}
    end
  end

  describe "overworld id to zone id and sector" do
    test "pulls out zone id and sector" do
      assert Overworld.sector_from_overworld_id("3:1,2") == {3, "0-0"}
    end
  end

  describe "calculating sectors" do
    setup do
      %{overworld: basic_overworld_map()}
    end

    test "sector every 10x10", %{overworld: overworld} do
      sectors = Overworld.break_into_sectors(overworld)

      assert length(sectors) == 50
    end

    test "a cell's sector" do
      assert Overworld.cell_sector(%{x: 3, y: 3}) == "0-0"
      assert Overworld.cell_sector(%{x: 97, y: 54}) == "9-5"
    end
  end

  describe "overworld exits" do
    setup do
      zone = %Zone{id: 1, overworld_map: basic_overworld_map(), exits: []}
      %{zone: zone}
    end

    test "top left", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 0, y: 0}) == [
        %{id: "overworld:1:0,0", direction: "south", start_id: "overworld:1:0,0", finish_id: "overworld:1:0,1"},
        %{id: "overworld:1:0,0", direction: "east", start_id: "overworld:1:0,0", finish_id: "overworld:1:1,0"},
        %{id: "overworld:1:0,0", direction: "south east", start_id: "overworld:1:0,0", finish_id: "overworld:1:1,1"},
      ]
    end

    test "top right", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 99, y: 0}) == [
        %{id: "overworld:1:99,0", direction: "south", start_id: "overworld:1:99,0", finish_id: "overworld:1:99,1"},
        %{id: "overworld:1:99,0", direction: "west", start_id: "overworld:1:99,0", finish_id: "overworld:1:98,0"},
        %{id: "overworld:1:99,0", direction: "south west", start_id: "overworld:1:99,0", finish_id: "overworld:1:98,1"},
      ]
    end

    test "bottom left", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 0, y: 49}) == [
        %{id: "overworld:1:0,49", direction: "north", start_id: "overworld:1:0,49", finish_id: "overworld:1:0,48"},
        %{id: "overworld:1:0,49", direction: "east", start_id: "overworld:1:0,49", finish_id: "overworld:1:1,49"},
        %{id: "overworld:1:0,49", direction: "north east", start_id: "overworld:1:0,49", finish_id: "overworld:1:1,48"},
      ]
    end

    test "bottom right", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 99, y: 49}) == [
        %{id: "overworld:1:99,49", direction: "north", start_id: "overworld:1:99,49", finish_id: "overworld:1:99,48"},
        %{id: "overworld:1:99,49", direction: "west", start_id: "overworld:1:99,49", finish_id: "overworld:1:98,49"},
        %{id: "overworld:1:99,49", direction: "north west", start_id: "overworld:1:99,49", finish_id: "overworld:1:98,48"},
      ]
    end

    test "center", %{zone: zone} do
      assert Overworld.exits(zone, %{x: 1, y: 1}) == [
        %{id: "overworld:1:1,1", direction: "north", start_id: "overworld:1:1,1", finish_id: "overworld:1:1,0"},
        %{id: "overworld:1:1,1", direction: "south", start_id: "overworld:1:1,1", finish_id: "overworld:1:1,2"},
        %{id: "overworld:1:1,1", direction: "east", start_id: "overworld:1:1,1", finish_id: "overworld:1:2,1"},
        %{id: "overworld:1:1,1", direction: "west", start_id: "overworld:1:1,1", finish_id: "overworld:1:0,1"},
        %{id: "overworld:1:1,1", direction: "north west", start_id: "overworld:1:1,1", finish_id: "overworld:1:0,0"},
        %{id: "overworld:1:1,1", direction: "north east", start_id: "overworld:1:1,1", finish_id: "overworld:1:2,0"},
        %{id: "overworld:1:1,1", direction: "south west", start_id: "overworld:1:1,1", finish_id: "overworld:1:0,2"},
        %{id: "overworld:1:1,1", direction: "south east", start_id: "overworld:1:1,1", finish_id: "overworld:1:2,2"},
      ]
    end

    test "default empty spaces are not an exit" do
      map = [
        %{x: 5, y: 5, s: ".", c: "green"},
        %{x: 5, y: 4, s: " ", c: nil},
        %{x: 5, y: 6, s: ".", c: "green"},
        %{x: 4, y: 5, s: " ", c: nil},
        %{x: 6, y: 5, s: " ", c: nil},
      ]
      zone = %Zone{id: 1, overworld_map: map, exits: []}

      assert Overworld.exits(zone, %{x: 5, y: 5}) == [
        %{id: "overworld:1:5,5", direction: "south", start_id: "overworld:1:5,5", finish_id: "overworld:1:5,6"}
      ]
    end

    test "when a saved exit is there", %{zone: zone} do
      room_exit = %{id: 1, direction: "east", start_id: "overworld:1:0,0", finish_id: 1}
      zone = %{zone | exits: [room_exit]}

      assert Overworld.exits(zone, %{x: 0, y: 0}) == [
        %{id: "overworld:1:0,0", direction: "south", start_id: "overworld:1:0,0", finish_id: "overworld:1:0,1"},
        room_exit,
        %{id: "overworld:1:0,0", direction: "south east", start_id: "overworld:1:0,0", finish_id: "overworld:1:1,1"},
      ]
    end
  end

  describe "loading the map" do
    setup do
      zone = %Zone{id: 1, overworld_map: basic_overworld_map()}
      %{zone: zone}
    end

    test "generate a zoomed in map around the cell", %{zone: zone} do
      expected_map = """
                  . . . . . . .             
              . . . . . . . . . . .         
            . . . . . . . . . . . . .       
          . . . . . . . . . . . . . . .     
        . . . . . . . . . . . . . . . . .   
        . . . . . . . . . . . . . . . . .   
      . . . . . . . . . . . . . . . . . . . 
      . . . . . . . . . . . . . . . . . . . 
      . . . . . . . . . . . . . . . . . . . 
      . . . . . . . . . X . . . . . . . . . 
      . . . . . . . . . . . . . . . . . . . 
      . . . . . . . . . . . . . . . . . . . 
      . . . . . . . . . . . . . . . . . . . 
        . . . . . . . . . . . . . . . . .   
        . . . . . . . . . . . . . . . . .   
          . . . . . . . . . . . . . . .     
            . . . . . . . . . . . . .       
              . . . . . . . . . . .         
                  . . . . . . .             

      """

      actual_map =
        zone
        |> Overworld.map(%{x: 30, y: 30})
        |> Color.strip_color()
        |> String.trim()

      assert actual_map == String.trim(expected_map)
    end
  end
end
