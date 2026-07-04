--  Motherlode

with HAL;
with World;

package Save_System is

   subtype World_Index is Natural
     range 0 .. (World.Ground_Width * World.Ground_Depth) - 1;

   type World_Image is array (World_Index) of HAL.UInt8;

   function Has_Save return Boolean;

   procedure Save_Current;
   procedure Load_Current (Loaded : out Boolean);

end Save_System;
