string GS_Target = "Generator Screen"; // name of turbine
list GL_Turbine_Prims = [];
list GL_Listen = []; // stores listens
integer GI_Chan = 999; // channel to use
integer GI_Count = 0; // point of spool spin
integer GI_Rotor_Mod = TRUE; // rise or fall of spool

integer GI_Action = -1; // exp action performed
key GK_ExpId = NULL_KEY; // key of exp request
string GS_Turbine_State_EKey = "Turb_Sta"; // info key in exp

string GS_State = ""; // used to store last checked state so changes can be found


key GK_Debug_Target = NULL_KEY;//"91ac2b46-6869-48f3-bc06-1c0df87cc6d6";


// DEBUG
debug( string msg ) {
    if( GK_Debug_Target != NULL_KEY ) {
        llRegionSayTo( GK_Debug_Target, 0 , msg );
    }
}

// perform setup
setup() {
    map();
    GI_Count = 0;
    GI_Rotor_Mod = FALSE;
    //setRotorDown( 2 );
    llStopSound();
    GS_State = "";
}



// spool up the turbine
integer setRotorUp( integer lev ) {
    if( lev >= 1 && lev <= 4 ) {
        if( lev == 1 ) {
            llPlaySound("319a3d78-54cd-5b7e-6a94-4d05849d3f13",1);
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkTextureAnim( llList2Integer( GL_Turbine_Prims, i ), ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 1, 1, 1, 1, 0.5 );
            }
            llSetTimerEvent( 3 );
        } else if( lev == 2 ) {
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkTextureAnim( llList2Integer( GL_Turbine_Prims, i ), ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 1, 1, 1, 1, 1 );
            }
            llSetTimerEvent( 6.6 );
        } else if( lev == 3 ) {
            llLoopSound("26579b11-d7f5-e0bd-6802-7e52830d7250",1);
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkPrimitiveParamsFast( llList2Integer( GL_Turbine_Prims, i ), [PRIM_FULLBRIGHT, ALL_SIDES, TRUE, PRIM_COLOR, ALL_SIDES, <1.000, 0.522, 0.106>, 1.0, PRIM_GLOW, ALL_SIDES, .4] );
            }
            llSetTimerEvent( 10 );
        } else if( lev == 4 ) {
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkPrimitiveParamsFast( llList2Integer( GL_Turbine_Prims, i ), [PRIM_FULLBRIGHT, ALL_SIDES, TRUE, PRIM_COLOR, ALL_SIDES, <1.000, 0.522, 0.106>, 1.0, PRIM_GLOW, ALL_SIDES, .8]);
            }
            llSetTimerEvent( 5 );
        }
        return TRUE;
    }
    
    return FALSE;
}

// spool down the turbine
integer setRotorDown( integer lev ) {
    if( lev >= 2 && lev <= 4  ) {
        if( lev == 4 ) {
            llStopSound();
            llPlaySound("a8526f6c-5388-a872-85da-36f0e6ffeb3a",1);
            llSetTimerEvent( 2 );
        } else if( lev == 3 ) {
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkPrimitiveParamsFast( llList2Integer( GL_Turbine_Prims, i ), [PRIM_FULLBRIGHT, ALL_SIDES, FALSE, PRIM_COLOR, ALL_SIDES, <1.000, 0.522, 0.106>, 1.0, PRIM_GLOW, ALL_SIDES, .3] );
                llSetLinkTextureAnim( llList2Integer( GL_Turbine_Prims, i ), ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 1, 1, 1, 1, 0.5 );
            }
            llSetTimerEvent( 6 );
        } else if( lev == 2 ) {
            integer i;
            integer num = llGetListLength( GL_Turbine_Prims );
            for( i=0; i<num; ++i ) {
                llSetLinkPrimitiveParamsFast( llList2Integer( GL_Turbine_Prims, i ), [PRIM_FULLBRIGHT, ALL_SIDES, FALSE, PRIM_COLOR, ALL_SIDES, <1.000, 1.000, 1.000>, 1.0, PRIM_GLOW, ALL_SIDES, .0] );
                llSetLinkTextureAnim( llList2Integer( GL_Turbine_Prims, i ), ANIM_ON | SMOOTH | LOOP , ALL_SIDES, 1, 1, 1, 1, 0.0 );
            }
            llSetTimerEvent( 0.5 );
        }
        return TRUE;
    }
    
    return FALSE;
}

// map the link set to find the needed prims
map() {
    list turbines = [];
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=1; i<=num; ++i ) {
        if( llGetLinkName(i) == GS_Target ) {
            turbines += i;
        }
    }
    GL_Turbine_Prims = turbines;
}

// clear active listens
// not needed when state change happens
clearListens() {
    integer i;
    integer num = llGetListLength( GL_Listen );
    for( i=0; i<num; ++i ) {
        llListenRemove( llList2Integer( GL_Listen, i ) );
    }
    GL_Listen = [];
}

// check if in an experiance
integer parseExpDetails() {
    //[string experience_name, key owner_id, key experience_id, integer state, string state_message, key group_id]
    list tags = ["experience_name", "owner_id", "experience_id", "state", "state_message", "group_id"];
    list data = llGetExperienceDetails( NULL_KEY );
    return (llGetListLength( data ) != 0);
}

// get the exp value of exp key tkey
readKeyValue( string tkey ) {
    GI_Action = 4;
    GK_ExpId = llReadKeyValue( tkey );
}

// parse returned value
integer parseKeyValue( string key_val, string value ) {
    list result = llCSV2List( value );
    string text = "";
    integer out = FALSE;
    if ( llList2Integer( result, 0 ) == 1 ) {
        text = "Value Found: "+ key_val +": "+ llDumpList2String( llList2List( result,1,-1 ), "," );
        out = TRUE;
    } else {
        text = "Key Value Lookup Failed: "+ key_val;
    }
    debug( text );
    return out;
}

// exp error parsing
parseExpError( integer error ) {
    string text = "Exp Error: " + llGetExperienceErrorMessage(error);
    debug( text );
    llSetText( text, <1,0,0>, 1 );
}

// parse returned value of power state
parseState( list data ) {
    string nstate = llList2String( data, 1 );
    if( nstate != GS_State ) {
        if( nstate == "Online" ) {
            llMessageLinked( LINK_THIS, 50, "Online", "STATE" );
        } else {
            llMessageLinked( LINK_THIS, 50, "Offline", "STATE" );
        }
    }
}






/////////////////
// setup state //
/////////////////
default {
    state_entry() {
        setup();
        state ready;
    }
}

//////////////////////
// idle ready state //
//////////////////////
state ready {
    on_rez( integer peram ) {
        state default;
    }

    state_entry() {
        debug( "Ready" );
        llSetText( "", <1,1,1>, 1 );
        if( parseExpDetails() ) {
            readKeyValue( GS_Turbine_State_EKey );
        } else {
            llSetText( "Error: Experiance Not Set", <1,0,0>, 1 );
        }
        llListen( 50, "", "", "CHECK" );
    }
    
    state_exit() {
        GL_Listen = []; // listens autoclear on state exit
        llSetTimerEvent(0);
        debug( "unready" );
    }

    touch_start( integer num ) {
        clearListens();
        key user = llDetectedKey( 0 );
        GL_Listen += llListen( GI_Chan, "", user, "Yes" );
        GL_Listen += llListen( GI_Chan, "", user, "No" );
        llDialog( user, "\nWould you like to Start this Turbine", ["Yes", "No" ] , GI_Chan );
        llSetTimerEvent( 60 );
    }

    listen( integer chan, string name, key id, string msg ) {
        if( chan == 50 ) {
            if( llToUpper( msg ) == "CHECK" ) {
                readKeyValue( GS_Turbine_State_EKey );
            }
            return;
        }
        if( msg == "Yes" ) {
            state spool_up;
        } else if( msg == "No" ) {
            state spool_down;
        }
    }

    timer() {
        llSetTimerEvent( 0 );
        clearListens();
    }
    
    dataserver( key rid, string value ) {
        if ( rid == GK_ExpId ) {
            list data = llCSV2List( value );
            if ( llList2Integer( data, 0 ) == 0 ) {
                parseExpError( llList2Integer( data, 1 ) );
            } else if ( GI_Action == 4 ) {
                GI_Action = -1;
                parseState( data );
            }
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( id == "STATE" ) {
            if( msg == "Online" ) {
                state spool_up;
            } else {
                state spool_down;
            }
        }
    }
}

//////////////////////
// starting turbine //
//////////////////////
state spool_up {
    on_rez( integer peram ) {
        state default;
    }

    state_entry() {
        llSay(0, "Preparing to Start Turbine");
        GI_Rotor_Mod = TRUE;
        GS_State = "Online";
        llSetTimerEvent( 0.5 );
    }

    timer() {
        GI_Count += 1;
        llSetTimerEvent( 0 );
        debug( "Up Timer: "+ (string)GI_Count );
        if( !setRotorUp( GI_Count ) ) {
            GI_Count = 5;
            state ready;
        }
    }

    listen( integer chan, string name, key id, string msg ) {
        debug( "MEW 1" );
    }
}

//////////////////////
// stopping turbine //
//////////////////////
state spool_down {
    on_rez( integer peram ) {
        state default;
    }

    state_entry() {
        llSay(0, "Turbine in Lock down Mode");
        GI_Rotor_Mod = FALSE;
        GS_State = "Offline";
        llSetTimerEvent( 0.5 );
    }

    timer() {
        GI_Count -= 1;
        llSetTimerEvent( 0 );
        debug( "Down Timer: "+ (string)GI_Count );
        if( !setRotorDown( GI_Count ) ) {
            GI_Count = 0;
            state ready;
        }
    }

    listen( integer chan, string name, key id, string msg ) {
        debug( "MEW 2" );
    }
}


