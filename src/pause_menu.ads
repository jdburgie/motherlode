--  Motherlode

package Pause_Menu is

   type Action is (Resume, Save_Game, Save_And_Quit);

   function Run return Action;

end Pause_Menu;
