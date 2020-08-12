/*
    CAT Prim Animator 
    Heavily dependent on sleep.
    Load test one that uses quick timer option instead


*/
// 202001041738
// 202001051745
// 202001052125
// 202001071140 // added recapture feature
// 202001071751 // handled auto scaling
// 202001071915 // fixed recapture ignoring safeword
// 202008120350 // implamented timer release function


#include <CAT Oups.lsl> // debugging
string GS_Script_Name = "CAT Pod Prim Mover"; // debugging


float GV_Ref_Scale = 2.62071; // used for scaling relative to the root prims z scale




// prim animation data
list GL_Frames_RT = [
        <0.203320, 0.125000, 0.925000>, <0.000000, 0.000000, 180.000000>,
        <0.203320, 0.125000, 0.987510>, <0.000000, 0.000000, 180.000000>,
        <0.303320, 0.125000, 1.103150>, <4.000000, 0.000000, 180.000000>,
        <0.303320, -0.001280, 1.340550>, <3.926590, -0.780380, 168.776900>,
        <0.303320, -0.001280, 1.340550>, <3.926590, -0.780380, 168.776900>
];

list GL_Frames_LT = [
        <-0.203320, 0.125000, 0.925000>, <0.000000, 0.000000, 180.000000>,
        <-0.203320, 0.125000, 0.987510>, <0.000000, 0.000000, 180.000000>,
        <-0.303320, 0.125000, 1.103150>, <4.000000, 0.000000, 180.000000>,
        <-0.303320, -0.001280, 1.340550>, <3.926580, 0.780390, 191.2232>,
        <-0.303320, -0.001280, 1.340550>, <3.926580, 0.780390, 191.2232>
];

list GL_Frames_R = [
        <0.221000, 0.150000, 0.000000>, <0.000000, 0.000000, 180.000000>,
        <0.221000, 0.150000, 0.000000>, <0.000000, 0.000000, 180.000000>,
        <0.421000, 0.149990, 0.000000>, <0.000000, 0.000000, 174.375100>,
        <0.421000, 0.149990, 0.179860>, <0.000000, 0.000000, 129.375000>,
        <0.421000, -0.064180, 0.179860>, <0.000000, 0.000000, 129.375000>
];

list GL_Frames_L = [
        <-0.221000, 0.150000, 0.000000>, <0.000000, 0.000000, 180.000000>,
        <-0.221000, 0.150000, 0.000000>, <0.000000, 0.000000, 180.000000>,
        <-0.421000, 0.149990, 0.000000>, <0.000000, 0.000000, 185.6249>,
        <-0.421000, 0.149990, 0.179860>, <0.000000, 0.000000, 230.625>,
        <-0.421000, -0.064180, 0.179860>, <0.000000, 0.000000, 230.625>
];

list GL_Frames_RB = [
        <0.201110, 0.150000, -0.935000>, <0.000000, 0.000000, 180.000000>,
        <0.201110, 0.149990, -1.015860>, <0.000000, 0.000000, 180.000000>,
        <0.309130, 0.149990, -1.065860>, <-9.000000, 0.000000, 180.000000>,
        <0.409130, 0.149990, -1.103890>, <-32.000000, 0.000000, 180.000000>,
        <0.409130, 0.149990, -1.103890>, <-32.000000, 0.000000, 180.000000>
];

list GL_Frames_LB = [
        <-0.201110, 0.150000, -0.935000>, <0.000000, 0.000000, 180.000000>,
        <-0.201110, 0.149990, -1.015860>, <0.000000, 0.000000, 180.000000>,
        <-0.301110, 0.149990, -1.065860>, <-9.000000, 0.000000, 180.000000>,
        <-0.401110, 0.149990, -1.103890>, <-32.000000, 0.000000, 180.000000>,
        <-0.401110, 0.149990, -1.103890>, <-32.000000, 0.000000, 180.000000>
];



integer GI_Frame_Data_Length = 2; // number of items in each frame: 2 pos + rot

// store needed links
integer GI_Link_RT; // set by script
integer GI_Link_R;  // set by script
integer GI_Link_RB; // set by script
integer GI_Link_LT; // set by script
integer GI_Link_L;  // set by script
integer GI_Link_LB; // set by script


integer GI_Index; // set by script
integer GI_Dir = 1; // values:  1 open(ing) // -1 close(ing)


list GL_Sound_KV = []; // stores event frame + sound uuid/name. set by notecard load

integer GI_DB_Chan = -1191;



// map the link set finding the needed prims
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=2; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( llGetSubString( name, 0, 0 ) == "." ) {
            if( name == ".l" ) {
                GI_Link_L = i;
            } else if( name == ".lt" ) {
                GI_Link_LT = i;
            } else if( name == ".lb" ) {
                GI_Link_LB = i;
            } else if( name == ".r" ) {
                GI_Link_R = i;
            } else if( name == ".rt" ) {
                GI_Link_RT = i;
            } else if( name == ".rb" ) {
                GI_Link_RB = i;
            }
        }
    }
}

// perform open/close function
integer run() {//GV_Ref_Scale
    vector v = llList2Vector( llGetLinkPrimitiveParams( LINK_ROOT, [PRIM_SIZE] ), 0 );
    float scale = v.z / GV_Ref_Scale;
    integer index = GI_Index;
    
    if( GI_Dir < 1 ) { // is opening
        GI_Index -= 1;
        
        if( GI_Index < 0 ) {
            GI_Index = 0;
            soundEvent( GI_Index );
            llMessageLinked( LINK_THIS, 100, "Closed", "PodState" );
            return FALSE;
        }

        index = (index -2) * GI_Frame_Data_Length;

        if( index < 0 ) {
            soundEvent( GI_Index );
            llMessageLinked( LINK_THIS, 100, "Closed", "PodState" );
            return FALSE;
        }
    } else { // if closing
        GI_Index += 1;
        
        if( (GI_Index*GI_Frame_Data_Length) >= llGetListLength( GL_Frames_LT ) ) {
            GI_Index = llGetListLength( GL_Frames_LT ) / GI_Frame_Data_Length;
            soundEvent( GI_Index );
            llMessageLinked( LINK_THIS, 100, "Open", "PodState" );
            return FALSE;
        }
        
        index *= GI_Frame_Data_Length;
    }
    
    soundEvent( GI_Index );
    
    integer i;
    integer num = 10;
    // passing whole lists needs to be replaced with passing in needed data
    // do step handling before the loop and just dump all the needed info into doStep
    for( i=1; i<=num; ++i ) {
        frame( GI_Link_LT, GL_Frames_LT, index, i, GI_Dir, scale );
        frame( GI_Link_RT, GL_Frames_RT, index, i, GI_Dir, scale );
        frame( GI_Link_L,  GL_Frames_L,  index, i, GI_Dir, scale );
        frame( GI_Link_R,  GL_Frames_R,  index, i, GI_Dir, scale );
        frame( GI_Link_LB, GL_Frames_LB, index, i, GI_Dir, scale );
        frame( GI_Link_RB, GL_Frames_RB, index, i, GI_Dir, scale );
        llSleep( 0.1 );
    }
    return 1;
}

// play sound at target frame
soundEvent( integer ref ) {
    integer index = llListFindList( GL_Sound_KV, [ref] );
    if( index == -1 && index++ < llGetListLength( GL_Sound_KV ) ) {
        return;
    }
    string sound = llList2String( GL_Sound_KV, index );
    if( llGetOwnerKey( (key)sound ) == NULL_KEY ) {
        if( llGetInventoryType( sound ) != INVENTORY_SOUND ) {
            return;
        }
    }
    llTriggerSound( (key)sound, 1 );
}

// prep the frame for application. // if only lsl supported pointers
frame( integer link, list data, integer step, integer frame, integer dir, float scale ) {
    vector p1 = llList2Vector( data, step );
    vector r1 = llList2Vector( data, step+1 );
    vector p2 = llList2Vector( data, step+GI_Frame_Data_Length );
    vector r2 = llList2Vector( data, step+GI_Frame_Data_Length+1 );
    vector pc = ((p2-p1)/10) * frame;
    vector rc = ((r2-r1)/10) * frame;
    if( dir >= 1 ) {
        doStep( link, (p1+pc)*scale, r1+rc );
    } else {
        doStep( link, (p2-pc)*scale, r2-rc );
    }
}

// apply link position and rot
doStep( integer link, vector pos, vector rot ) {
    llSetLinkPrimitiveParamsFast( link, [
            PRIM_POS_LOCAL, pos,
            PRIM_ROT_LOCAL, llEuler2Rot( rot * DEG_TO_RAD )
        ] );
}

// add/replace sounds in frame event list
addSound( integer ref, string sound ) {
    if( llGetOwnerKey( (key)sound ) == NULL_KEY ) {
        if( llGetInventoryType( sound ) != INVENTORY_SOUND ) {
            llOwnerSay( "Err: Sound: '"+ sound +"' Not Found" );
            return;
        }
    }

    integer index = llListFindList( GL_Sound_KV, [ref] );
    if( index == -1 ) {
        GL_Sound_KV += [ ref, sound ];
    } else if( index+1 >= llGetListLength( GL_Sound_KV ) ) {
        GL_Sound_KV += [sound];
    } else {
        GL_Sound_KV = llListReplaceList( GL_Sound_KV, [sound], index+1, index+1 );
    }
}


openPod() {
    llMessageLinked( LINK_THIS, 100, "Opening", "PodState" );
    GI_Dir = 1;
    integer hold = TRUE;
    for( ;hold; ) {
        hold = run();
    }
}

closePod() {
    llMessageLinked( LINK_THIS, 100, "Closing", "PodState" );
    GI_Dir = -1;
    integer hold = TRUE;
    for( ;hold; ) {
        hold = run();
    }
}






/*
*   START OF STATES
*   Because it is easier than regularly adjusting spacing
*/


default {
    state_entry() {
        safeLoad();
        llWhisper( GI_DB_Chan, "'"+ llGetScriptName() +"' Reset" );
        map();
    }

    link_message( integer src, integer num, string msg, key id ) {
        if( num == 120 ) {
            if( id == "OpenPod" ) {
                if( msg == "1" ) {
                    openPod();
                } else {
                    closePod();
                }
            }
        } else if( num == 200 ) {
            if( id == "SOUND" ) {
                list data = llParseString2List( msg, [","], [] );
                addSound(
                        (integer)llStringTrim( llList2String( data, 0 ), STRING_TRIM ), 
                        llStringTrim( llList2String( data, 1 ), STRING_TRIM )
                    );
            }
        }
    }
}
