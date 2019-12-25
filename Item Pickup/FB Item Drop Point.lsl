// 201925120855


integer GB_Quick = FALSE;
integer GI_Rng = 3;


integer GI_Last = -1;
list GL_Lines = [
     "Test Dialog 01"
];

list GL_Agents = [];

list GL_Seek = [
        "Exotic Dildo",
        "BUTALBITAL",
        "Jagar Bottle"
    ];

integer GI_Listen = -1;


string GS_End_Flag = "DUP";

integer GI_Coin_Count = 0;

list GL_Known_Agents = [];


integer GI_Inv_Chan = 2121;


string GS_Salt = "CAT_SPAWN_PAD!"; // salt for verification code









zero() {
    GB_Quick = FALSE;
    hatch( FALSE );
    llSensorRepeat( "", "", AGENT_BY_LEGACY_NAME, GI_Rng, PI/2, 0.5 );
    rotation rrot = llGetRootRotation();
    vector detected = <10,0,0> / rrot;
    vector pos = llGetPos();
    rotation rot = llRotBetween( <1.0, 0.0, 0.0>, llVecNorm( <detected.x, detected.y, detected.z> - pos ) ) / rrot;
    llMessageLinked( LINK_SET, 5, (string)detected, "L2" );
}


active() {
    GB_Quick = TRUE;
    llSensorRepeat( "", "", AGENT_BY_LEGACY_NAME, GI_Rng, PI/2, 0.5 );
    hatch( TRUE );
    GI_Listen = llListen( 2121, "", "", "" );
}


hatch( integer open ) {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=2; i<=num; ++i ) {
        if( llGetLinkName( i ) == ".hatch" ) {
            if( open ) {
                llSetLinkPrimitiveParamsFast( i, [PRIM_POS_LOCAL, <-4.500000, 0.901281, 0.099998>] );
            } else {
                llSetLinkPrimitiveParamsFast( i, [PRIM_POS_LOCAL,  <-4.500000, 0.676029, 0.099998>] );
            }
        }
    }
}


chat( key id ) {
    integer count = 10;
    integer line;
    while( GI_Last == (line = (integer)llFloor( llFrand( llGetListLength( GL_Lines ))))) {
        count--;
    }
    GI_Last = line;
    llRegionSayTo( llGetOwnerKey( id ), 0, llList2String( GL_Lines, GI_Last ) );
}



integer isKnownAgent( key id ) {
    return llListFindList( GL_Known_Agents, [id] ) != -1;
}

logAgent( key id ) {
    GL_Known_Agents += id;
    if( llGetListLength( GL_Known_Agents ) > 10 ) {
        GL_Known_Agents = llList2List( GL_Known_Agents, llGetListLength( GL_Known_Agents )-10, -1 );
    }
}






// uuid to integer
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


integer isValidAction( key id, string data, string ver ) {
    return ( encode( id, data ) == ver );
}










default {
    state_entry() {
        zero();
    }

    sensor( integer num ) {
        if( !GB_Quick ) {
            active();
        }

        list agents = [];

        integer i;
        for( i=0; i<num; ++i ) {
            key id = llDetectedKey(i);
            agents += id;
            if( llListFindList( GL_Agents, [id] ) == -1 ) {
                if( isKnownAgent( id ) ) {
                    logAgent( id );
                    chat( id );
                }
                llRegionSayTo( id, GI_Inv_Chan, "FB:"+ llList2Json( JSON_ARRAY, ["IChk"] ) );
            }
        }

        GL_Agents = agents;

        rotation rrot = llGetRootRotation();
        vector detected = llDetectedPos( 0 ) + <0,0,0.5>;
        vector pos = llGetPos();
        rotation rot = llRotBetween( <1.0, 0.0, 0.0>, llVecNorm( <detected.x, detected.y, detected.z> - pos ) ) / rrot;

        llMessageLinked( LINK_SET, 5, (string)detected, "L2" );
    }

    
    listen( integer chan, string name, key id, string msg ) {
        if( llListFindList( GL_Agents, [llGetOwnerKey( id )] ) == -1 || llStringLength( msg ) <= 3 || llGetSubString( msg, 0, 2 ) != "FB:" ) {
            return;
        }
        
        list data = llJson2List( llGetSubString( msg, 3, -1 ) );
        
        if( llToLower( llList2String( data, 0 ) ) != "items" ) {
            if( llList2String( data, -1 ) == GS_End_Flag ) {
                GI_Coin_Count += 1;
                llSetTimerEvent( 0.5 );
                //llRegionSayTo( llGetOwnerKey( id ), 0, "I'll be taking these off your hands." );
            }
            return;
        }
        
        integer i;
        integer num = llGetListLength( data );
        integer found = FALSE;
        for( i=0; i<num; ++i ) {
            if( llListFindList( GL_Seek, llList2List( data, i, i ) ) != -1 ) {
                string item = llList2String( data, i );
                string ver_key = encode( llGetKey(), item );
                llRegionSayTo( id, GI_Inv_Chan, "FB:"+ llList2Json( JSON_ARRAY, ["IDel", item, ver_key, GS_End_Flag] ) );
                found = TRUE;
            }
        }

        if( found ) {
            llRegionSayTo( llGetOwnerKey( id ), 0, "I'll be taking these off your hands." );
        } else {
            llRegionSayTo( llGetOwnerKey( id ), 0, "What is this shit? Try getting me something worth my time!" );
        }
    }

    no_sensor() {
        if( GB_Quick ) {
            GL_Agents = [];
            zero();
        }
    }
    
    timer() {
        GI_Coin_Count -= 1;
        if( GI_Coin_Count <= 0 ) {
            llSetTimerEvent( 0 );
        } else {
            llSetTimerEvent( 0.25 );
        }
        llTriggerSound( "501242bf-e2ff-477a-36a8-84d6fcbb9571", 1 );
    }
}


