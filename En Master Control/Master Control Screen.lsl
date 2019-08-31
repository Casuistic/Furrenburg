/*
// Cats makes the best programmers!  
// 
// Manage The Screens and the preload prims of the Master Control Console
//
// 201908311750
*/



list GL_Screens = [ 
    "e4a3d33e-897d-84de-ddc8-e149186ce508", // comm
    "1377ee26-6938-c41a-99c4-74bbd2544917", // stattic
    "1d9e0646-2c8c-d7f1-c56f-88ec8396b698", // STATIC ERROR
    "7dbac366-32b0-86c0-788c-5110b16d0378", // blue screen
    
    "b9c93400-4423-1933-1122-aa2d5b610705", 
    "19e0d945-167b-aa39-fac4-c5385a34017d",
    "7ce40d17-6deb-4db0-51ca-ae59c42712f3",
    "df56e018-1ca3-78c0-d45e-cc396b84ea3d",
    "c2d95ce0-f774-73bf-e9c3-56f637e05f34",

    "0e0f82e5-8e73-0f6b-0435-7173a96aadb6",
    "9151ece5-aae3-5873-77ad-f9083daabb3d",
    "a623d448-46b8-7427-62f0-f784243b85c1",
    "4a94cd9e-afeb-376e-ebc8-458c780e48e5",
    "d24d3aa6-79ee-725c-c6f3-4bf8db7efe19",
    
    "9e4a5fb3-82a9-f781-6a19-91df7be0413b",
    "f1399eaa-ecb1-7e3c-1604-225f91d9bf09",
    "409bd994-23a0-7ab5-6220-6c6a91431bdd",
    "698486f8-cb7b-6282-3b0f-bd8dfe5dfb6e",
    "019a0787-b482-8f67-c565-d4608deb5606"
];

// sound
key GK_Sound_B_Screen = "a49f6d8b-ef39-415e-6b18-ee827972079d";
key GK_Sound_Error = "f123cda7-f8ed-38b2-9c45-ad9a8507c0b4";


integer GI_Screen = -1;
integer GI_Preload = -1;
integer GI_Base = 1;


map() {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( name == ".Screen" ) {
            GI_Screen = i;
            startScreen( GI_Screen, 0, 8 );
        } else if( name == ".Preload" ) {
            GI_Preload = i;
        }
    }
}


set( integer front, integer back ) {
    llSetLinkPrimitiveParamsFast( GI_Screen, [
                PRIM_TEXTURE, 
                0, 
                llList2Key( GL_Screens, front ), 
                <.25,.25,0>, 
                <.125,.125,0>, 
                0
            ] );
    if( front <= 8 && front >=4  ) { // blue
        setBeacons( <0.5,0.5,1>, 75 );
    } else if( front <= 13 && front >=9  ) { // red
        setBeacons( <1,0.5,0>, 75 );
    } else if( front <= 18 && front >=14  ) { // grey
        setBeacons( <0.75,1,0.75>, 75 );
    } 
    
    else if( front == 0 ) {
        setBeacons( <0,1,0>, 25 );
    } else if( front == 1 ) {
        setBeacons( <1,1,0>, 100 );
    }  else if( front == 2 ) {
        setBeacons( <1,0,0>, 120 );
        llTriggerSound( GK_Sound_Error, 1 );
    } else if( front == 3 ) {
        setBeacons( <0,0,0>, 1 );
        llTriggerSound( GK_Sound_B_Screen, 1 );
    }
    llSetLinkPrimitiveParamsFast( GI_Base, [PRIM_TEXTURE, 2, llList2Key( GL_Screens, back ), <.25,.25,0>, <.125,.125,0>, 0] );
}

// set the preload prim
set2( list data ) {
    integer i;
    integer num = llGetListLength( data );
    if( num > 4 ) {
        num = 4;
    }
    for( i=0; i<num; ++i ) {
        llSetLinkPrimitiveParamsFast( GI_Preload, [PRIM_TEXTURE, i, llList2Key( GL_Screens, llList2Integer( data, i ) ), <.25,.25,0>, <.125,.125,0>, 0] );
    }
}

// set the side light animation
setBeacons( vector col, float speed ) {
    integer side = 1;
    llSetLinkPrimitiveParamsFast( GI_Base, [PRIM_COLOR, side, col, 1] );
    llSetLinkTextureAnim( GI_Base, ANIM_ON | LOOP, side,  120,1,0,0, speed );
}

// kick off the screen and side lights
startAnim() {
    set( 0, 3 );
}


startScreen( integer screen, integer side, float speed ) {
    llSetLinkTextureAnim( screen, ANIM_ON | LOOP, side,  4,4,0,0,   speed );
}




default {
    state_entry() {
        map();
        startAnim();
        set( 0, 0 );
    }

    link_message( integer src, integer num, string msg, key id ) {
        if( id == "SET_SCREEN" ) {
            llOwnerSay( "msg: "+ msg );
            list data = llParseString2List( msg, [","], [] );
            list data_2;
            integer i;
            integer num = llGetListLength( data );
            for( i=1; i<num; ++i ) {
                data_2 += (integer)llList2String( data, i );
            }
            set( (integer)llList2String( data, 0 ), 0 );
            set2( data_2 );
        } else {
            llOwnerSay( msg );
        }
    }
}