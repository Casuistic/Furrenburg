/*
*   Bunker Gear Door Piston 
*
*
*   201912300320
*/


vector GP_Pos_Start;
rotation GR_Rot_Start;

vector GP_Pos_End;
rotation GR_Rot_End;

vector GV_Base_Pos;
vector GV_Base_Rot;

integer GI_Open = FALSE;
integer GI_Active = FALSE;

list GL_Keyframes;
float GF_Timer;

key GK_Root_Ref = "5ed5fbc1-4c48-e3c3-62f4-8b41715e23b1";
vector GP_Root_Pos;
rotation GR_Root_Rot;

integer GI_Listen = -1;
string GS_Data =  " [[\"<-6.51274, 1.60178, -0.11123>\",\"<0.000000, 0.000000, 0.000000>\"],[\"<0.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",0.250000],[\"<5.525000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",3.000000],[\"<0.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",0.500000],[\"<0.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",2.250000],[\"<0.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",0.500000],[\"<-4.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",2.500000],[\"<0.000000, 0.000000, 0.000000>\",\"<0.000000, 0.000000, 0.000000>\",0.125000]]";

list GL_Frame_Pos;
list GL_Frame_Rot; 
list GL_Frame_Time;
















// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}



stop() {
    llSetKeyframedMotion( [], [KFM_COMMAND,KFM_CMD_STOP] );
}

open() {
    llSetTimerEvent( GF_Timer );
    llSetKeyframedMotion ( GL_Keyframes, [KFM_MODE, KFM_FORWARD]);
}

close() {
    llSetTimerEvent( GF_Timer );
    llSetKeyframedMotion ( GL_Keyframes, [KFM_MODE, KFM_REVERSE] );
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
        llOwnerSay( "Door Frame Not Found. Self Terminating." );
        llDie();
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
    
    /* CALCULATE END POSITION & ROTATION */
    integer i;
    integer num = llGetListLength( GL_Frame_Pos );
    vector spos = ZERO_VECTOR;
    vector srot = ZERO_VECTOR;
    for( i=0; i<num; ++i ) {
        spos += llList2Vector( GL_Frame_Pos, i );
        srot += llList2Vector( GL_Frame_Rot, i );
    }
    GP_Pos_End = GP_Pos_Start + (spos * GR_Root_Rot);
    GR_Rot_End = llEuler2Rot( (GV_Base_Rot + srot) * DEG_TO_RAD ) * GR_Root_Rot;
    /* END OF END POS & ROT CALCULATION */
    
    genKeyframes();
    
    setKnownState( GP_Pos_Start, GR_Rot_Start );
}

parseStringData() {
    /* PARSE STORED DATA */
    list p = [];
    list r = [];
    list t = [];
    list break = llJson2List( GS_Data );
    if( llGetListLength( break ) >= 2 ) {
        list start = llJson2List( llList2String( break, 0 ) );
        if( llGetListLength( start ) == 2 ) {
            GV_Base_Pos = (vector)llList2String( start, 0 );
            GV_Base_Rot = (vector)llList2String( start, 1 );
            integer i;
            integer num = llGetListLength( break );
            for( i=1; i<num; ++i ) {
                list d = llJson2List( llList2String( break, i ) );
                p += (vector)llList2String( d, 0 );
                r += (vector)llList2String( d, 1 );
                t += (float)llList2String( d, 2 );
            }
        }
    }

    GL_Frame_Pos = p;
    GL_Frame_Rot = r; 
    GL_Frame_Time = t;
    /* END OF DATA PARSE */
}

genKeyframes() {
    /* GENERATE KEYFRAME DATA */
    list keyframes = [];
    float time = 0.5;
    integer i;
    integer num = llGetListLength( GL_Frame_Pos );
    //list json = [llList2Json( JSON_ARRAY, [GV_Base_Pos, GV_Base_Rot] )];
    for( i=0; i<num; ++i ) {
        keyframes += [
            llList2Vector( GL_Frame_Pos, i ) * GR_Rot_Start, 
            llEuler2Rot ( llList2Vector( GL_Frame_Rot, i ) * DEG_TO_RAD),
            llList2Float( GL_Frame_Time, i ) ];
            //json += llList2Json( JSON_ARRAY, [llList2Vector( GL_Frame_Pos, i ), llList2Vector( GL_Frame_Rot, i ), llList2Float( GL_Frame_Time, i )] );
            time += llFabs( llList2Float( GL_Frame_Time, i ) );
    }
    //llOwnerSay( llList2Json( JSON_ARRAY, json ) );
    GL_Keyframes = keyframes;
    GF_Timer = time;
    /* END OF KEYFRAME GENERATION */
}


// texture animation wont let me play an animation once and then stop so this is the dirty work around
move( integer sign ) {
    key id = "0939027b-6189-31fc-e28e-9f3a3c370b6f";
    integer i;
    integer num = 15;
    
    float pre;
    float step =sign * (0.3 / num);;
    if( sign < 0 ) {
        pre = 0.3;
    }
    for( i=1; i<=num; ++i ) {
        float mod = step * i;
        llSetLinkPrimitiveParamsFast( LINK_THIS, [PRIM_TEXTURE, 2, id, <0.9,1,0>, 
        <0.2 + (pre+mod),0,0>,
         0]);
        llSleep( 0.01 );
    }
}






default {
    on_rez( integer peram ) {
        if( peram != 0 ) {
            GI_Listen = llListen( peram, "", "", "SetRef" );
        }
        stop();
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( msg == "SetRef" ) {
            llListenRemove( GI_Listen );
            GK_Root_Ref = id;
            
            parseStringData();
            
            state ready;
        }
    }

    state_entry() {
        stop();
    }
    
}



state ready {
    on_rez( integer peram ) {
        state default;
    }
    

    state_entry() {
        integer chan = key2Chan( GK_Root_Ref, 499999, 500000 );
        llListen( chan, "", "", "Door Open" );
        llListen( chan, "", "", "Door Close" );
        stop();
        setRef();
        setup();
    }
    
    
    listen( integer chan, string name, key id, string msg ) {
        if( msg == "Door Open" ) {
            GI_Open = TRUE;
            verifyRoot();
            setKnownState( GP_Pos_Start, GR_Rot_Start );
            open();
            llSleep( 2.75 );
            move( 1 );
            llSleep( 1.5 );
            move( -1 );
        } else if( msg == "Door Close" ) {
            GI_Open = FALSE;
            verifyRoot();
            setKnownState( GP_Pos_End, GR_Rot_End );
            close();
            llSleep( 3.25 );
            move( 1 );
            llSleep( 1.5 );
            move( -1 );
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

