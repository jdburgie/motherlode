--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Time;
with PyGamer.Controls; use PyGamer.Controls;
with PyGamer.Screen;

with Parameters;
with Render; use Render;
with World; use World;
with Save_System;
with Sound;

package body Title_Screen is

   type Menu_Item is (Continue_Item, New_Game_Item, Credits_Item);

   Selected : Menu_Item := New_Game_Item;
   Credits : Boolean := False;
   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is
   begin
      FB := (others => 0);

      if Credits then
         Draw_String_Center (FB, "- Credits -", Screen.Width / 2, 20);

         Draw_String (FB, "Original game:", 0, 30);
         Draw_String (FB, "   xgenstudios.com", 0, 40);
         Draw_String (FB, "Art:  kenney.nl", 0, 55);
         Draw_String (FB, "Font: nfggames.com", 0, 70);
         Draw_String (FB, "Code: Fabien.C", 0, 85);
      else

         Draw_String_Center (FB, "--------------", Screen.Width / 2, 25);
         Draw_String_Center (FB, "- Motherlode -", Screen.Width / 2, 25 + 8);
         Draw_String_Center (FB, "--------------", Screen.Width / 2, 25 + 16);

         if Save_System.Has_Save then
            Draw_String (FB, "Continue", Screen.Width / 3, 25 + 40);
         else
            Draw_String (FB, "Continue", Screen.Width / 3, 25 + 40);
            Draw_H_Line (FB, Screen.Width / 3, 25 + 49, 64, RGB565 (40, 40, 40));
         end if;

         Draw_String (FB, "New game", Screen.Width / 3, 25 + 58);
         Draw_String (FB, "Credits", Screen.Width / 3, 25 + 76);

         Draw_Tile
           (FB,
            Screen.Width / 3 - 20,
            (case Selected is
                when Continue_Item => 25 + 40 - 4,
                when New_Game_Item => 25 + 58 - 4,
                when Credits_Item  => 25 + 76 - 4),
            8);

         for X in 0 .. (Screen.Width / Cell_Size) - 1 loop
            Draw_Tile (FB, X * Cell_Size, 7 * Cell_Size, 1);
         end loop;
      end if;
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   function Run return Action is

      Period : constant Time.Time_Ms := Parameters.Frame_Period;
      Next_Release : Time.Time_Ms;

   begin
      Next_Release := Time.Clock;

      Sound.Play_Music;

      --  First scan to avoid detectin a falling edge when a button is pressed
      --  during reset.
      Controls.Scan;

      loop
         Controls.Scan;

         if Falling (A)
           or else
            Falling (B)
           or else
            Falling (Start)
           or else
            Falling (Sel)
         then
            if Credits then
               Credits := False;
            elsif Selected = Continue_Item then
               if Save_System.Has_Save then
                  return Continue_Game;
               end if;
            elsif Selected = New_Game_Item then
               return New_Game;
            else
               Credits := True;
            end if;
         end if;

         if Falling (Down) then
            if Selected = Menu_Item'Last then
               Selected := Menu_Item'First;
            else
               Selected := Menu_Item'Succ (Selected);
            end if;
         elsif Controls.Falling (Controls.Up) then
            if Selected = Menu_Item'First then
               Selected := Menu_Item'Last;
            else
               Selected := Menu_Item'Pred (Selected);
            end if;
         end if;

         if Render.Flip then
            Render.Refresh_Screen (Render.FB1'Access);
            Draw_Screen (Render.FB2);
         else
            Render.Refresh_Screen (Render.FB2'Access);
            Draw_Screen (Render.FB1);
         end if;
         Render.Flip := not Render.Flip;

         Sound.Tick;

         Time.Delay_Until (Next_Release);
         Next_Release := Next_Release + Period;
      end loop;
   end Run;

end Title_Screen;
