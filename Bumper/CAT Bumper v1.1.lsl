integer GI_Ready = FALSE; // used by scrip. Dont change

string GS_Sound;     // set by script. don't bother changing
string GS_Animation; // set by script. don't bother changing

float GF_Len = 1.5; // duration for animation & sound to play

integer GI_Speed_Check = TRUE; // bumper has to be moving faster than owner to trigger
// if false no speed check is performed




// setup for action
setup() {
    integer noi = llGetInventoryNumber( INVENTORY_SOUND );
    if( noi != 0 ) {
        GS_Sound = llGetInventoryName( INVENTORY_SOUND, 0 );
    } else {
        llOwnerSay( "Sound Not Found" );
        GS_Sound = "b1d2f8f4-b4ce-ad8a-3af5-418602cc6273";
    }
    noi = llGetInventoryNumber( INVENTORY_ANIMATION );
    if( noi != 0 ) {
        GS_Animation = llGetInventoryName( INVENTORY_ANIMATION, 0 );
    } else {
        llOwnerSay( "Animation Not Found" );
        GS_Animation = "";
    }
    GI_Ready = TRUE;
    llSetTimerEvent(0);
}

// called when a valid impact is detected
impact() {
    llStartAnimation( GS_Animation );
    llPlaySound( GS_Sound, 1 );
}

// called after GF_Len seconds of a valid bump to reset for next bump
stop() {
    llStopAnimation( GS_Animation );
    llStopSound( );
}





default {
    state_entry() {
        setup();
        llRequestPermissions( llGetOwner(), PERMISSION_TRIGGER_ANIMATION );
    }
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            setup();
            llRequestPermissions( id, PERMISSION_TRIGGER_ANIMATION );
        }
    }

    collision_start( integer num ) {
        if( GI_Ready && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION ) {
            integer i;
            for( i=0; i<num; ++i ) {
                if( llDetectedType( i ) & AGENT && (!GI_Speed_Check || llVecMag(llDetectedVel( i )) >= llVecMag(llGetVel())) ) {
                    GI_Ready = FALSE;
                    impact();
                    llSetTimerEvent( GF_Len );
                    return;
                }
            }
        }
    }
    
    timer() {
        llSetTimerEvent(0);
        stop();
        GI_Ready = TRUE;
    }
}
