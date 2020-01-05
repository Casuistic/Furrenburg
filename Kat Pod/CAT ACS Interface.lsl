/*
    ACS protocol Charger
    

*/
// 202001041738
// 202001051745
// 202001052125

#include <oups.lsl> // debugging
string GS_Script_Name = "CAT ACS Interface"; // debugging





key GK_User = NULL_KEY; // set by script

integer GI_Chan = -1; // set by script
integer GI_Listen;    // set by script

integer GI_Charge_Tick = 100; // amount of charge to apply per tick
integer GI_Charge_Time = 10;  // rate of ticks

string GS_Top = "None"; // set by script
string GF_Level = "-"; // set by script

integer GI_ChargeEnabled = TRUE; // loaded from NC
integer GI_IsCharing = FALSE;    // set by script
integer GI_GotAck = FALSE;       // set by script

integer GI_MoveLock = FALSE;     // loaded from NC
integer GI_IsMoveLocked = FALSE; // set by script

integer GI_Text = TRUE; // show charger hover text // set by script

integer GI_DB_Chan = -1199;





// look for ACS device
ACSPing( key id ) {
    llRegionSayTo( id, 360, "ACS,hello,CHARGER" );
}

// request open connection to device
ACSInterface( key id ) {
    llRegionSayTo( id, 360, "ACS,interface,CHARGER" );
}

// close connection to a device
ACSCloseInterface( key id, integer chan ) {
    llRegionSayTo( id, chan, "ACS,disconnect:" );
}

// lock ACS Device movement
ACSMoveLock( key id, integer chan, integer on ) {
    llRegionSayTo( id, chan, "ACS,travel:"+ (string)(!on) );
}

// start charge (auto locks movement and doesnt automaticly provide charging)
ACSStartCharge( key id, integer chan, integer on ) {
    if( GI_MoveLock || (!on && GI_IsMoveLocked) ) {
        llRegionSayTo( id, chan, "ACS,charging:"+ (string)(on) );
    }
}

// apply a charge to target device
ACSApplyCharge( key id, integer chan, integer power ) {
    llRegionSayTo( id, chan, "ACS,setcharge+:"+ (string)power );
}

// request device data
ACSReqData( key id, integer chan ) {
    llRegionSayTo( id, chan, "ACS,chargersummary:" );
}

// enable or disable ACS interactions
setACSEnabled( integer on ) {
    if( on != GI_ChargeEnabled ) {
        GI_ChargeEnabled = on; 
        if( GK_User != NULL_KEY ) {
            
        }
    }
}



// update overhead text
updateText() {
    if( GI_Text ) {
        llSetText( GS_Top +"\n"+ (string)GF_Level, <0,1,0>, 1 );
    }
}

// clear overhead text
clearText() {
    llSetText( " ", <0,1,0>, 1 );
}



// open communication to device
openChan( integer chan ) {
    llSay( GI_DB_Chan, "ACS Opening Channel" );
    GI_Chan = chan;
    llListenRemove( GI_Listen );
    GI_Listen = llListen( GI_Chan, "", "", "" );
}

// close communication to device
closeChan() {
    llSay( GI_DB_Chan, "ACS Closing Channel" );
    GI_Chan = -1;
    llListenRemove( GI_Listen );
}

// start charging process
startCharge() {
    if( GI_ChargeEnabled ) {
        ACSApplyCharge( GK_User, GI_Chan, GI_Charge_Tick );
        ACSReqData( GK_User, GI_Chan );
        GS_Top = "Starting Charge Cycle";
        
        llSetTimerEvent( GI_Charge_Time );
    } else {
        GS_Top = "Charging Disabled";
    }
    updateText();
}

// start ACS negotiation
start( key id ) {
    llSay( GI_DB_Chan, "Starting ACS" );
    GK_User = id;
    GI_IsCharing = FALSE;
    GI_GotAck = FALSE;
    
    llSetTimerEvent( 10 );
    clearText();
    ACSPing( GK_User );
}

// end all ACS interactions
clear() {
    llSay( GI_DB_Chan, "Clearing ACS" );
    if( GI_GotAck && GK_User != NULL_KEY ) {
        ACSStartCharge( GK_User, GI_Chan, FALSE );
        ACSCloseInterface( GK_User, GI_Chan );
    }
    closeChan();
    GK_User = NULL_KEY;
    GI_IsCharing = FALSE;
    GI_GotAck = FALSE;
    clearText();
    llSetTimerEvent( 0 );
}


// parse ACS the 360 channel ACS commands
parsACSBasic( string msg ) {
    if( llGetSubString( msg, 0, 3 ) == "ACS," ) {
        list data = llParseString2List( llGetSubString( msg, 4, -1 ), [","], [] );
        if( llList2String( data, 0 ) == "welcome" && llList2String( data, 1 ) == "ccu" ) {
            ACSInterface( GK_User );
        } else if( llList2String( data, 0 ) == "interface" ) {
            llTriggerSound( "a3eddc69-9a94-e39c-77a5-fbc9615d423f", 1 );
            openChan( (integer)llList2String( data, 1 ) );
            GI_GotAck = TRUE;
        }
    }
}

// parse ACS the interface channel commands
parsACSAdv( string msg ) {
    if( llGetSubString( msg, 0, 3 ) == "ACS," ) {
        list data = llParseString2List( llGetSubString( msg, 4, -1 ), [","], [] );
        if( llList2String( data, 0 ) == "powertype:EL" ) {
            // ACS,powertype:EL
            ACSStartCharge( GK_User, GI_Chan, TRUE & GI_MoveLock );
            startCharge(  );
        } else if( llList2String( data, 0 ) == "chargersummary:1" ) {
            if( (float)llList2String( data, 1 ) == 100 ) {
                GS_Top = "Charging";
            }
            GF_Level = llList2String( data, 1 );
            updateText();
        } else if( llList2String( data, 0 ) == "stopcharge:" ) {
            ACSStartCharge( GK_User, GI_Chan, FALSE );
            GS_Top = "Charge Finished";
            updateText();
            closeChan();
            GI_GotAck = FALSE;
            llSetTimerEvent( 0 );
        } else {
            integer index = llSubStringIndex( llList2String( data, 0 ), ":" );
            if( index == -1 ) {
                //llOwnerSay( "ACS Unknown Command: "+ name +" : "+ msg );
            } else {
                string test = llGetSubString( llList2String( data, 0 ), 0, index-1 );
                if( test == "chargeticks" ) {
                    // charge level
                    // ACS,chargeticks:35418.460000
                    //llOwnerSay( msg );
                } else if( test == "maxcharge" ) {
                    // charge report
                    // ACS,maxcharge:36504.000000
                    //llOwnerSay( msg );
                } else {
                    //llOwnerSay( "ACS Err: "+ msg );
                }
            }
        }
    }
}




default {
    state_entry() {
        safeLoad();
        llWhisper( 0, "'"+ llGetScriptName() +"' Reset" );
        llListen( 360, "", "", "" );
        ACSPing( GK_User );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) != GK_User ) {
            return;
        }
        if( chan == 360 ) {
            parsACSBasic( msg );
        } else if( chan == GI_Chan ) {
            parsACSAdv( msg );
            
        }
    }
    
    timer() {
        if( GI_GotAck ) {
            if( GI_Chan != -1 ) {
                if( GI_ChargeEnabled ) {
                    ACSApplyCharge( GK_User, GI_Chan, GI_Charge_Tick );
                    ACSReqData( GK_User, GI_Chan );
                }
            } else {
                llSetTimerEvent( 0 );
            }
        } else {
            //llSay( 0, "ACS Control Protocol Not Responding. Aborting Interface" );
            //llRegionSayTo( GK_User, 0, "Protocol Not Recognized. Aborting Interface" );
            llSetTimerEvent( 0 );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 500 && id == "safeword" ) {
            if( GK_User != NULL_KEY ) {
                ACSStartCharge( GK_User, GI_Chan, FALSE );
            }
        } else if( num == 130 ) {
            if( id == "NewUser" ) {
                key uuid = (key)msg;
                if( llGetAgentSize( uuid ) != ZERO_VECTOR ) {
                    start( uuid );
                } else {
                    clear();
                }
            }
        } else if( num == 200 ) {
            if( id == "TEXT_ENABLE" ) {
                GI_Text = (integer)msg;
            } else if( id == "ACS_ENABLE" ) {
                setACSEnabled( (integer)msg );
            } else if( id == "ACS_LOCK" ) {
                GI_MoveLock = (integer)msg;
            }
        }
    }
}
