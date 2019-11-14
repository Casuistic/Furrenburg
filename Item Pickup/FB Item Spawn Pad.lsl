//
//
//
//
// 201911121730
// 201911131622
// 201911141249




integer chan = -100; // used for death command to rezzed display item
integer GI_Chan_Inv = 2121;

key GK_Rezzed;

key GK_Subject = NULL_KEY; // potencial pickup target used for listen filtering




integer GI_Respawn_Time = 5;

string GS_Pickup_Sound = "bd884944-ee8c-1b34-96ee-27777eba991a";
string GS_Respawn_Sound = "0a56abd7-4531-3786-118e-e2d5dbb6c66f";

string GS_Item_Name = ""; // item name
key GK_Item_Img  = NULL_KEY; // item image

integer GI_Item_Susp = 0; // suspishon to add when item picked up


vector GV_Pad_Colour = <1,1,1>; // pad colour on valid state



string GS_DataNote = "Data"; // notecard name to be loaded
integer GI_DataNote_Line; // current loading NC line
key GK_Dataserver_Ref; // used during notecard loading

key GK_LoadedCard = NULL_KEY; // notecard key / reloaded if not found on state change



integer GI_Listen = -1; // listen for verification
string GS_End_Flag = "VerFlag"; // verification flag






/////////////////
//  FUNCTIONS  //
/////////////////


// remove rezed display item
clear() {
    if( GK_Rezzed != NULL_KEY ) {
        llRegionSayTo( GK_Rezzed, chan, "DIE" );
        llTriggerSound( GS_Pickup_Sound, 1 );
        GK_Rezzed = NULL_KEY;
    }
}

// rez the internal display object
integer rez() {
    string name = "";
    integer num = llGetInventoryNumber( INVENTORY_OBJECT );
    if( num != 0 ) {
        name = llGetInventoryName( INVENTORY_OBJECT, 0 );
        llRezObject( name, llGetPos()+<0,0,0.35>, ZERO_VECTOR, ZERO_ROTATION, chan );
        llTriggerSound( GS_Respawn_Sound, 1 );
        return TRUE;
    }
    return FALSE;
}


// badly named. Change to something clearer
// initalises contact to add item to someones inventory
integer verify( key id ) {
    GK_Subject = id;
    string space = ",";
    llRegionSayTo( id, GI_Chan_Inv, "FB:IAdd:"+ GS_Item_Name +space+ (string)GK_Item_Img +space+ (string)GI_Item_Susp +":"+ GS_End_Flag );
    return TRUE;
}


// verify all core values are valid
integer isReady() {
    if( GI_Respawn_Time <= 0 ) {
        return FALSE;
    }
    if( GS_Item_Name == "" ) {
        return FALSE;
    }
    if( GK_Item_Img == "" || GK_Item_Img == NULL_KEY ) {
        return FALSE;
    }
    return TRUE;
}


// notecard value parsing
parse( string raw ) {
    list data = llParseString2List( raw, [";"], [] );
    
    integer i;
    integer num = llGetListLength( data );
    for( i=0; i<num; ++i ) {
        string value = llStringTrim( llList2String( data, i ), STRING_TRIM );
        integer index = llSubStringIndex( value, "=" );
        if( index != -1 ) {
            integer end = llStringLength( value )-1;
            string tag = "NO_KEY";
            if( index != 0 ) {
                tag = llToLower( llGetSubString( value, 0, (index-1) ) );
            }
            string val = "NO_VAL";
            if( index < end ) {
                val = llGetSubString( value, (index+1), -1 );
            }
            
            if( tag == "item_name" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Item_Name = val;
            } else if( tag == "item_icon" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GK_Item_Img = (key)val;
            } else if( tag == "item_susp" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GI_Item_Susp = (integer)val;
            } else if( tag == "item_spawn_time" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GI_Respawn_Time = (integer)val;
            } else if( tag == "pickup_sound" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Pickup_Sound = (key)val;
            } else if( tag == "respawn_sound" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Respawn_Sound = (key)val;
            } else if( tag == "pad_colour" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GV_Pad_Colour = (vector)val;
            } else {
                llOwnerSay( "Loaded Unknown Info: '"+ tag +"' = '"+ val +"'" );
            }
        }
    }
}


// handle error appearance
error( integer err ) {
    if( ! err ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
                    PRIM_COLOR, 1, GV_Pad_Colour, 1, 
                    PRIM_TEXTURE, 1, "a0272345-9789-d187-4184-2e0815b2b1da", <1,1,0>, <0,0,0>, 0
                ] );
        llSetLinkTextureAnim( LINK_THIS, FALSE, 1, 0, 0, 0.0, 0.0, 1.0 );
    } else {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [
                    PRIM_COLOR, 1, <1,0,0>, 1, 
                    PRIM_TEXTURE, 1, "ffea530a-13be-969e-23c0-0d0c9f206247", <1,1,0>, <0,0,0>, 0
                ] );
        llSetLinkTextureAnim( LINK_THIS, ANIM_ON | SMOOTH | LOOP, 1, 1000, 1, 0.0, 1000.0, 100.0 );
    }
}


// used to generate verification flag
string ranStr( integer length ) {
    string chars = "1234567890abcdefghijklmnopqrstuvwxyz";
    integer len = llStringLength( chars );
    string output;
    integer i;
    integer index;
    do {
       index = (integer) llFrand(len);
       output += llGetSubString(chars, index, index);
    } while( ++i < length );                                                    
    return output;
}







//////////////
//  STATES  //
//////////////


default {
    state_entry() {
        llWhisper( chan, "DIE" );
        error( FALSE );
        //state respawn;
        
        if( llGetInventoryType( GS_DataNote ) == INVENTORY_NONE ) {
            llOwnerSay( "Notecard '"+ GS_DataNote +"' Not Found!" );
            state broken;
        }
        
        llSetText( "Loading...", <1,1,1>, 1.0 );
        
        GK_LoadedCard = llGetInventoryKey( GS_DataNote );
        
        GI_DataNote_Line = 0;
        GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, GI_DataNote_Line );
        
    }

    state_exit() {
        llSetText( "", <1,1,1>, 0.0 );
        error( FALSE );
    }
    
    on_rez( integer peram ) {
        llResetScript();
    }
    
    dataserver(key keyQueryId, string strData) {
        if ( keyQueryId == GK_Dataserver_Ref ) {
            llSetTimerEvent( 0 );
            GK_Dataserver_Ref = NULL_KEY;
            if (strData == EOF) {
                if( isReady() ){
                    state respawn;
                }
                state broken;
            }
            
            strData = llStringTrim(strData, STRING_TRIM_HEAD);
            if (llGetSubString (strData, 0, 0) != "#") { // skip comments
                //llOwnerSay( strData );
                parse( strData );
            }
            
            llSetTimerEvent( 1.5 );
        }
    }
    
    timer() {
        if( GK_Dataserver_Ref == NULL_KEY ) { // next line
            GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, ++GI_DataNote_Line);
            llSetTimerEvent( 15 );
        } else { // retry last
            GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, GI_DataNote_Line);
            llSetTimerEvent( 15 );
        }
    }
}


state broken {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        llSetText( "Error", <1,1,1>, 1 );
        error( TRUE );
    }
    
    state_exit() {
        llSetText( "", <1,1,1>, 1 );
        error( FALSE );
    }
}


state ready {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    collision_start( integer num ) {
        if( GK_Rezzed == NULL_KEY ) {
            state respawn;
        }
        if( llDetectedType( 0 ) & AGENT_BY_LEGACY_NAME ) {
            GI_Listen = llListen( GI_Chan_Inv, "", "", "" );
            if( GK_Subject == NULL_KEY && verify( llDetectedKey( 0 ) ) ) {
                llSetTimerEvent( 10 );
            }
        }
    }
    
    listen( integer chan, string name,  key id, string msg ) {
        if( llGetOwnerKey( id ) == GK_Subject && llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            list data = llParseString2List( llGetSubString( msg, 3, -1 ), [":"], [] );
            if( llList2String( data, 0 ) == "ACK" && llList2String( data, 1 ) == GS_End_Flag ) {
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                state respawn;
            } else if( llList2String( data, 0 ) == "NAK" && llList2String( data, 1 ) == GS_End_Flag ) {
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
            }
        }
    }
    
    state_entry() {
        GS_End_Flag = ranStr( 3 );
        GK_Subject = NULL_KEY;
    }
    
    state_exit() {
        llSetTimerEvent( 0 );
    }
    
    timer() {
        llListenRemove( GI_Listen );
        GK_Subject = NULL_KEY;
        llSetTimerEvent( 0 );
    }
}


state spawn {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        clear();
        
        if( GK_LoadedCard != llGetInventoryKey( GS_DataNote ) ) {
            llResetScript();
        }
        
        if( !rez() ) {
            error( TRUE );
        }
    }
    
    object_rez( key id ) {
        llSleep( 1 ); // wait 1 second for initalisation
        GK_Rezzed = id;
        state ready;
    }
}


state respawn {
    on_rez( integer peram ) {
        llResetScript();
    }

    state_entry() {
        clear();
        llSetTimerEvent( GI_Respawn_Time );
    }

    timer() {
        llSetTimerEvent( 0 );
        clear();
        state spawn;
    }
}


