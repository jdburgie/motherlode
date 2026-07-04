--  Motherlode
--  Copyright (c) 2020 Fabien Chouteau

package Title_Screen is

   type Action is (New_Game, Continue_Game);

   function Run return Action;

end Title_Screen;
