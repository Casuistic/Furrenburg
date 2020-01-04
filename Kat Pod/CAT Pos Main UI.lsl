/*
    CAT User Animator and pose adjust control script
    Likely could bemerged with main(ui) script to have only one change event


*/
// 202001041738


string GS_Input; // entered code
string GS_RightCode = "0000"; // target code
integer GI_Max_Code_Len = 10; // max length of both target and entered code

integer GI_Closed = FALSE; // is pod closed
integer GL_Pad_Link = 0; // link number of keypad (found by script)


list GL_PadColours = [ // pad colours for diffrent pad events
    <1,1,1>, // DEFAULT (should be unused due to colour matching)
    <1,1,0>, // active
    <0,1,0>, // accepted
    <1,0,0>  // rejected
];

list GL_Sound_KV = []; // loaded from notecard

integer GI_NC_Line; // current notecard line (used only during loading)
key GK_Rid = NULL_KEY; // dataserver id (used during loading)
integer GI_Failed_Load = 0; // number of failed read efforts (used during loading)




// map link set to find and store needed link prim numbers
map() {
    GL_Pad_Link = 0;
    
    integer num = llGetNumberOfPrims();
    for( ; num>0; --num ) {
        if( llGetLinkName( num ) == ".l" ) {
            GL_Pad_Link = num;
        }
    }
}



// convert face pos vector to a button integer
integer parsePad( vector pos ) {
    integer x = (integer)llFloor(pos.x*3);
    integer y = (integer)llFloor((1-pos.y)*4);
    return (x+(y*3));
}


soundEvent( integer ref ) {
    integer index = llListFindList( GL_Sound_KV, [ref] );
    if( index == -1 && index++ < llGetListLength( GL_Sound_KV ) ) {
        return;
    }
    string sound = llList2String( GL_Sound_KV, index );
    if( llGetOwnerKey( (key)sound ) == NULL_KEY ) {
        if( llGetInventoryType( sound ) != INVENTORY_SOUND ) {
            return;
        }
    }
    llTriggerSound( (key)sound, 1 );
}


// process a keypanel button push
procInput( integer data, key user ) {
    if( data == 9 ) { // catch clear
        soundEvent( 2 );
        GS_Input = "";
        llSetLinkColor( GL_Pad_Link, llGetColor( 3 ), 1 );
        llSetTimerEvent( 0 );
    } else if( data == 11 ) { // catch enter
        if( validate( GS_Input ) ) {
            soundEvent( 3 );
            llRegionSayTo( user, 0, "Entered code: '"+ GS_Input +"' Accepted!");
            llSetLinkColor( GL_Pad_Link, llList2Vector( GL_PadColours, 2 ), 1 );
            llMessageLinked( LINK_THIS, 120, (string)GI_Closed, "OpenPod" );
        } else {
            soundEvent( 4 );
            llRegionSayTo( user, 0, "Entered code: '"+ GS_Input +"' Rejected!");
            llSetLinkColor( GL_Pad_Link, llList2Vector( GL_PadColours, 3 ), 1 );
        }
        llSetTimerEvent( 5 );
        GS_Input = "";
    } else if( data >= 0 ){ // anything that isnt enter or clear or... negative?
        if( data < 9 ) {
            GS_Input += (string)(data+1);
        } else if( data == 10 ) {
            GS_Input += "0";
        }
        GS_Input = cutToLength( GS_Input, GI_Max_Code_Len );
        soundEvent( 1 );
        llSetTimerEvent( 30 );
        llSetLinkColor( GL_Pad_Link, llList2Vector( GL_PadColours, 1 ), 1 );
    }
}

// compare stored code and entered code
integer validate( string data ) {
    if( GS_RightCode == data ) {
        return TRUE;
    }
    return FALSE;
}

// trim a string to a given length if needed
string cutToLength( string line, integer len ) {
    if( llStringLength( line ) > len  ) {
        line = llGetSubString( line, -len, -1 );
    }
    return line;
}



// reset all other scripts!
resetScripts() {
    string me = llGetScriptName();
    integer i;
    integer num = llGetInventoryNumber( INVENTORY_SCRIPT );
    for( i=0; i<num; ++i ) {
        string name = llGetInventoryName( INVENTORY_SCRIPT, i );
        if( name != me ) {
            llResetOtherScript( name );
        }
    }
}

addSound( integer ref, string sound ) {
    if( llGetOwnerKey( (key)sound ) == NULL_KEY ) {
        if( llGetInventoryType( sound ) != INVENTORY_SOUND ) {
            llOwnerSay( "Err: Sound: '"+ sound +"' Not Found" );
            return;
        }
    }

    integer index = llListFindList( GL_Sound_KV, [ref] );
    if( index == -1 ) {
        GL_Sound_KV += [ ref, sound ];
    } else if( index+1 >= llGetListLength( GL_Sound_KV ) ) {
        GL_Sound_KV += [sound];
    } else {
        GL_Sound_KV = llListReplaceList( GL_Sound_KV, [sound], index+1, index+1 );
    }
}


testValidCode() {
    if( GI_Max_Code_Len < 4 ) {
        llOwnerSay( "Err: Minimum Max_Code_Len is 4" );
        GI_Max_Code_Len = 4;
    }

    string t = "1" + GS_RightCode;
    integer n = (integer)t;
    if( t != (string)n ) {
        llOwnerSay( "Err: Invalid Characters in Code" );
        llOwnerSay( "Code reset to '1234'" );
        GS_RightCode = "1234";
    }

    integer len = llStringLength( GS_RightCode );
    if( len > GI_Max_Code_Len ) {
        string code = cutToLength( GS_RightCode, GI_Max_Code_Len );
        llOwnerSay( "Err: Code '"+ GS_RightCode +"' excedes maximum length of '"+ (string)GI_Max_Code_Len +"'" );
        llOwnerSay( "Code Trimmed to '"+ code +"'" );
    } else if( len < 2 ) {
        llOwnerSay( "Err: Minimum Code Length is 2" );
        GS_RightCode = GS_RightCode + llGetSubString( "00", llStringLength(GS_RightCode) -2, -1 );
        llOwnerSay( "Code set to: '"+ GS_RightCode +"'" );
    }
}



default {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        llWhisper( 0, "'"+ llGetScriptName() +"' Reset" );
        map( );
        llSetLinkTextureAnim( LINK_THIS, ANIM_ON | SMOOTH | LOOP | PING_PONG, 3, 1, 200, 20, 120, 50);
        llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
        llWhisper( 0, "Reinitializing" );
        //resetScripts();
        llSleep( 0.5 );
        state load;
    }
}

state active {
    state_entry() {
        map( );
        llSetLinkTextureAnim( LINK_THIS, ANIM_ON | SMOOTH | LOOP | PING_PONG, 3, 1, 200, 20, 120, 50);
        llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
    }
    
    touch_start(integer num ) {

        integer link = llDetectedLinkNumber( 0 );
        if( link == LINK_ROOT && llDetectedKey(0) == llAvatarOnSitTarget() ) {
            integer face = llDetectedTouchFace( 0 );
            if( face == 0 | face == 1 ) {
                llMessageLinked( LINK_THIS, 110, "", "" );
            }
        } else if( ".l" == llGetLinkName( link ) ) {
            if( llDetectedTouchFace(0) == 1 ) {
                procInput( parsePad( llDetectedTouchUV( 0 ) ), llDetectedKey(0) );
            }
        }
    }

    link_message( integer src, integer num, string msg, key id ) {
        if( id == "PodState" ) {
            if( msg == "Open" ) {
                GI_Closed = FALSE;
                llOwnerSay( "Is Now Open" );
            } else if( msg == "Closed" ) {
                GI_Closed = TRUE;
                llOwnerSay( "Is Now Closed" );
            }
        }
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_INVENTORY ) {
            state load;
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        GS_Input = "";
        llSetLinkColor( GL_Pad_Link, llGetColor( 3 ), 1 );
    }
}

state load {
    state_entry() {
        GI_NC_Line = 0;
        GK_Rid = NULL_KEY;
        GI_Failed_Load = 0;
        if( llGetInventoryType( "Data" ) != INVENTORY_NOTECARD ) {
            llSay( 0, "Data Card Not Found!" );
            state active;
        } else {
            llWhisper( 0, "Loading..." );
            GK_Rid = llGetNotecardLine( "Data",  GI_NC_Line );
            llSetTimerEvent( 10 );
        }
    }
    
    dataserver( key rid, string data ) {
        if( GK_Rid == rid ) {
            GK_Rid = NULL_KEY;
            if( data != EOF ) {
                if( llGetSubString( data, 0,0 ) != "#" ) { // skip comments
                    
                    list break = llParseString2List( data, [":", "//" ], [] );
                    if( llGetListLength( break ) >= 2 ) {
                        //llCSV2List
                        string tag = llToUpper( llList2String( break, 0 ) );
                        if( tag == "CODE" ) {
                            GS_RightCode = cutToLength( llStringTrim( llList2String( break, 1 ), STRING_TRIM ), GI_Max_Code_Len );
                        } else if( tag == "CODE_MAX_LEN" ) {
                            GI_Max_Code_Len = (integer)llStringTrim( llList2String( break, 1 ), STRING_TRIM );
                        } else if( tag == "KP_SOUND" ) {
                            list parse = llParseString2List( llList2String( break, 1 ), [","], [] );
                            if( llGetListLength( parse ) != 2 ) {
                                llOwnerSay( "Bad Sound Data: "+ data );
                                return;
                            }
                            integer se = (integer)llStringTrim( llList2String( parse, 0 ), STRING_TRIM );
                            string sk = llStringTrim( llList2String( parse, 1 ), STRING_TRIM );
                            addSound( se, sk );
                        } else {
                            llOwnerSay( "Unknown Data: "+ data );
                        }
                    } else {
                        llOwnerSay( "Short Data: "+ data );
                    }
                }
                llSetTimerEvent( 0.25 );
            } else {
                llWhisper( 0, "Load Complete" );
                llSetTimerEvent( 0 );
                testValidCode();
                state active;
            }
            
        }
    }
    
    timer() {
        if( GK_Rid == NULL_KEY ) {
            // next
            GK_Rid = llGetNotecardLine( "Data",  ++GI_NC_Line );
            GI_Failed_Load = 0;
        } else if( GI_Failed_Load <= 3 ){
            // retry
            GK_Rid = llGetNotecardLine( "Data",  GI_NC_Line );
            GI_Failed_Load += 1;
        } else {
            llWhisper( 0, "Unable To Load Data" );
            GK_Rid = NULL_KEY;
            GI_NC_Line = 0;
            GI_Failed_Load = 0;
            state active;
        }
    }
}