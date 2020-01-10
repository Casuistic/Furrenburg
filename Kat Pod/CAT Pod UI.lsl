/*
    CAT User Animator and pose adjust control script
    Likely could be merged with main(ui) script to have only one change event
*/
// 202001041738
// 202001051745
// 202001052125
// 202001071140 // added recapture feature
// 202001071751 // handled auto scaling
// 202001071915 // fixed recapture ignoring safeword
// 202001102045 // added set code dialog system

#include <oups.lsl> // debugging
string GS_Script_Name = "CAT Pod UI"; // debugging




string GS_Input; // entered code
string GS_RightCode = "0000"; // target code
string GS_SetCode = ""; // target code
integer GI_Max_Code_Len = 10; // max length of both target and entered code

integer GI_Closed = FALSE; // is pod closed
integer GL_Pad_Link = 0; // link number of keypad (found by script)
integer GL_SZ_Link = 0;

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

string GS_Safeword = "ABORT";
integer GI_SW_Listen = -1;

integer GI_DB_Chan = -1192;



integer GI_Chan_SW = 1;
integer GI_Inform = TRUE;


integer GI_Chan_User = 5050;
list GL_Active_Users = [];
list GL_Listen_Users = [];
list GL_CountD_Users = [];



setSafeword( string word ) {
    llListenRemove( GI_SW_Listen );
    GS_Safeword = word;
    if( word != "" ) {
        GI_SW_Listen = llListen( GI_Chan_SW, "", "", word );
        llOwnerSay( "Safeword Set: '"+ word +"'" );
    } else {
        llOwnerSay( "Caution: No Safeword Set" );
    }
}

// map link set to find and store needed link prim numbers
map() {
    GL_Pad_Link = 0;
    
    integer num = llGetNumberOfPrims();
    for( ; num>0; --num ) {
        string name = llGetLinkName( num );
        if( name == ".l" ) {
            GL_Pad_Link = num;
        } else if( name == ".sit zone" ) {
            GL_SZ_Link = num;
        }
    }
}

// convert face pos vector to a button integer
integer parsePad( vector pos ) {
    integer x = (integer)llFloor(pos.x*3);
    integer y = (integer)llFloor((1-pos.y)*4);
    return (x+(y*3));
}

// slight convoluted sound handling
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
    if( data != "" && (GS_SetCode == data || GS_RightCode == data) ) {
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
    llOwnerSay( "Scripts Reset" );
}

// add key value pair to used with sound events
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


// make sure the code added through the notecard is a valid code
// must be an integer, may have leading zeros, must not contain characters
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
    } /*else if( len < 2 ) {
        llOwnerSay( "Minimum Active Code Length is 2" );
        GS_RightCode = GS_RightCode + llGetSubString( "00", llStringLength(GS_RightCode) -2, -1 );
        llOwnerSay( "Code set to: '"+ GS_RightCode +"'" );
    } */else if( len < 2 ) {
        llOwnerSay( "No Code Set: To set a code it must be a minimum of 2 integers long" );
        GS_RightCode = "";
    }
}


integer parseDataLoad( string data ) {
    if( data == EOF ) {
        return TRUE;
    } else {
        if( llGetSubString( data, 0,0 ) != "#" ) { // skip comments
            list break = llParseStringKeepNulls( data, [":"], ["//"] );
            integer index = llListFindList( break, ["//"] ); // find if comments
            string tag = llToUpper( 
                                llStringTrim(
                                    llList2String( break, 0 ), 
                                    STRING_TRIM )
                            );
            if( index != -1 ) { // strip comments
                break = llList2List( break, 0, index-1 );
            } // end of strip comments
            if( llGetListLength( break ) >= 2 ) {
                if( tag == "CODE" ) {
                    GS_RightCode = cutToLength( llStringTrim( llList2String( break, 1 ), STRING_TRIM ), GI_Max_Code_Len );
                } else if( tag == "CODE_MAX_LEN" ) {
                    GI_Max_Code_Len = (integer)llStringTrim( llList2String( break, 1 ), STRING_TRIM );
                } else if( tag == "KP_SOUND" ) {
                    list parse = llParseStringKeepNulls( llList2String( break, 1 ), [","], [] );
                    if( llGetListLength( parse ) == 2 ) {
                        addSound(
                                (integer)llStringTrim( llList2String( parse, 0 ), STRING_TRIM ), 
                                llStringTrim( llList2String( parse, 1 ), STRING_TRIM )
                            );
                    } else {
                        llOwnerSay( "Bad Sound Data: '"+ data +"'" );
                    }
                } else if( tag == "SAFEWORD" ) {
                    GS_Safeword = llStringTrim( llList2String( break, 1 ), STRING_TRIM );
                } else {
                    if( llGetSubString( tag, 0,3 ) == "POD_" ) {
                        llMessageLinked( LINK_THIS, 200,
                            llStringTrim( llList2String( break, 1 ), STRING_TRIM ),
                            llGetSubString( tag, 4,-1 ) 
                        );
                    } else {
                        llOwnerSay( "Unknown Data: '"+ tag +" : "+ data +"'" );
                    }
                }
            } else { // list length 1
                if( tag == "END_LOAD" ) {
                    return TRUE;
                //} else if( tag != "" ) {
                    //llOwnerSay( "Short Data: '"+ tag +"' '"+ data +"'" );
                }
            }
        }
    }
    return FALSE;
}


sendIm( string msg ) {
    if( !GI_Inform ) {
        return;
    }
    key user = llGetOwner();
    if( llGetAgentSize( user ) == ZERO_VECTOR ) {
        llInstantMessage( user, msg );
    } else {
        llRegionSayTo( user, 0, msg );
    }
}

// open a channel and send dialog box
openChannel( key id ) {
    integer index = llListFindList( GL_Active_Users, [id] );
    if( index != -1 ) {
        GL_CountD_Users = llListReplaceList( GL_CountD_Users, [12], index, index );
        llTextBox( id, "Set Code\n2-"+ (string)GI_Max_Code_Len +" numbers\nCharacters: 0-9 only", GI_Chan_User );
    } else if( id != NULL_KEY ) {
        GL_Active_Users += [id];
        GL_Listen_Users += [llListen( GI_Chan_User, "", id, "" )];
        GL_CountD_Users += [3];
        llTextBox( id, "Set Code\n2-"+ (string)GI_Max_Code_Len +" numbers\nCharacters: 0-9 only", GI_Chan_User );
    }
}

// close a given channel or all channels if null key is suplied
closeChannel( key id, string inform ) {
    if( id == NULL_KEY ) {
        integer i;
        integer num = llGetListLength( GL_Active_Users );
        for( i=0; i<num; ++i ) {
            clearChannel( -1, inform );
        }
    } else {
        integer index = llListFindList( GL_Active_Users, [id] );
        if( index != -1 ) {
            clearChannel( index, inform );
        }
    }
}

// clear a channel at a given index
clearChannel( integer index, string inform ) {
    integer len = llGetListLength( GL_Active_Users );
    if( index < len || ( index<=-1 && llAbs(index) <= len ) ) {
        llListenRemove( llList2Integer( GL_Listen_Users, index ) );
        if( inform != "" ) {
            llRegionSayTo( llList2Key( GL_Active_Users, 0 ), 0, inform );
        }
        GL_Active_Users = llDeleteSubList( GL_Active_Users, index, index );
        GL_Listen_Users = llDeleteSubList( GL_Listen_Users, index, index );
        GL_CountD_Users = llDeleteSubList( GL_CountD_Users, index, index );
    }
}

// count down to channel close
integer processChannels() {
    integer num = llGetListLength( GL_Active_Users );
    list close = [];
    if( num != 0 ) {
        integer i;
        for( i=0; i<num; ++i ) {
            integer n = llList2Integer( GL_CountD_Users, i ) -1;
            llOwnerSay( (string)n +" : "+ (string)i );
            if( n <= 0 ) {
                close += i;
            } else {
                GL_CountD_Users = llListReplaceList( GL_CountD_Users, [n], i, i );
            }
        }
        for( i=0; i<llGetListLength(close); ++i ) {
            closeChannel( llList2Key( GL_Active_Users, llList2Integer( close, i ) ), "Listen Timed Out" );
        }
        return TRUE;
    }
    return FALSE;
}


integer verifyCodeChars( string code ) {
    string t = "1" + code;
    integer n = (integer)t;
    if( t != (string)n ) {
        return FALSE;
    }
    return TRUE;
}


integer parseCodeInput( string code, key id ) {
    integer len = llStringLength( code );
    if( !verifyCodeChars( code ) || len > GI_Max_Code_Len || len < 2 ) {
        return FALSE;
    }
    return TRUE;
}


/*
*   START OF STATES
*   Because it is easier than regularly adjusting spacing
*/


default {
    on_rez( integer peram ) {
        llWhisper( 0, "Reinitializing" );
        resetScripts();
        llResetScript();
    }
    
    state_entry() {
        safeLoad();
        llWhisper( GI_DB_Chan, "'"+ llGetScriptName() +"' Reset" );
        map( );
        llSetLinkTextureAnim( LINK_THIS, ANIM_ON | SMOOTH | LOOP | PING_PONG, 3, 1, 200, 20, 120, 50);
        llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
        //llWhisper( 0, "Reinitializing" );
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
        //llOwnerSay( llDumpList2String( GL_Sound_KV, "\n" ) );
        setSafeword( GS_Safeword );
    }

    listen( integer chan, string name, key id, string msg ) {
        if( chan == GI_Chan_SW ) {
            llMessageLinked( LINK_SET, 500, "safeword", "safeword" );
            sendIm( "Safeword Used by: '"+ llKey2Name( id ) +"'" );
            return;
        } else if( chan == GI_Chan_User ) {
            if( !GI_Closed ) {
                integer t = parseCodeInput( msg, id );
                if( t > 0 ) {
                    GS_SetCode = msg;
                    GI_Closed = TRUE;
                    llMessageLinked( LINK_THIS, 120, (string)(!GI_Closed), "OpenPod" );
                    llRegionSayTo( id, 0, "Code Accepted: "+ msg );
                    closeChannel( id, "" );
                    closeChannel( NULL_KEY, "A Valid Code Has Been Entered" );
                } else {
                    llRegionSayTo( id, 0, "Code Rejected: Code must have a length of 2-"+ (string)GI_Max_Code_Len +" and must contain only characters 0-9" );
                    openChannel( id );
                }
            }
        }
    }
    
    touch_start(integer num ) {
        integer link = llDetectedLinkNumber( 0 );
        if( (link == LINK_ROOT || link == GL_SZ_Link) && llDetectedKey(0) == llAvatarOnSitTarget() ) {
            integer face = llDetectedTouchFace( 0 );
            if( link == GL_SZ_Link || (face == 0 | face == 1) ) {
                llMessageLinked( LINK_THIS, 110, "", "" );
            }
        } else if( ".l" == llGetLinkName( link ) ) {
            if( llVecDist( llGetPos(), llDetectedPos(0) ) >= 5 ) {
                llRegionSayTo( llDetectedKey(0), 0, "You need to be closer to use that!" );
                return;
            }
            if( llDetectedTouchFace(0) == 1 ) {
                if( !GI_Closed ) {
                    openChannel( llDetectedKey( 0 ) );
                    llSetTimerEvent( 5 );
                } else {
                    procInput( parsePad( llDetectedTouchUV( 0 ) ), llDetectedKey(0) );
                }
            }
        }
    }

    link_message( integer src, integer num, string msg, key id ) {
        if( id == "PodState" ) {
            if( msg == "Open" ) {
                GI_Closed = FALSE;
                //llOwnerSay( "UI Is Now Open" );
            } else if( msg == "Closed" ) {
                GI_Closed = TRUE;
                //llOwnerSay( "UI Is Now Closed" );
            }
        }
        else if( num == 210 ) {
            if( id == "Tattle" ) {
                sendIm( msg );
            }
        }
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_INVENTORY ) {
            state load;
        }
    }
    
    timer() {
        if( GS_Input != "" ) {
            GS_Input = "";
            llSetLinkColor( GL_Pad_Link, llGetColor( 3 ), 1 );
            return;
        } else if( processChannels() ) {
            return;
        }
        llSetTimerEvent( 0 );
    }
}

state load {
    state_entry() {
        //resetScripts();
        GI_NC_Line = 0;
        GK_Rid = NULL_KEY;
        GI_Failed_Load = 0;
        GL_Sound_KV = [];
        if( llGetInventoryType( "Data" ) != INVENTORY_NOTECARD ) {
            llSay( 0, "Data Card Not Found!" );
            state active;
        } else {
            llWhisper( 0, "Loading..." );
            GK_Rid = llGetNotecardLine( "Data",  GI_NC_Line );
            llSetTimerEvent( 10 );
        }
    }

    /* // only needed if this script has a dataserver event in load
    state_exit() {
        GI_NC_Line = 0;
        GK_Rid = NULL_KEY;
        GI_Failed_Load = 0;
    }
    */

    dataserver( key rid, string data ) {
        if( GK_Rid == rid ) {
            GK_Rid = NULL_KEY;
            if ( parseDataLoad( data ) ) { // returned true if EOL or END_LOAD
                llWhisper( 0, "Load Complete" );
                llSetTimerEvent( 0 );
                testValidCode();
                state active; // STATE EXIT EVENT
            } else {
                llSetTimerEvent( 0.25 );
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
            state active; // STATE EXIT EVENT
        }
    }
}
