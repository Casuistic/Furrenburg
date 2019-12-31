/*
*   Bunker Gear Door Terminal 
*
*
*   201912301700
*   201912310711
*/

integer GI_Active = FALSE;

rotation GR_Up = <0.00000, -0.09802, 0.00000, 0.99518>;
rotation GR_Down = <0.00000, 0.64279, 0.00000, 0.76604>;

integer GI_LightDoor = 1;
integer GI_LightPower = 2;


integer GI_Link_Panel = -1; // faces: 1 & 2 = lights // 5 = screen
integer GI_Link_Lever = -1;
integer GI_Link_Buffer = -1;

integer GI_Power = FALSE;
integer GI_Open = FALSE;




integer GI_Chan;

integer GI_Is_Closed = TRUE;
integer GI_Is_Powered = TRUE;

integer GI_Rocker_Up = TRUE;







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





integer isOpen() {
    return !GI_Is_Closed;
}


integer hasPower() {
    /* perform power verification */
    return GI_Is_Powered;
}





map() {
    integer i;
    integer num = llGetNumberOfPrims();
    integer a = -1;
    integer b = -1;
    integer c = -1;
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( name == ".Lever" ) {
            a = i;
        } else if( name == ".Terminal" ) {
            b = i;
        } else if( name == ".ScreenBuffer" ) {
            c = i;
        }
    }
    if( b == -1 ) {
        b = LINK_ROOT;
    }
    GI_Link_Lever = a;
    GI_Link_Panel = b;
    GI_Link_Buffer = c;
}

setup() {
    setLight( GI_Link_Panel, GI_LightDoor, <0,1,0> );
    setLight( GI_Link_Panel, GI_LightPower, <0,1,0> );
    
    setScreen( GI_Link_Buffer, 0, "4c651247-cc9b-0ab5-518c-8201298cbeaf" );
    setScreen( GI_Link_Panel, 5, "19e2c9cc-0cbf-fabf-1153-3a84c958c41d" );
}




rocker( ) {
    if( !GI_Active ) {
        GI_Active = TRUE;
        GI_Rocker_Up = FALSE;
        llTriggerSound( "d1088805-c83d-016b-b721-27d8cf923776", 1 );
        if( GI_Link_Lever != -1 ) {
            llSetLinkPrimitiveParamsFast( GI_Link_Lever, [PRIM_ROT_LOCAL, GR_Down ]);
        }
        setLight( GI_Link_Panel, GI_LightDoor, <0.9,1,0> );
        llSetTimerEvent( 1.5 );
        
    }
}

rockerReset() {
    GI_Rocker_Up = TRUE;
    llTriggerSound( "d8576562-a404-987e-c8c6-1ed0b8071809", 1 );
    if( GI_Link_Lever != -1 ) {
        llSetLinkPrimitiveParamsFast( GI_Link_Lever, [PRIM_ROT_LOCAL, GR_Up]);
    }
    setLight( GI_Link_Panel, GI_LightDoor, <0.5,1,0> );
    parseActive();
}







setLight( integer link, integer face, vector col ) {
    if( link != -1 ) {
        llSetLinkPrimitiveParamsFast( link, [PRIM_COLOR, face, col, 1] );
    }
}

setScreen( integer link, integer face, key id ) {
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, id, <.25,.25,0>, <.125,.125,0>, 0] );
    llSetLinkTextureAnim( link, ANIM_ON | LOOP, face, 4, 4, 0.0, 16.0, 12 );
}

setScreenState( integer screen ) {
    if( screen == 1 ) {
        setScreen( GI_Link_Buffer, 0, "4c651247-cc9b-0ab5-518c-8201298cbeaf" );
        setScreen( GI_Link_Panel, 5, "19e2c9cc-0cbf-fabf-1153-3a84c958c41d" );
    } else if( screen == 2 ) {
        setScreen( GI_Link_Buffer, 0, "19e2c9cc-0cbf-fabf-1153-3a84c958c41d" );
        setScreen( GI_Link_Panel, 5, "4c651247-cc9b-0ab5-518c-8201298cbeaf" );
    } else {
        setScreen( GI_Link_Buffer, 0, "1d9e0646-2c8c-d7f1-c56f-88ec8396b698" );
    }
}




parseActive() {
    if( hasPower() ) {
        if( isOpen() ) {
            llSay( GI_Chan, "Close Bunker" );
        } else {
            llSay( GI_Chan, "Open Bunker" );
            setScreenState( 2 );
        }
    } else {
        llSetLinkPrimitiveParamsFast( GI_Link_Panel, [PRIM_COLOR, 1, <1,0.25,0>, 1] );
    }
}

setReady() {
    setLight( GI_Link_Panel, GI_LightDoor, <0,1,0> );
    GI_Active = FALSE;
    llSetTimerEvent( 0 );
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
    state_entry() {
        map();
        setup();
        GI_Chan = genChan();
        llListen( GI_Chan, "", "", "Ready Open" );
        llListen( GI_Chan, "", "", "Ready Closed" );
    }
    
    touch_start(integer total_number) {
        integer link = llDetectedLinkNumber( 0 );
        if( link == GI_Link_Lever ) {
            rocker();
            return;
        }
    }
    
    timer() {
        if( !GI_Rocker_Up ) {
            rockerReset();
            llSetTimerEvent( 30 );
        } else {
            setReady();
        }
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( filterListen( id ) ) {
            return;
        }
        if( msg == "Ready Closed" ) {
            GI_Is_Closed = TRUE;
            setScreenState( 1 );
            setReady();
        } else if( msg == "Ready Open" ) {
            GI_Is_Closed = FALSE;
            setScreenState( 2 );
            setReady();
        }
    }
}
