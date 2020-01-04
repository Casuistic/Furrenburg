/*
    ACS protocol Charger
    

*/
// 202001041738

key GK_Sub = NULL_KEY;

integer GI_Chan = -1;
integer GI_Listen;

integer GI_Charge_Tick = 100;
integer GI_Charge_Time = 10;

string GS_Top = "None";
string GF_Level = "-";


integer GI_IsCharing = FALSE;
integer GI_GotAck = FALSE;



ACSPing( key id ) {
    llRegionSayTo( id, 360, "ACS,hello,CHARGER" );
}

ACSInterface( key id ) {
    llRegionSayTo( id, 360, "ACS,interface,CHARGER" );
}

ACSMoveLock( key id, integer chan, integer on ) {
    llRegionSayTo( id, chan, "ACS,travel:"+ (string)(!on) );
}

ACSStartCharge( key id, integer chan, integer on ) {
    llRegionSayTo( id, chan, "ACS,charging:"+ (string)(on) );
}

ACSApplyCharge( key id, integer chan, integer power ) {
    llRegionSayTo( id, chan, "ACS,setcharge+:"+ (string)power );
}

ACSReqData( key id, integer chan ) {
    llRegionSayTo( id, chan, "ACS,chargersummary:" );
}

updateText() {
    llSetText( GS_Top +"\n"+ (string)GF_Level, <0,1,0>, 1 );
}

clearText() {
    llSetText( " ", <0,1,0>, 1 );
}




openChan( integer chan ) {
    GI_Chan = chan;
    llListenRemove( GI_Listen );
    GI_Listen = llListen( GI_Chan, "", "", "" );
}

closeChan() {
    GI_Chan = -1;
    llListenRemove( GI_Listen );
}




start( key id ) {
    llOwnerSay( "Starting ACS" );
    GK_Sub = id;
    GI_IsCharing = FALSE;
    GI_GotAck = FALSE;
    
    llSetTimerEvent( 10 );
    clearText();
    ACSPing( GK_Sub );
}

clear() {
    llOwnerSay( "Clearing ACS" );
    GK_Sub = NULL_KEY;
    GI_IsCharing = FALSE;
    GI_GotAck = FALSE;

    closeChan();
    clearText();
    llSetTimerEvent( 0 );
}



default {
    state_entry() {
        llWhisper( 0, "'"+ llGetScriptName() +"' Reset" );
        llListen( 0, "", "", "ABORT" );
        llListen( 360, "", "", "" );
        ACSPing( GK_Sub );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( chan == 0 ) {
            ACSStartCharge( GK_Sub, GI_Chan, FALSE );
            return;
        }
        if( chan == 360 ) {
            if( llGetSubString( msg, 0, 3 ) == "ACS," ) {
                list data = llParseString2List( llGetSubString( msg, 4, -1 ), [","], [] );
                if( llList2String( data, 0 ) == "welcome" && llList2String( data, 1 ) == "ccu" ) {
                    ACSInterface( GK_Sub );
                } else if( llList2String( data, 0 ) == "interface" ) {
                    llTriggerSound( "a3eddc69-9a94-e39c-77a5-fbc9615d423f", 1 );
                    openChan( (integer)llList2String( data, 1 ) );
                    GI_GotAck = TRUE;
                }
            }
        } else if( chan == GI_Chan ) {
            if( llGetSubString( msg, 0, 3 ) == "ACS," ) {
                list data = llParseString2List( llGetSubString( msg, 4, -1 ), [","], [] );
                if( llList2String( data, 0 ) == "powertype:EL" ) {
                    ACSStartCharge( GK_Sub, GI_Chan, TRUE );
                    GS_Top = "Starting Charge Cycle";
                    updateText();
                    llSetTimerEvent( GI_Charge_Time );
                } else if( llList2String( data, 0 ) == "chargersummary:1" ) {
                    if( (float)llList2String( data, 1 ) == 100 ) {
                        GS_Top = "Charging";
                    }
                    GF_Level = llList2String( data, 1 );
                    updateText();
                } else if( llList2String( data, 0 ) == "stopcharge:" ) {
                    ACSStartCharge( GK_Sub, GI_Chan, FALSE );
                    GS_Top = "Charge Finished";
                    updateText();
                    closeChan();
                    GI_GotAck = FALSE;
                    llSetTimerEvent( 0 );
                } else {
                    integer index = llSubStringIndex( llList2String( data, 0 ), ":" );
                    if( index == -1 ) {
                        llOwnerSay( "ACS Unknown Command: "+ name +" : "+ msg );
                    } else {
                        string test = llGetSubString( llList2String( data, 0 ), 0, index-1 );
                        if( test == "chargeticks" ) {
                            // accepting charge
                        } else if( test == "maxcharge" ) {
                            // charge report
                        } else {
                            llOwnerSay( "ACS Err: "+ msg );
                        }
                    }
                }
            }
        }
    }
    
    timer() {
        if( GI_GotAck ) {
            if( GI_Chan != -1 ) {
                ACSApplyCharge( GK_Sub, GI_Chan, GI_Charge_Tick );
                ACSReqData( GK_Sub, GI_Chan );
            } else {
                llSetTimerEvent( 0 );
            }
        } else {
            llRegionSayTo( GK_Sub, 0, "Protocol Not Recognised. Aborting Interface" );
            llSetTimerEvent( 0 );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == 130 ) {
            if( id == "NewUser" ) {
                key uuid = (key)msg;
                if( llGetAgentSize( uuid ) != ZERO_VECTOR ) {
                    start( uuid );
                } else {
                    clear();
                }
            }
        }
    }
}
