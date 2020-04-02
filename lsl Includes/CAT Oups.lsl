#ifndef INC_OUPS
#define INC_OUPS
/*
// 202001272322
*/
// GS_Script_Name

safeLoad() {
    if( llGetScriptName() != GS_Script_Name ) {
        llTriggerSound( "8ee7bb8d-cbf1-3931-1795-2fda47c0409f", 1 );
        if( llGetInventoryCreator( llGetScriptName() ) == llGetOwner() ) {
            llSay( 0, "YOU LOADED THE WRONG SCRIPT YOU DAFT FUCKING CAT!\nReload: '"+ llGetScriptName() +"'!" );
            return;
        }
        llSay( 0, "Exposed Script Name '"+ GS_Script_Name +"' Does Not Match In World Script Name '"+ llGetScriptName() +"'!\nPlease Reload: '"+ llGetScriptName() +"'" );
    }
}

#endif
//END OF FILE
