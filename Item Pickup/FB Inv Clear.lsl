// 201925120855





integer GI_Listen = -1;

key GK_User = NULL_KEY;






default {
    state_entry() {
        llSetText( "Clear Inv", <1,1,1>, 1 );
    }

    touch_start( integer num ) {
        //if( GK_User == NULL_KEY ) {
            GK_User = llDetectedKey( 0 );
            GI_Listen = llListen( 2121, "", "", "" );
            llRegionSayTo( llDetectedKey(0), 2121, "FB:"+ llList2Json( JSON_ARRAY, ["IChk"] ) );
            llSetTimerEvent( 15 );
        //}
    }
    
    timer() {
        llSetTimerEvent( 0 );
        llListenRemove( GI_Listen );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) != GK_User && llStringLength( msg ) <= 3 && llGetSubString( msg, 0, 2 ) != "FB:" ) {
            llOwnerSay( "ERR: "+ msg );
            return;
        }
        
        list data = llJson2List( llGetSubString( msg, 3, -1 ) );
        
        if( llToLower( llList2String( data, 0 ) ) != "items" ) {
            return;
        }
        
        integer i;
        integer num = llGetListLength( data );//-1;
        llRegionSayTo( id, 2121, "FB:"+ llList2Json( JSON_ARRAY, ["IClr"]+ llList2List( data, 1, num ) +["KRR"] ) );
    }
}
