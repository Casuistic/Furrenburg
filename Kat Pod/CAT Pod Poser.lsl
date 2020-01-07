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


#include <oups.lsl> // debugging
string GS_Script_Name = "CAT Pod Poser"; // debugging

integer anim_index = 0;

vector GV_Pos_Adj = <0,0,0>;
vector GV_Pos_Adj_Limit = <0.5,0.5,0.5>;

integer GI_Hit = FALSE;
integer GI_Adjust = FALSE;

integer GI_Sealed = FALSE; // used for detecting escape
integer GI_Closed = FALSE; // used to see when pod is closed

integer GI_DB_Chan = -1193;


key GK_User = NULL_KEY; // used for offline check
integer GI_User_CD = 0; // count down post user exit
key GK_QID_Online_Check = NULL_KEY; // dataserver ref id





adjustUser( key id ) {
    if( id == NULL_KEY ) {
        return;
    }
    integer i;
    for( i = llGetNumberOfPrims(); i > 0; --i ) {
        if( llGetLinkKey( i ) == id ) {
            llSetLinkPrimitiveParamsFast( i, [
                    PRIM_POS_LOCAL, <0,0,0.1> + GV_Pos_Adj,
                    PRIM_ROT_LOCAL, llEuler2Rot( <0,0,90> * DEG_TO_RAD )
                ]);
            return;
        }
    }
}


startPosAdjust( integer bool ) {
    GI_Adjust = bool;
    if( GI_Adjust ) {
        llRegionSayTo( llAvatarOnSitTarget(), 0, "Use movement controls to adjust position." );
        llTakeControls( 
            CONTROL_UP | CONTROL_DOWN
            | CONTROL_FWD | CONTROL_BACK
            | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT
            , TRUE, FALSE );
    } else {
        llRegionSayTo( llAvatarOnSitTarget(), 0, "Position Adjustment Finished." );
        llTakeControls( CONTROL_UP | CONTROL_DOWN, TRUE, FALSE );
    }
}


adjustPos( integer act ) {
    float mod = 0.025;
    if( act & CONTROL_UP ) {
        GV_Pos_Adj.z += mod;
        if( GV_Pos_Adj.z > GV_Pos_Adj_Limit.z ) {
            GV_Pos_Adj.z = GV_Pos_Adj_Limit.z;
        }
    }
    if( act & CONTROL_DOWN ) {
        GV_Pos_Adj.z -= mod;
        if( GV_Pos_Adj.z < -GV_Pos_Adj_Limit.z ) {
            GV_Pos_Adj.z = -GV_Pos_Adj_Limit.z;
        }
    }
    if( act & CONTROL_FWD ) {
        GV_Pos_Adj.y += mod;
        if( GV_Pos_Adj.y > GV_Pos_Adj_Limit.y ) {
            GV_Pos_Adj.y = GV_Pos_Adj_Limit.y;
        }
    }
    if( act & CONTROL_BACK ) {
        GV_Pos_Adj.y -= mod;
        if( GV_Pos_Adj.y < -GV_Pos_Adj_Limit.y ) {
            GV_Pos_Adj.y = -GV_Pos_Adj_Limit.y;
        }
    }
    if( act & CONTROL_ROT_LEFT ) {
        GV_Pos_Adj.x += mod;
        if( GV_Pos_Adj.x > GV_Pos_Adj_Limit.x ) {
            GV_Pos_Adj.x = GV_Pos_Adj_Limit.x;
        }
    }
    if( act & CONTROL_ROT_RIGHT ) {
        GV_Pos_Adj.x -= mod;
        if( GV_Pos_Adj.x < -GV_Pos_Adj_Limit.x ) {
            GV_Pos_Adj.x = -GV_Pos_Adj_Limit.x;
        }
    }
    adjustUser( llAvatarOnSitTarget() );
}


getUser() {
    key id = llAvatarOnSitTarget();
    if( id != NULL_KEY ) {
        if( GI_Closed && id != GK_User ) {
            llRegionSayTo( id, 0, "Try opening the pod before sitting in it!" );
            llUnSit( id );
            return;
        }
        if( GI_Closed ) {
            llMessageLinked( LINK_THIS, 130, (string)id, "RefreshRLV" );
        }
        if( GK_User == id ) {
            llMessageLinked( LINK_THIS, 210, "Captive has been recaptured!", "Tattle" );
        } else {
            GK_User = id;
        }
        llSetTimerEvent( 0 );
        llMessageLinked( LINK_THIS, 130, (string)llAvatarOnSitTarget(), "NewUser" );
        llRequestPermissions( id, 
                PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA );
    } else {
        checkForEscape( id );
        if( llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetAgentSize( id ) != ZERO_VECTOR ) {
            llStopAnimation( llGetInventoryName( INVENTORY_ANIMATION, anim_index ) );
        }
        llMessageLinked( LINK_THIS, 130, (string)NULL_KEY, "NewUser" );
        //llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
        GI_Hit = FALSE;
        GI_Adjust = FALSE;
    }
}


checkForEscape( key id ) {
    if( id == NULL_KEY && id != GK_User && GI_Closed ) {
        // pos is closed
        if( llGetAgentSize( GK_User ) != ZERO_VECTOR ) {    // still in sim
            llMessageLinked( LINK_THIS, 210, "Captive has left Pod", "Tattle" );
            doCapture( GK_User );
        } else {
            llMessageLinked( LINK_THIS, 210, "Captive has left Sim: '"+ llGetRegionName() +"'", "Tattle" );
        }
        GI_User_CD = 60;
        llSetTimerEvent( 10 );
    } else {
        GK_User = id;
    }
}


lookupOnline( key id ) {
    if( id != NULL_KEY ) {
        GK_QID_Online_Check = llRequestAgentData( id, DATA_ONLINE );
    }
}


doCapture( key id ) {
    if( id != NULL_KEY ) {
        llMessageLinked( LINK_THIS, 130, (string)GK_User, "Capture" );
    }
}


performRLVSafeword() {
    key id = llAvatarOnSitTarget();
    if( GI_Closed || GI_Sealed ) {
        GI_Closed = FALSE;
        GI_Sealed = FALSE;
        llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
    }
    if( id != NULL_KEY ) {
        llUnSit( id );
    }
}






/*
*   START OF STATES
*   Because it is easier than regularly adjusting spacing
*/


default {
    dataserver(key qid, string data) {
        if ( GK_QID_Online_Check == qid ) {
            GK_QID_Online_Check = NULL_KEY;
            if( data == "1" ) { // user is online;
                // user is online
            } else {
                // user is offline
            }
        }
    }

    timer() {
        //llSetText( "EC\nT1: "+ (string)GI_User_CD, <1,1,1>, 1 );
        if ( --GI_User_CD >= 0 ) {
            if( llGetAgentSize( GK_User ) == ZERO_VECTOR ) {
                lookupOnline( GK_User );
            } else {
                doCapture( GK_User );
            }
        } else {
            llMessageLinked( LINK_THIS, 210, "Captive has Not Returned", "Tattle" );
            llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
            llSetTimerEvent( 0 );
            GK_User = NULL_KEY;
            GI_User_CD = -1;
        }
    }

    state_entry() {
        safeLoad();
        llWhisper( GI_DB_Chan, "'"+ llGetScriptName() +"' Reset" );
        llSitTarget( <0,1,-0.35>, llEuler2Rot( <0,0,90> * DEG_TO_RAD ) );
        
        llSetCameraAtOffset( <0,-0.5,0.25> );
        llSetCameraEyeOffset( <0,2.5,1.5> );
        getUser();
    }
    
    changed( integer change ) {
        if( change & CHANGED_LINK ) {
            getUser();
        }
    }
    
    run_time_permissions( integer flags ) {
        if( flags & PERMISSION_TRIGGER_ANIMATION ) {
            adjustUser( llAvatarOnSitTarget() );
            llStopAnimation( "sit" );
            llStartAnimation( llGetInventoryName( INVENTORY_ANIMATION, anim_index ) );
        }
        if( flags & PERMISSION_TAKE_CONTROLS ) {
            llTakeControls( CONTROL_UP | CONTROL_DOWN, TRUE, FALSE );
        }
        if( flags & PERMISSION_CONTROL_CAMERA ) {
            //setCam();
        }
    }

    link_message( integer src, integer num, string msg, key id ) {
        if( num == 110 ) {
            integer index = anim_index + 1;
            if( index < llGetInventoryNumber( INVENTORY_ANIMATION ) ) {
                llStartAnimation( llGetInventoryName( INVENTORY_ANIMATION, index ) );
                llStopAnimation( llGetInventoryName( INVENTORY_ANIMATION, anim_index ) );
                anim_index = index;
            } else {
                index = 0;
                llStartAnimation( llGetInventoryName( INVENTORY_ANIMATION, index ) );
                llStopAnimation( llGetInventoryName( INVENTORY_ANIMATION, anim_index ) );
                anim_index = index;
            }
        } else if( num == 100 && id == "PodState" ) {
            /*
            if( msg == "Open" ) {
                GI_Closed = FALSE;
            } else 
            */
            if( msg == "Closed" ) {
                GI_Closed = TRUE;
            } else if ( msg == "Opening" ) {
                GI_Closed = FALSE;
            }/* else if ( msg == "Closing" ) {
                // do what you got to do when closing
            } else {
                llOwnerSay( "Unknown Pod State Message: '"+ msg +"'" );
            }*/
        }  else if( num == 500 && id == "safeword" ) {
            performRLVSafeword();
        }
    }

    control( key id, integer level, integer edge ) {
        integer held = (level&~edge);
        if( held == (CONTROL_UP | CONTROL_DOWN) ) {
            if( !GI_Hit ) {
                GI_Hit = TRUE;
            }
        } else if( GI_Hit ) {
            GI_Hit = FALSE;
            startPosAdjust( !GI_Adjust );
        } else if( GI_Adjust ) {
            adjustPos( ~level&edge );
        }
    }
}
