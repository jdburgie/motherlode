--  Motherlode

with HAL; use HAL;

with PyGamer; use PyGamer;
with PyGamer.Controls;
with PyGamer.Screen;
with PyGamer.Time;

with Parameters;
with Render;
with Save_System;
with Sound;

package body Pause_Menu is

   Selected : Action := Resume;
   Saved_Message_TTL : Natural := 0;

   ---------
   -- Img --
   ---------

   function Img (Item : Action) return String
   is (case Item is
          when Resume        => "Resume",
          when Save_Game     => "Save Game",
          when Save_And_Quit => "Save and Quit");

   -----------------
   -- Draw_Screen --
   -----------------

   procedure Draw_Screen (FB : in out HAL.UInt16_Array) is
      Y : Natural := 36;
   begin
      FB := (others => 0);

      Render.Draw_String_Center (FB, "- Paused -", Screen.Width / 2, 16);

      for Item in Action loop
         Render.Draw_String (FB, Img (Item), 36, Y);

         if Selected = Item then
            Render.Draw_Tile (FB, 16, Y - 4, 8);
         end if;

         Y := Y + 18;
      end loop;

      if Saved_Message_TTL > 0 then
         Render.Draw_String_Center (FB, "Saved", Screen.Width / 2, 108);
      else
         Render.Draw_String_Center (FB, "A select  B resume", Screen.Width / 2, 108);
      end if;
   end Draw_Screen;

   ---------
   -- Run --
   ---------

   function Run return Action is
      Period : constant Time.Time_Ms := Parameters.Frame_Period;
      Next_Release : Time.Time_Ms := Time.Clock;
   begin
      loop
         Controls.Scan;

         if Controls.Falling (Controls.Down) then
            if Selected = Action'Last then
               Selected := Action'First;
            else
               Selected := Action'Succ (Selected);
            end if;
         elsif Controls.Falling (Controls.Up) then
            if Selected = Action'First then
               Selected := Action'Last;
            else
               Selected := Action'Pred (Selected);
            end if;
         end if;

         if Controls.Falling (Controls.B) then
            return Resume;
         elsif Controls.Falling (Controls.A)
           or else Controls.Falling (Controls.Start)
         then
            if Selected = Save_Game then
               Save_System.Save_Current;
               Saved_Message_TTL := 30;
            else
               return Selected;
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

         if Saved_Message_TTL > 0 then
            Saved_Message_TTL := Saved_Message_TTL - 1;
         end if;

         Sound.Tick;

         Time.Delay_Until (Next_Release);
         Next_Release := Next_Release + Period;
      end loop;
   end Run;

end Pause_Menu;
