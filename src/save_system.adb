--  Motherlode

with Player;
with World;

package body Save_System is

   type Game_State is record
      Player_State : Player.Save_State;
      Ground       : World_Image;
   end record;

   Saved : Game_State;
   Valid : Boolean := False;

   --------------
   -- Has_Save --
   --------------

   function Has_Save return Boolean
   is (Valid);

   ------------------
   -- Save_Current --
   ------------------

   procedure Save_Current is
   begin
      Saved.Player_State := Player.Export_State;

      for Index in World_Index loop
         Saved.Ground (Index) :=
           HAL.UInt8 (World.Export_Cell (World.Ground (Index)));
      end loop;

      Valid := True;
   end Save_Current;

   ------------------
   -- Load_Current --
   ------------------

   procedure Load_Current (Loaded : out Boolean) is
   begin
      Loaded := Valid;

      if not Valid then
         return;
      end if;

      for Index in World_Index loop
         World.Ground (Index) :=
           World.Import_Cell (World.Persisted_Cell (Saved.Ground (Index)));
      end loop;

      Player.Import_State (Saved.Player_State);
   end Load_Current;

end Save_System;
