integer GV_Chan = -995533; // channel to listen for
integer GI_On = 0;
list GL_Cmd = [ "OFF", "ON" ];





integer GI_Active = FALSE;
integer GI_Action = -1;
string GS_Turbine_State_EKey = "Turb_Sta";
key GK_ExpId = NULL_KEY;




string GS_State = "";





setFree() {
    GI_Active = FALSE;
    llSetTimerEvent(0);
}

setBusy() {
    GI_Active = TRUE;
    llSetText( "Working", <1,1,1>, 1 );
    llSetTimerEvent(10);
}

integer isFree() {
    return !GI_Active;
}





readKeyValue( string tkey ) {
    setBusy();
    GI_Action = 4;
    GK_ExpId = llReadKeyValue( tkey );
}

updateKeyValue( string tkey, string nval, integer check, string oval ) {
    setBusy();
    GI_Action = 5;
    llSetText( "Setting: ["+ tkey +"] from ["+ oval +"] to ["+ nval +"]", <1,1,1>, 1 );
    GK_ExpId = llUpdateKeyValue( tkey, nval, check, oval );
}

createKeyValue( string tkey, string nval ) {
    setBusy();
    GI_Action = 6;
    llSetText( "Creating: ["+ tkey +"] wirh valye "+ nval, <1,1,1>, 1 );
    GK_ExpId = llCreateKeyValue( tkey, nval );
}


parseExpError( integer error ) {
    string text = "Exp Error: " + llGetExperienceErrorMessage(error);
    llOwnerSay( text );
    //llSetText( text, <1,0,0>, 1 );
}






parseState( list data ) {
    string nstate = llList2String( data, 1 );
    if( nstate != GS_State ) {
        if( nstate == "Online" ) {
            llRegionSay( GV_Chan, llList2String( GL_Cmd, GI_On ));
        } else {
            llRegionSay( GV_Chan, llList2String( GL_Cmd, 0 ));
        }
    }
}








default {
    state_entry() {
        llListen( 50, "", "", "CHECK" );
        readKeyValue( GS_Turbine_State_EKey );
    }

    listen( integer chan, string name, key id, string msg ) {
        if( chan == 50 ) {
            if( llToUpper( msg ) == "CHECK" ) {
                readKeyValue( GS_Turbine_State_EKey );
            }
            return;
        }
    }

    dataserver( key rid, string value ) {
        if ( rid == GK_ExpId ) {
            setFree();
            llSetText( llGetObjectDesc() +"\nAct: "+ (string)GI_Action +"\n"+ value, <1,1,1>, 1 );
            list data = llCSV2List( value );
            if ( llList2Integer( data, 0 ) == 0 ) {
                parseExpError( llList2Integer( data, 1 ) );
            }
            
            if( GI_Action == 4 ) {
                GI_Action = -1;
                parseState( data );
            }
        }
    }
    
    timer() {
        setFree();
    }

    touch_start(integer num) {
        GI_On = llAbs( GI_On - 1 );
        llRegionSay( GV_Chan, llList2String( GL_Cmd, GI_On ));
    }
}
