/*
    CAT Pod RLV
*/
// 202001051745
// 202001052125

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


// called when doors close
rlvLock( key user ) {
    if( user != NULL_KEY ) {
        llSay( GI_DB_Chan, "RLV Locked" );
        rlvCmd( user, "lk", "@unsit=n|@fartouch=n|@tplocal=n|@tplm=n|@tploc=n|@tplure=n|@sittp=n" );
    }
    rlvReqRes( user );
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
                    rlvRelease( GK_User );
                } else if( msg == "Closing" ) {
                    rlvLock( GK_User );
                }
            }
        } else if( num == 130 ) {
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
            }
        } else if( num == 200 ) {
            //llSay( GI_DB_Chan, "NN: "+ msg +" : "+ (string)id );
            if( id == "RLV_ENABLE" ) {
                enableRLV( (integer)msg );
            }
        } else if( num == 500 && id == "safeword" ) {
            if( GK_User != NULL_KEY ) {
                rlvClear( GK_User );
            }
        }
    }

    listen( integer chan, string name, key id, string msg ) {
        if( chan == GI_Chan_RLV ) {
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
        } else {
            if( id != GK_User ) {
                return;
            }
            llSay( GI_DB_Chan, "Unhanded Message: '"+ name +"' : '"+ msg +"'" );
            // handle RLV version check
            // handle lookup and release restrictions
            // handle aug event
            // handle door change transition
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
