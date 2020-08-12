/*
*   release timer function
*
*
*/

// 202008120350 implamented timer function



integer GI_Lock = 1;
integer GI_Lock_Max = 604800;
integer GI_Lock_Min = 30;
integer GI_Lock_Length = 1800;
integer GI_Lock_Cur = -1;

integer GI_Timer_Interval = 1;

integer GI_Timer_Running = FALSE;


key GK_User = NULL_KEY;




#include <CAT Oups.lsl> // debugging
string GS_Script_Name = "CAT Pod Time Release"; // debugging



key getUser() {
    return llAvatarOnSitTarget();
}




timer_reset() {
    //llSay( 0, "Time Reset" );
    GI_Lock_Cur = GI_Lock_Length;
}


timer_clear() {
    //llSay( 0, "Time Cleared" );
    GI_Lock_Cur = -1;
}


timer_start() {
    //llSay( 0, "TIMER START" );
    timer_reset();
    llMessageLinked( LINK_SET, 250, "1", "TIMER" );
    GI_Timer_Running = TRUE;
    llSetTimerEvent( GI_Timer_Interval );
}


timer_end() {
    //llSay( 0, "TIMER STOP" );
    timer_clear();
    llMessageLinked( LINK_SET, 250, "0", "TIMER" );
    GI_Timer_Running = FALSE;
    llSetTimerEvent( 0 );
}


timer_suspend() {
    if( GI_Timer_Running ) {
        //llSay( 0, "TIMER PAUSE" );
        llMessageLinked( LINK_SET, 250, "-1", "TIMER" );
        llSetTimerEvent( 0 );
    }
}


timer_resume() {
    if( GI_Timer_Running ) {
        //llSay( 0, "TIMER RESUME" );
        llMessageLinked( LINK_SET, 250, "1", "TIMER" );
        llSetTimerEvent( GI_Timer_Interval );
    }
}






default {
    state_entry() {
        safeLoad();
    }
    
    link_message( integer src, integer num, string msg, key id ) {
    // newuser comes from poser
    // set data comes from UI
    // tattle comes from UI and indicates uswer left/returnd
    // open/close pod comes from many scripts
        string tag = (string)id;
        if( num == 240 ) {
            //llSay( 0, "Time Cmd: "+ msg +" / "+ tag );
            if( tag == "TIME_LOCK" ) {
                GI_Lock = (integer)msg;
                //llSay( 0, "Time Release: "+ (string)GI_Lock );
            } else if ( tag = "TIME_LENGTH" ) {
                integer len = (integer)msg;
                if( len < GI_Lock_Min ) {
                    GI_Lock_Length = GI_Lock_Min;
                } else if( len > GI_Lock_Max ) {
                    GI_Lock_Length = GI_Lock_Max;
                } else {
                    GI_Lock_Length = len;
                }
                //llSay( 0, "Time Release set: "+ (string)GI_Lock_Length );
            }
        } else if( !GI_Lock ) {
            // timer system disabled
            return;
        } else if( num == 120 ) {
            if( tag == "OpenPod" ) {
                if( msg == "0" ) {
                    //llOwnerSay( "Pod Closed" );
                    if( GK_User != NULL_KEY ) {
                        if( GI_Lock_Cur > 0 ) {
                            timer_resume();
                        } else {
                            timer_start();
                        }
                    } else {
                        if( getUser() != NULL_KEY ) {
                            if( GI_Lock_Cur > 0 ) {
                                timer_resume();
                            } else {
                                timer_start();
                            }
                        }/* else {
                            llOwnerSay( "No one in pod?" );
                        }*/
                    }
                } else {
                    if( GI_Lock_Cur > 0 ) {
                        timer_suspend();
                    }
                }
            }
        } else if( num == 130 ) {
            if( tag == "NewUser" ) {
                key user = (key)msg;
                if( user != NULL_KEY ) {
                    if( GI_Timer_Running ) {
                        timer_resume();
                    }
                } else {
                    timer_suspend();
                }
                GK_User = user;
            }
        }
        //llSay(0, (string)src +": "+ (string)num +" / "+ msg +" ["+ (string)tag +"]" );
    }
    
    
    timer() {
        GI_Lock_Cur -= GI_Timer_Interval;
        if( GI_Lock_Cur <= 0 ) {
            timer_end();
            //llSetText( "", <1,1,1>, 1 );
        }
        //llSetText( "Time Test: "+ (string)GI_Lock_Cur, <1,1,1>, 1 );
    }
}
