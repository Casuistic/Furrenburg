/*
    CAT User Animator and pose adjust control script
    Likely could bemerged with main(ui) script to have only one change event


*/
// 202001041738

integer anim_index = 0;


vector GV_Pos_Adj = <0,0,0>;


integer GI_Hit = FALSE;
integer GI_Adjust = FALSE;


integer GI_Closed = FALSE;








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
        GV_Pos_Adj += <0,0,mod>;
    }
    if( act & CONTROL_DOWN ) {
        GV_Pos_Adj -= <0,0,mod>;
    }
    if( act & CONTROL_FWD ) {
        GV_Pos_Adj += <0,mod,0>;
    }
    if( act & CONTROL_BACK ) {
        GV_Pos_Adj -= <0,mod,0>;
    }
    if( act & CONTROL_ROT_LEFT ) {
        GV_Pos_Adj += <mod,0,0>;
    }
    if( act & CONTROL_ROT_RIGHT ) {
        GV_Pos_Adj -= <mod,0,0>;
    }
    adjustUser( llAvatarOnSitTarget() );
}









default {
    state_entry() {
        llWhisper( 0, "'"+ llGetScriptName() +"' Reset" );
        llSitTarget( <0,1,-0.35>, llEuler2Rot( <0,0,90> * DEG_TO_RAD ) );
        
        llSetCameraAtOffset( <0,-0.5,0.25> );
        llSetCameraEyeOffset( <0,2.5,1.5> );
    }
    
    changed( integer change ) {
        if( change & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                if( GI_Closed ) {
                    llRegionSayTo( id, 0, "Try opening the pod before sitting in it!" );
                    llUnSit( id );
                    return;
                }
                llMessageLinked( LINK_THIS, 130, (string)llAvatarOnSitTarget(), "NewUser" );
                llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA );
            } else {
                if( llGetPermissions() & PERMISSION_TRIGGER_ANIMATION ) {
                    llStopAnimation( llGetInventoryName( INVENTORY_ANIMATION, anim_index ) );
                }
                llMessageLinked( LINK_THIS, 130, (string)NULL_KEY, "NewUser" );
                llMessageLinked( LINK_THIS, 120, (string)TRUE, "OpenPod" );
                GI_Hit = FALSE;
                GI_Adjust = FALSE;
            }
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
            if( msg == "Open" ) {
                GI_Closed = FALSE;
            } else if( msg == "Closed" ) {
                GI_Closed = TRUE;
            }
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
