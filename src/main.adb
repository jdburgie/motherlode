--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

with Motherload;
with Title_Screen;

with Arith_64;
pragma Unreferenced (Arith_64);

procedure Main is
begin

   loop
      Motherload.Run
        (case Title_Screen.Run is
            when Title_Screen.New_Game      => False,
            when Title_Screen.Continue_Game => True);
   end loop;
end Main;
