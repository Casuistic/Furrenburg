/*
    CAT Script!
*/
integer FACE_1 = 1;
integer FACE_2 = 1;


list GL_Chevrons = [];
integer GI_Link_Locker = 0;




map() {
    integer i;
    integer num = llGetNumberOfPrims();
    list chevs = [0,0,0,0,0,0,0,0,0];
    integer lock = 0;
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( name == ".Chevron" ) {
            integer index = (integer)llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 );
            if( index >= 1 && index <= 9) {
                index -= 1;
                chevs = llListReplaceList( chevs, [i], index, index );
            }
        } else if( name == ".Chevron_lock" ) {
            lock = i;
        }
    }
    GL_Chevrons = chevs;
    GI_Link_Locker = lock;
}


lightAll( integer on, vector col ) {
    list data = getSettings( on, col );
    integer i;
    integer num = llGetListLength( GL_Chevrons );
    for( i=0; i<num; ++i ) {
        llSetLinkPrimitiveParamsFast( llList2Integer( GL_Chevrons, i ), data );
    }
    llSetLinkPrimitiveParamsFast( GI_Link_Locker, data );
}


lightOne( integer on, integer index, vector col ) {
    list data = getSettings( on, col );
    llSetLinkPrimitiveParamsFast( llList2Integer( GL_Chevrons, index ), data );
    if( llAbs( on ) == 7 ) {
        llSetLinkPrimitiveParamsFast( GI_Link_Locker, data );
    }
}


list getSettings( integer on, vector col ) {
    integer fb = FALSE;
    float gl = 0;
    list data = [
                PRIM_COLOR, FACE_1, col, 1.0, 
                PRIM_COLOR, FACE_2, col, 1.0
                ];
    
    if( on >= 0  ) {
        fb = TRUE;
        gl = 0.1;
    }
    data += [
                PRIM_FULLBRIGHT, FACE_1, fb, 
                PRIM_FULLBRIGHT, FACE_2, fb,
                PRIM_GLOW, FACE_1, gl,
                PRIM_GLOW, FACE_2, gl
            ];
    return data;
}




default {
    on_rez( integer peram ) {
        llResetScript();
    }

    state_entry() {
        map();
    }

    link_message(integer src, integer num, string packet, key id) {
        if (packet == "light") {
            integer abs = llAbs( num );
            if( abs == 10 ) {
                vector col = (vector)((string)id);
                lightAll( num, col );
            } else if ( abs > 0 && abs <= llGetListLength( GL_Chevrons ) ) {
                vector col = (vector)((string)id);
                lightOne( num, (abs-1), col );
                
            }
        }
    }
}
