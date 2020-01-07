/*
    CAT Pod RLV



*/
// 202001051745
// 202001052125
// 202001071140 // added recapture feature
// 202001071751 // handled auto scaling
// 202001071915 // fixed recapture ignoring safeword






#include <oups.lsl> // debugging
string GS_Script_Name = "CAT Pod RLV"; // debugging

// should handle rlv not being active on user
// should allow for update event if relay is worn after fact.
// recurring ping... maybe use timer for this?

integer GI_RLV_Enabled = TRUE; // set by notecard load

integer GI_Chan_RLV = -1812221819; // rlv channel DO NOT CHANGE
integer GI_Res_Chan = 1000; // response channel (could be regenerated for each user? or randomized)
integer GI_Listen_Res; // set by script


key GK_User = NULL_KEY;

integer GI_DB_Chan = -1198;


integer GI_No_Touch_Hud = TRUE;
integer GI_No_Touch_Attach = TRUE;
integer GI_No_Touch_World = TRUE;








// called when doors close
rlvLock( key user ) {
    if( user != NULL_KEY ) {
        llSay( GI_DB_Chan, "RLV Locked" );
        rlvCmd( user, "lk", "@unsit=n|@fartouch=n|@tplocal=n|@tplm=n|@tploc=n|@tplure=n|@sittp=n" );
    }
    rlvReqRes( user );
}

// active touch lock
rlvTouchLock( key user ) {
    if( user != NULL_KEY ) {
        list items = [];
        if( GI_No_Touch_Hud ) {
            items += [ "@touchhud=n" ];
        }
        if( GI_No_Touch_Attach ) {
            items += [ "@touchattach=n" ];
        }
        if( GI_No_Touch_World ) {
            items += [ "@touchworld=n" ];
        }
        rlvCmd( user, "tl", llDumpList2String( items, "|" ) );
    }
}


rlvCapture( key user ) {
    if( user != NULL_KEY ) {
        rlvCmd( 
            user,
            "cp",
            "@sit:"+ (string)llGetLinkKey(LINK_ROOT) +"=force" );
    }
}

// called when doors open
rlvRelease( key user ) {
    if( user != NULL_KEY ) {
        llSay( GI_DB_Chan, "RLV Cleared" );
        //rlvCmd( user, "ul", "@unsit=y|@fartouch=y" ); // gets a stray detach restriction and can't be reapplied for some reason...
        rlvCmd( user, "ul", "!release" );
    }
    rlvReqRes( user );
}

// called on safeword
rlvClear( key user ) {
    llSay( GI_DB_Chan, "RLV Escaped" );
    if( user != NULL_KEY ) {
        rlvCmd( user, "dn", "@clear" );
    }
}

// called to test for rlv
rlvPing( key user ) {
    llSetTimerEvent( 10 );
    rlvCmd( user, "pn", "@version="+ (string)GI_Res_Chan );
}

// ask for active restrictions
rlvReqRes( key user ) {
    rlvCmd( user, "lu", "@getstatus="+ (string)GI_Res_Chan );
}

// used to send all rlv commands
rlvCmd( key user, string tag, string cmd ) {
    llRegionSayTo( user, GI_Chan_RLV, tag +","+ (string)user +","+ cmd );
}

// enable or disable script rlv functions
enableRLV( integer on ) {
    llSay( GI_DB_Chan, "RLV Enable Stats Changed to: "+ (string)on );
    if( GI_RLV_Enabled != on ) {
        GI_RLV_Enabled = on;
        if( GK_User != NULL_KEY ) {
            if( on ) {
                rlvPing( GK_User );
            } else {
                rlvClear( GK_User );
            }
        }
    }
}

openResChan( integer chan, key id ) { // open comm channel
    GI_Res_Chan = chan;
    llListenRemove( GI_Listen_Res );
    GI_Listen_Res = llListen( chan, "", id, "" );
}

closeResChan() { // close comm channel
    llListenRemove( GI_Listen_Res );
}


// parse rlv listen response
parseRLVAck( string msg ) {
    string tag = llGetSubString( msg, 0, 2 );
    if( tag == "pn," ) {
        llSay( GI_DB_Chan, "Got RLV Ping" );
        llSetTimerEvent( 0 );
    } else if( tag == "dn," ) {
        llSay( GI_DB_Chan, "Got RLV Clear" );
    } else {
        llSay( GI_DB_Chan, "Unknown RLV: "+ msg );
    }
}


// parse poser message
parsePoserSrcLM( string msg, key id ) {
    //llOwnerSay( "RLV Cmd: "+ (string)id +" : "+ msg );
    if( id == "NewUser" ) {
        llSay( GI_DB_Chan, "RLV User: "+ msg );
        key user = (key)msg;
        if( user == NULL_KEY ) {
            if( GK_User != user ) {
                if( GK_User != NULL_KEY ) {
                    closeResChan();
                    rlvRelease( GK_User );
                }
                llSetTimerEvent( 0 );
                GK_User = user;
           }
        } else {
            GK_User = user;
            openResChan( 1000 + (integer)llFloor(llFrand(9000)), user );
            rlvPing( GK_User );
        }
    } else if( id == "Capture" ) {
        rlvCapture( (key)msg );
        
    } else if( id == "RefreshRLV" ) {
        key user = (key)msg;
        rlvLock( user );
        rlvTouchLock( user );
    }
}

parseRLVSrcLM() {
    if( llGetOwnerKey( id ) != GK_User ) {
        return; // filter non user triggered events
    }
    if( llGetSubString( msg, 0, 2 ) == "pn," ) {
        llSay( GI_DB_Chan, "Got RLV Ping" );
        llSetTimerEvent( 0 );
    } else if( llGetSubString( msg, 0, 2 ) == "dn," ) {
        llSay( GI_DB_Chan, "Got RLV Clear" );
    } else {
        llSay( GI_DB_Chan, "Unknown RLV: "+ name +" : "+ msg );
    }
    //list data = llParseString2List( msg, [","], [] );
}

// perform safeword
performRLVSafeword() {
    if( GK_User != NULL_KEY && llGetAgentSize( GK_User ) != ZERO_VECTOR ) {
        llMessageLinked( LINK_THIS, 210, "Performing Safeword release of "+ llKey2Name( GK_User ), "Tattle" );
        rlvClear( GK_User );
    }
}




podClosed() {
    rlvTouchLock( GK_User );
}


parseDataLoad( string data, key tag ) {
    //GI_DB_Chan
    //llSay( 0, "NN: "+ data +" : "+ (string)tag );
    if( tag == "RLV_ENABLE" ) {
        enableRLV( (integer)data );
    }
}



/*
*   START OF STATES
*   Because it is easier than regularly adjusting spacing
*/


default {
    state_entry() {
        safeLoad();
        llListen( GI_Chan_RLV, "", "", "" );
    }

    link_message( integer src, integer num, string msg, key id ) {
        //llOwnerSay( (string)num +" : "+ msg +" : "+ (string)id );
        if( GI_RLV_Enabled && num == 100 ) {
            if( id == "PodState" ) {
                if( msg == "Open" ) {
                    // what to do when pot finishes opening
                    rlvRelease( GK_User );
                } else if( msg == "Closing" ) {
                    // what to do when pod starts closing
                    rlvLock( GK_User );
                } else if( msg == "Closed" ) {
                    // what to do when pod finished closing
                    podClosed();
                } else if( msg == "Opening" ) {
                    // what to do when pod starts opening
                }
            }
        } else if( num == 130 ) {
            parsePoserSrcLM( msg, id );
        } else if( num == 200 ) {
            parseDataLoad( msg, id );
        } else if( num == 500 && id == "safeword" ) {
            performRLVSafeword();
        }
    }

    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) != GK_User ) {
            return;
        }
        if( chan == GI_Chan_RLV ) {
            parseRLVAck( msg );
        } else {
            llSay( GI_DB_Chan, "Unhanded Message: '"+ name +"' : '"+ msg +"'" );
        }
    }

    timer() {
        llSetTimerEvent( 0 );
        if( GK_User != NULL_KEY ) {
            llSay( GI_DB_Chan, "User '"+ (string)GK_User +"' RLV Not Available" );
            llRegionSayTo( GK_User, 0, "Relay Has not responded. Please check if your RLV Relay is equipped and RLV is active in your viewer" );
        }
    }
}
