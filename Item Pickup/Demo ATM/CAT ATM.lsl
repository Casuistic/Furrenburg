/*
// 202001272322
// 202001272301
*/

#undef DEBUG
#include <debug.lsl>

#include <CAT Filters.lsl>
#include <CAT Encode.lsl>
#include <CAT Chan Ref.lsl> // link message chan ref



string GS_JSON_Data;
string GS_Encode_Key;
string GS_End_Flag;


integer GI_Listen;

key GK_Subject = NULL_KEY;





integer verify( key id ) {
    GK_Subject = id;
    string json = llList2Json( JSON_ARRAY, ["CMod" ,GS_JSON_Data, GS_Encode_Key, GS_End_Flag] );
    if( JSON_INVALID == json ) {
        return FALSE;
    }
    llRegionSayTo( id, GI_CHAN_INV, "FB:"+ json );
    return TRUE;
}





default {
    state_entry() {
        GS_JSON_Data = "100";
        GS_Encode_Key = encode( llGetKey(), "CMod", GS_JSON_Data );
    }
    
    touch_start( integer num ) {
        if( GK_Subject == NULL_KEY && llDetectedType( 0 ) & AGENT ) {
        
            llListenRemove( GI_Listen );
            GI_Listen = llListen( GI_CHAN_INV, "", "", "" );
            
            llSetTimerEvent( 10 );
            GS_End_Flag = ranStr( 3 );
            
            if( verify( llDetectedKey( 0 ) ) ) {
                llSetTimerEvent( 10 );
            }
        }
    }
    
    timer() {
        llSetTimerEvent(0);
        llListenRemove( GI_Listen );
        GK_Subject = NULL_KEY;
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) == GK_Subject && llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            list data = llJson2List( llGetSubString( msg, 3, -1 ) );
            if( llList2String( data, 0 ) == "ACK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llTriggerSound( "77a018af-098e-c037-51a6-178f05877c6f", 1 );
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                llSetTimerEvent( 0 );
            } else if( llList2String( data, 0 ) == "NAK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                llSetTimerEvent( 0 );
            }
        }
    }
}
