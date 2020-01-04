/*
*   Bunker Gear Door Piston 
*
*
*   201912300320
*   201912301700
*   201912310711
*/








integer GI_Open = FALSE;
//integer GI_Active = FALSE;



key GK_Root_Ref = NULL_KEY;
vector GP_Root_Pos;
rotation GR_Root_Rot;

integer GI_Listen = -1;
integer GI_Chan = -1;



list GL_Frames_Open = [
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.250000,
        <5.525000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 3.000000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.500000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 2.250000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.500000,
        <-4.00000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 2.500000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.125000
];

list GL_Keyframes_Open;
float GF_Timer_Open;

list GL_Frames_Close = [
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.250000,
        <4.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 2.500000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 6.500000,
        <-5.52500, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 3.000000,
        <0.000000, 0.000000, 0.000000>, <0.000000, 0.000000, 0.000000>, 0.250000
];

list GL_Keyframes_Close;
float GF_Timer_Close;



vector GV_Base_Pos = <-6.51274, 1.60178, -0.11123>;
vector GV_Base_Rot = <0.00000, 0.00000, 0.00000>;

vector GP_Pos_Start;   // generated based on frame data and base pos/rot
rotation GR_Rot_Start; // generated based on frame data and base pos/rot

vector GP_Pos_End;   // generated based on start and frame data
rotation GR_Rot_End; // generated based on start and frame data

// spindol texture positions
vector GV_Shaft_In = <0.2,0,0>;
vector GV_Shaft_Half = <0.35,0,0>;
vector GV_Shaft_Out = <0.5,0,0>;




// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

integer genChan() {
    integer offset = (integer)llGetObjectDesc();
    integer number = key2Chan( llGetOwner(), 499999, 500000 );
    integer chan = offset + number;
    if( chan == 0 ) {
        chan = number - offset;
        if( chan == 0 ) {
            chan = number;
        }
    }
    llOwnerSay( "Active Chan: "+ (string)chan );
    return chan;
}

integer genBaseChan() {
    integer chan = (integer)llGetObjectDesc();
    if( chan == 0 ) {
        chan = 42;
    }
    return chan;
}

reqRef( integer chan ) {
    llListenRemove( GI_Listen );
    GI_Listen = llListen( chan, "", "", "SetRef" );
    llSay( chan, "Need Ref" );
}





stop() {
    llSetKeyframedMotion( [], [KFM_COMMAND,KFM_CMD_STOP] );
}

open() {
    llSetTimerEvent( GF_Timer_Open );
    llSetKeyframedMotion ( GL_Keyframes_Open, [KFM_MODE, KFM_FORWARD]);
}

close() {
    llSetTimerEvent( GF_Timer_Close );
    llSetKeyframedMotion ( GL_Keyframes_Close, [KFM_MODE, KFM_FORWARD] );
}

setKnownState( vector pos, rotation rot ) {
    stop();
    llSetLinkPrimitiveParamsFast( LINK_THIS, [
                PRIM_POSITION,pos,
                PRIM_ROTATION,rot
            ] );   
}




verifyRoot() {
    if( llGetOwnerKey( GK_Root_Ref ) == llGetOwner() ) {
        list data = llGetObjectDetails( GK_Root_Ref, [OBJECT_POS, OBJECT_ROT] );
        vector pos  = llList2Vector( data, 0 );
        rotation rot = llList2Rot( data, 1 );
        if( pos != GP_Root_Pos || rot != GR_Root_Rot ) {
            GP_Root_Pos = pos;
            GR_Root_Rot = rot;
            setup();
        }
    } else {
        llOwnerSay( "Err: Door Frame Not Found." );
    }
}

setRef() {
    list data = llGetObjectDetails( GK_Root_Ref, [OBJECT_POS, OBJECT_ROT] );
    GP_Root_Pos = llList2Vector( data, 0 );
    GR_Root_Rot = llList2Rot( data, 1 );
}

setup() {
    /* CALCULATE START POS & ROT */
    GP_Pos_Start =  (GV_Base_Pos * GR_Root_Rot) + GP_Root_Pos;
    GR_Rot_Start = llEuler2Rot( GV_Base_Rot * DEG_TO_RAD ) * GR_Root_Rot;
    /* END OF CALC START POS & ROT */

    list temp = genKeyframes( GL_Frames_Open, GR_Rot_Start );
    GL_Keyframes_Open = llList2List( temp, 3, -1 );
    GF_Timer_Open = llList2Float( temp, 2 );
    GP_Pos_End = GP_Pos_Start + (llList2Vector( temp, 0 ) * GR_Root_Rot);
    GR_Rot_End = llEuler2Rot( (GV_Base_Rot + llList2Vector( temp, 1 )) * DEG_TO_RAD ) * GR_Root_Rot;
    
    temp = genKeyframes( GL_Frames_Close, GR_Rot_Start );
    GL_Keyframes_Close = llList2List( temp, 3, -1 );
    GF_Timer_Close = llList2Float( temp, 2 );
    vector ep = GP_Pos_Start + (llList2Vector( temp, 0 ) * GR_Root_Rot);
    rotation er = llEuler2Rot( (GV_Base_Rot + llList2Vector( temp, 1 )) * DEG_TO_RAD ) * GR_Root_Rot;
    // verify movement comes back to start?
}

list genKeyframes( list frame_data, rotation root_rot ) {
    /* GENERATE KEYFRAME DATA */
    list keyframes = [];
    float time = 0.5;
    integer i;
    integer num = llGetListLength( frame_data );
    vector tpos = ZERO_VECTOR;
    vector trot = ZERO_VECTOR;
    for( i=0; i<num; i+=3 ) {
        keyframes += [
            llList2Vector( frame_data, i ) * root_rot, 
            llEuler2Rot ( llList2Vector( frame_data, i+1 ) * DEG_TO_RAD),
            llList2Float( frame_data, i+2 ) ];
            time += llFabs( llList2Float( frame_data, i+2 ) );
        tpos += llList2Vector( frame_data, i );
        trot += llList2Vector( frame_data, i+1 );
    }
    return [tpos, trot, time] + keyframes;
    /* END OF KEYFRAME GENERATION */
}



// texture animation wont let me play an animation once and then stop so this is the dirty work around
move( vector end ) {
    key id = "0939027b-6189-31fc-e28e-9f3a3c370b6f";

    integer steps = 15;

    vector sta = llList2Vector( llGetLinkPrimitiveParams( LINK_THIS, [PRIM_TEXTURE, 2] ), 2 ); //<0.2,0,0>;
    vector ste = (end - sta) / steps;
    
    integer i;
    for( i=1; i<=steps; ++i ) {
        llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_TEXTURE, 2, id, <0.9,1,0>, 
        sta + (ste*i),
         0]);
        llSleep( 0.01 );
    }
}



integer filterListen( key id ) {
    if( llGetOwner() != llGetOwnerKey( id ) ) {
        return TRUE;
    }
    if( llList2String( llGetObjectDetails( id, [OBJECT_DESC] ), 0 ) != llGetObjectDesc() ) {
        return TRUE;;
    }
    return FALSE;
}










default {
    on_rez( integer peram ) {
        if( peram != 0 ) {
            llSetObjectDesc( (string)peram );
            reqRef( peram );
        } else {
            reqRef( genBaseChan() );
        }
        stop();
    }
    
    state_entry() {
        stop();
        llSetTimerEvent( 15 );
        reqRef( genBaseChan() );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        llOwnerSay( "Err: Frame Ref Not Set" );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( filterListen(id) ) {
            return;
        }
        if( msg == "SetRef" ) {
            llListenRemove( GI_Listen );
            GK_Root_Ref = id;
            state ready;
        }
    }
}



state ready {
    on_rez( integer peram ) {
        state default;
    }
    

    state_entry() {
        GI_Chan = genChan();
        llListen( GI_Chan, "", "", "Open Bunker" );
        llListen( GI_Chan, "", "", "Close Bunker" );
        stop();
        setRef();
        setup();
        llOwnerSay( "Ready!" );
    }
    
    
    listen( integer chan, string name, key id, string msg ) {
        if( filterListen(id) ) {
            return;
        }
        if( msg == "Open Bunker" ) {
            GI_Open = TRUE;
            verifyRoot();
            setKnownState( GP_Pos_Start, GR_Rot_Start );
            open();
            llSleep( 2.75 );
            move( GV_Shaft_Out );
            llSleep( 1.5 );
            move( GV_Shaft_Half );
        } else if( msg == "Close Bunker" ) {
            GI_Open = FALSE;
            verifyRoot();
            setKnownState( GP_Pos_End, GR_Rot_End );
            close();
            llSleep( 3.25 );
            move( GV_Shaft_Half );
            llSleep( 1.25 );
            move( GV_Shaft_Out );
            llSleep( 1.25 );
            move( GV_Shaft_In );
        }
    }
    
    
    timer() {
        llSetTimerEvent( 0 );
        if( !GI_Open ) {
            setKnownState( GP_Pos_Start, GR_Rot_Start );
        } else {
            setKnownState( GP_Pos_End, GR_Rot_End );
        }
    }
    
}
