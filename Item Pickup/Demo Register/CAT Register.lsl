/*
// 202001270212
// 202001272301
*/

#define DEBUG
#include <debug.lsl>

#include <CAT Filters.lsl>
#include <CAT Encode.lsl>
#include <CAT Chan Ref.lsl> // link message chan ref




integer GI_Listen = -1; // listen for verification


integer GI_Charge = 100;
string GS_Encode_Key;
string GS_End_Flag; // verification flag


key GK_Subject = NULL_KEY;



/////////////////
//  FUNCTIONS  //
/////////////////


// badly named. Change to something clearer
// initalises contact to add item to someones inventory
integer verify( key id ) {
    GK_Subject = id;
    string json = llList2Json( JSON_ARRAY, ["CPay" , (string)GI_Charge, GS_Encode_Key, GS_End_Flag] );
    if( JSON_INVALID == json ) {
        return FALSE;
    }
    llRegionSayTo( id, GI_CHAN_INV, "FB:"+ json );
    return TRUE;
}







//////////////
//  STATES  //
//////////////


default {
    state_entry() {
        GS_Encode_Key = compileKey( "CPay", (string)GI_Charge );
    }
    
    touch_start( integer num ) {
        if( GK_Subject != NULL_KEY ) {
            llOwnerSay( "This item is busy at the moment! Please try again in a moment." );
            return;
        }
        GI_Listen = llListen( GI_CHAN_INV, "", "", "" );
        GS_End_Flag = ranStr( 3 );
        verify( llDetectedKey( 0 ) );
        llSetTimerEvent( 10 );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        GK_Subject = NULL_KEY;
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) == GK_Subject && llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            list data = llJson2List( llGetSubString( msg, 3, -1 ) );
            if( llList2String( data, 0 ) == "ACK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llTriggerSound( "664e481d-9be4-7241-eb7a-ace7a5da5e3f", 1 );
                llRegionSayTo( GK_Subject, 0, "You paid for this purchase" );
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                llSetTimerEvent( 0 );
            } else if( llList2String( data, 0 ) == "NAK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llRegionSayTo( GK_Subject, 0, "Insufficient Funds" );
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                llSetTimerEvent( 0 );
            }
        }
    }
}


