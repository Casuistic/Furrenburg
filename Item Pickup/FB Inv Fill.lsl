
// 201925120855


integer GI_Listen = -1;

key GK_User = NULL_KEY;

list GL_Item_Name = [   
        "Test Drugs", 
        "Test Good Shit",
        "Test Crate",
        "Test Tools"
    ];
    
list GL_Item_Desc = [   
        "Dummy Obj 01", 
        "Dummy Obj 02",
        "Dummy Obj 03",
        "Dummy Obj 04"
    ];

list GL_Item_Icon = [
        "21a3600f-67cd-2faf-ac8c-808a1521c979", 
        "8234981c-6a98-69fe-204d-cb007ec0bbbc", 
        "a2b79dc5-885c-1575-bb21-78e23b121b7b",
        "86ed7b5c-7831-7138-a063-0e89393b7da3"
    ];

list GL_Item_Susp = [
        1, 
        2,
        0,
        0
    ];


string GS_Salt = "CAT_SPAWN_PAD!"; // salt for verification code











integer addItem( key id ) {
    integer index = (integer)llFloor( llFrand( llGetListLength( GL_Item_Name ) ) );
    string json = llList2Json( JSON_OBJECT, [
                "name", llList2String( GL_Item_Name, index ),
                "desc", llList2String( GL_Item_Desc, index ),
                "img", llList2String( GL_Item_Icon, index ),
                "susp", llList2String( GL_Item_Susp, index )
            ] );
    string var_key = encode( llGetKey(), json );
    llRegionSayTo( id, 2121, "FB:"+ llList2Json( JSON_ARRAY, ["IAdd", json, var_key, "OOO"] ) );
    return TRUE;
}




integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

string encode( key id, string text ) {
    string text = llXorBase64( llStringToBase64( GS_Salt + text ), llIntegerToBase64( key2Chan(id,1000000,1000000) ) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}





default {
    state_entry() {
        llSetText( "Fill Inv", <1,1,1>, 1 );
    }

    touch_start( integer num ) {
        //if( GK_User == NULL_KEY ) {
            GK_User = llDetectedKey( 0 );
            GI_Listen = llListen( 2121, "", "", "" );
            llRegionSayTo( llDetectedKey(0), 2121, "FB:IChk");
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
        
        llOwnerSay( "Test: "+ llDumpList2String( data, "//" ) );
        
        integer i;
        for( i=llGetListLength( data )-2; i<6; ++i ) {
            addItem( id );
        }
    }
}
