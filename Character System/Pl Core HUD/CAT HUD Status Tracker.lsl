/*
// STATUS TRACKING AND HANDLING!
//
// 201925120855
*/



integer GI_Status_Interval = 15;

list GL_Status_Id = [];
list GL_Status_Effects = [];
list GL_Status_Duration = [];

setup() {
    GL_Status_Id = [];
    GL_Status_Effects = [];
    GL_Status_Duration = [];
}





default {
    state_entry() {
        setup();
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 666 ) {
            if( id == "Stat Augment" ) {
                llOwnerSay( "SAA: "+ msg );
                list data = llParseString2List( msg, [","], [] );
                if( llGetListLength( data ) != 4 ) {
                    llOwnerSay( "Err: Bad Stat Augment: '"+ msg +"'" );
                    return;
                }
                string stat = "Unknown";
                if( llList2String( data, 1 ) == "st"  ) {
                    stat = "Strength";
                } else if( llList2String( data, 1 ) == "ch"  ) {
                    stat = "Charm"; 
                } else if( llList2String( data, 1 ) == "de"  ) {
                    stat = "Dexterity";
                } else if( llList2String( data, 1 ) == "in"  ) {
                    stat = "Intelect";
                } else if( llList2String( data, 1 ) == "co"  ) {
                    stat = "Constatution";
                } else {
                    llOwnerSay( "Err: Bad Stat Augment: '"+ msg +"'" );
                    return;
                }
                llOwnerSay( "Augmented "+ stat +" by "+ llList2String( data, 2 ) +" from "+ llList2String( data, 0 ) +" for "+ (string)((integer)llList2String( data, 3 ) * GI_Status_Interval) +" Seconds" );
            } else if( id == "Stat Adjust" ) {
                llOwnerSay( "SAB: "+ msg );
                list data = llParseString2List( msg, [","], [] );
                if( llGetListLength( data ) != 3 ) {
                    llOwnerSay( "Err: Bad Stat Adjust: '"+ msg +"'" );
                    return;
                }
                if( llList2String( data, 1 ) == "he" ) {
                    llOwnerSay( "Healed by "+ llList2String( data, 2 ) +" from "+ llList2String( data, 0 ) );
                }
            }
        }
    }
}
