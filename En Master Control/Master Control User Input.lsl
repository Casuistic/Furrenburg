

string GS_Anim = "Work";

key GK_Sound_Zap = "3a425dce-50ea-3576-399a-7a5371618cc5"; // zap sound


integer isZap = FALSE;

float GF_Process;




start() {
    llStopAnimation( "sit" ); // because it fucks shit up
    //llStartAnimation( "stand" ); // because for some reason I need a stand....
    llStartAnimation( GS_Anim );
}

stop() {
    integer peram = llGetPermissions();
    if( peram & PERMISSION_TRIGGER_ANIMATION ) {
        llStopAnimation( GS_Anim );
    }
    llReleaseControls();
}




zap( integer isZapped ) {
    if( isZapped ) {
        llMessageLinked( LINK_THIS, 5, "2,0,1,3,4", "SET_SCREEN" );
        llStartAnimation( "Zap" );
        llStopAnimation( GS_Anim );
        llPlaySound( GK_Sound_Zap, 1 );
    } else {
        llMessageLinked( LINK_THIS, 5, "0,1,2,3,4", "SET_SCREEN" );
        llStartAnimation( GS_Anim );
        llStopAnimation( "Zap" );
        llStopSound( );
    }
}


updateText() {
    string text = (string)(GF_Process * 100);
    integer index = llSubStringIndex( text, "." );
    text = llGetSubString( text, 0, index+2 );
    llSetText( "Progress: "+ text +"%", <1,1,1>, 1 );
}



progressReport( float new, float old, key id ) {
    if( new >= 0.5 && old < 0.5 ) {
        llMessageLinked( LINK_THIS, 5, "4,9,14,15,16", "SET_SCREEN" );
        //llSay( 0, llKey2Name( id ) +" makes great progress!" );
    } else if( new >= 0.75 && old < 0.75 ) {
        llMessageLinked( LINK_THIS, 5, "9,4,14,15,16", "SET_SCREEN" );
        //llSay( 0, llKey2Name( id ) +" is really getting into the gritty details!" );
    } else if( new >= 0.9 && old < 0.9 ) {
        llMessageLinked( LINK_THIS, 5, "14,4,9,15,16", "SET_SCREEN" );
        //llSay( 0, llKey2Name( id ) +" is dealing with the fine details!" );
    } else if( new >= 0.95 && old < 0.95 ) {
        llMessageLinked( LINK_THIS, 5, "15,4,9,14,16", "SET_SCREEN" );
        //llSay( 0, llKey2Name( id ) +" is so close he can taste victory!!!" );
    } else if( new >= 0.975 && old < 0.975 ) {
        llMessageLinked( LINK_THIS, 5, "16,4,9,14,15", "SET_SCREEN" );
        //llSay( 0, llKey2Name( id ) +" is almost done!!!!!" );
    }
}


/*
    DEBUGGING
*/
list data = [];
integer last_edge = -1;
integer last_level = -1;
log( string line ) {
    data += line;
    if( llGetListLength( data ) > 10 ) {
        data = llList2List( data, -10, -1 );
    }
}


default {
    state_entry() {
        llSetText( "", <1,1,1>, 1 );
        rotation rot = llEuler2Rot( <0,0,90> * DEG_TO_RAD );
        llSitTarget( <0,-0.58,-0.55>, rot );
        state ready;
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                llUnSit( id );
            }
        }
    }
}



state ready {
    on_rez( integer peram ) {
        state default;
    }
    
    state_entry() {
        llSetTimerEvent( 0 );
        llMessageLinked( LINK_THIS, 5, "0,1,2,3,4", "SET_SCREEN" );
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS );
                llSetTimerEvent( 5 );
            } else {
                stop();
                llMessageLinked( LINK_THIS, 5, "0,1,2,3,4", "SET_SCREEN" );
            }
        }
    }
    
    // lev = pressed
    // edg = changed
    // lev & edg = just pressed
    // !lev & edg = just released
    control( key id, integer lev, integer edg ) {
        if( last_edge != edg || last_level != lev ) {
            last_edge = edg;
            last_level = lev;
            log( (string)lev +","+ (string)edg +","+ (string)(lev&edg) +","+ (string)(lev&!edg) );
            //llSetText( llDumpList2String( data, "\n" ), <1,1,1>, 1 );
        }
        /*
        if( lev & edg == 1 ) {
            // just pressed forward
        } else if( lev & edg == 2 ) {
            // just pressed back
        }
        */
    }
    
    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TRIGGER_ANIMATION ) {
            start();
        }
        /*
        if( flag & PERMISSION_TAKE_CONTROLS ) {
            llTakeControls( CONTROL_BACK | CONTROL_FWD, TRUE, FALSE );
        }
        */
    }

    timer() {
        key id = llAvatarOnSitTarget();
        if( id == NULL_KEY ) {
            if( GF_Process > 0 ) {
                GF_Process -= 0.05;
                if( GF_Process <= 0 ) {
                    GF_Process = 0;
                }
            } else {
                llSetTimerEvent( 0 );
            }
            updateText();
            return;
        }
        integer a = llFloor( llFrand( 10 ) );
        if( a == 9 ) {
            llMessageLinked( LINK_THIS, 5, "3,0,1,2,3", "SET_SCREEN" );
            llSay( 0, llKey2Name( id ) +" fucked up so spectacularly the computer just gave up and died!" );
            state error;
        }
        if( a == 0 && !isZap ) {
            isZap = TRUE;
            zap( isZap );
            llSay( 0, llKey2Name( id ) +" gets shocked as a direct result of their stupidity!" );
            GF_Process *= 0.5;
        } else if( a != 0 && isZap ) {
            isZap = FALSE;
            zap( isZap );
            llSay( 0, llKey2Name( id ) +" recovers from their episode and gets back to work!" );
        } else if( !isZap ){
            float prog = GF_Process + (1-GF_Process) * 0.2;
            progressReport( prog, GF_Process, id );
            GF_Process = prog;
        }
        updateText();
    }
}



state error {
    on_rez( integer peram ) {
        state default;
    }
    
    state_entry() {
        isZap = FALSE;
        GF_Process = 0;
        llSetText( "", <1,1,1>, 1 );
        key id = llAvatarOnSitTarget();
        llUnSit( id );
        llSetTimerEvent( 300 );
    }
    
    touch( integer num ) {
        llWhisper( 0, llKey2Name( llDetectedKey( 0 ) ) +" attempts To repair the terminal" );
        llSleep( 5 );
        state ready;
    }
    
    timer() {
        state ready;
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION );
                llSetTimerEvent( 5 );
            } else {
                stop();
            }
        }
    }

    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TRIGGER_ANIMATION ) {
            key id = llAvatarOnSitTarget();
            llUnSit( id );
        }
    }
}

