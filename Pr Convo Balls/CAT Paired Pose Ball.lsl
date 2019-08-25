/*
// Cats makes the best programmers!  
// 
// Pose Ball script made for linking with another
//
// 201908251950
//
//
*/



string GS_Anim = "awkward";

integer GI_Set = FALSE;
key GK_Sitter = NULL_KEY;

vector GV_SitPos = <0,0,0.1>;
rotation GR_SitRot = ZERO_ROTATION;

vector GV_Color = <1,0,0>;

integer GI_Link_Target = LINK_THIS; // may or may not be this depending on if this is script 1 or 2
integer GI_SitLink = -1;


string GS_Stand = "base";

integer GI_SetPos = FALSE;

integer GI_RLVChan = -1812221819;







start( key id ) {
    GI_Set = FALSE;
    GK_Sitter = id;
    llRequestPermissions( GK_Sitter, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS );
    llSetLinkPrimitiveParamsFast( GI_Link_Target, [PRIM_COLOR,ALL_SIDES,GV_Color,0] );
}


stop() {
    if( GI_Set ) {
        GI_Set = FALSE;
        llSetLinkPrimitiveParamsFast( GI_Link_Target, [PRIM_COLOR,ALL_SIDES,GV_Color,1] );
        integer flag = llGetPermissions();
        if( llGetInventoryType( GS_Anim ) == INVENTORY_ANIMATION ) {
            if( flag & PERMISSION_TRIGGER_ANIMATION ) {
                llStopAnimation( GS_Anim );
                llStopAnimation( GS_Stand );
            }
        }
    }
}


adjPos( integer cmd ) {
    if( GI_SitLink == -1 ) {
        return;
    }
    float base = 0.025;
    vector adj = <0,0,0>;
    if( cmd&CONTROL_FWD ) {
        adj += <0,base,0>;
    }
    if( cmd&CONTROL_BACK ) {
        adj -= <0,base,0>;
    }
    if( cmd&CONTROL_ROT_RIGHT ) {
        adj += <base,0,0>;
    }
    if( cmd&CONTROL_ROT_LEFT ) {
        adj -= <base,0,0>;
    }
    if( cmd&CONTROL_UP ) {
        adj += <0,0,base>;
    }
    if( cmd&CONTROL_DOWN ) {
        adj -= <0,0,base>;
    }
    vector cpos = llList2Vector( llGetLinkPrimitiveParams( GI_SitLink, [PRIM_POS_LOCAL] ), 0 );
    llSetLinkPrimitiveParamsFast( GI_SitLink, [PRIM_POS_LOCAL, cpos + adj] );
}

integer findSitter() {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=2; i<=num; ++i ) {
        if( llGetLinkKey( i ) == GK_Sitter ) {
            //llSay( 0, "TA: "+ llKey2Name( GK_Sitter ) );
            return i;
        }
    }
    return -1;
}

message( key id, string msg ) {
    if( id != NULL_KEY ) {
        llRegionSayTo( id, 0, msg );
    }
}




unsit() {
    stop();
    llSleep( 0.1 );
    llOwnerSay( "@unsit=force" );
    llRegionSayTo( GK_Sitter, GI_RLVChan, "FBSys,"+ (string)GK_Sitter +",@unsit=force");
    llSleep( 0.1 );
    GK_Sitter = NULL_KEY;
    llResetScript();
}




sit() {
    llRegionSayTo( GK_Sitter, GI_RLVChan, "FBSys,"+ (string)GK_Sitter +",@sit:"+ (string)llGetLinkKey(LINK_THIS) +"=force");
}


default {
    on_rez( integer peram ) {
        if( peram != 0 ) {
            llSetTimerEvent(0.5);
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        sit();
    }
    
    state_entry() {
        llLinkSitTarget( GI_Link_Target, GV_SitPos, GR_SitRot );
        llSetLinkPrimitiveParamsFast( GI_Link_Target, [PRIM_COLOR, ALL_SIDES, GV_Color, 1]);
        llSetLinkCamera( GI_Link_Target, <-0.75,0.75,1.5>, <2,0,0.5> );
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( msg == "RELEASE" ) {
            stop();
            unsit();
            GK_Sitter = NULL_KEY;
        }
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnLinkSitTarget( GI_Link_Target );
            if( id != NULL_KEY && id != GK_Sitter ) {
                start( id );
            } else if( id == NULL_KEY && GK_Sitter != NULL_KEY ) {
                stop();
                GK_Sitter = NULL_KEY;
                llResetScript();
            }
            GI_SitLink = findSitter();
        }
    }
    
    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TRIGGER_ANIMATION ) {
            if( llGetInventoryType( GS_Anim ) == INVENTORY_ANIMATION ) {
                GI_Set = TRUE;
                llStopAnimation( "sit" );
                llStartAnimation( "stand" );
                llSleep(0.1);
                llStartAnimation( GS_Stand );
                llStartAnimation( GS_Anim );
                llSleep( 0.1 );
                llStopAnimation( "stand" );
                message( GK_Sitter, "Press pgUp & pgDown at the same time to edit position!" );
            } else {
                message( GK_Sitter, "Animation Missing" );
            }
        }
        if( flag & PERMISSION_TAKE_CONTROLS ) {
            llTakeControls( CONTROL_FWD|CONTROL_BACK|CONTROL_ROT_RIGHT|CONTROL_ROT_LEFT|CONTROL_UP|CONTROL_DOWN, TRUE, FALSE );
        }
    }

    control( key id, integer level, integer edge ) {
        integer end = ~level & edge;
        if( end & CONTROL_UP && end & CONTROL_DOWN ) {
            GI_SetPos = !GI_SetPos;
            if( GI_SetPos ) {
                message( GK_Sitter, "Adjust Position with up, down, left, right, pgup & pgdown keys" );
            } else {
                message( GK_Sitter, "Position Set" );
            }
            return;
        } else if( GI_SetPos && end ) {
            integer start = level & edge;
            integer held = level & ~edge;
            integer untouched = ~( level | edge );
            adjPos( end );
        }
    }
}
