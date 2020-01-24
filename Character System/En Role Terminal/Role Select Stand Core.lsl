/*
// Cats makes the best programmers!  
// 
// FB Role Selection Terminal
//
// 201908302001
// 202001200654
//
*/


list GL_Last = [-1,-1];
list GL_Next = [-1,-1];
list GL_Cur = [-1,-1];

integer GI_Last = -1;
integer GI_Pick = -1;
integer GI_Next = -1;

key GK_Icons = "9244c439-53c7-ed90-79b7-dcd4c4638a63";//"eb0791f5-e72c-92d7-162f-7444e23b8903";
key GK_Descs = "e2221ef1-9a3d-51b9-6a06-5449423a71b1";



list GL_Class_Icons = [
    "85cd93de-8a05-7a05-b89f-33ecbab7b019", // BLANK
    "f33de671-3a01-60c3-a8e4-40859e34ade7", // Boss
    "5952fc99-b976-0a90-2d65-e1c98646428c", // cop boss

    "3ee99ed2-db9c-8daa-5256-52768609dbad", // Mech
    "fa48efea-b1d8-c8dd-e383-8eb39e3bee08", // civ
    "c1a17f83-8971-0236-3358-283613cc70e4", // Sci
    "bfaab990-6dfc-da78-e505-89fcd9697cdb", // Med
    "f3831407-318d-1f21-1fdb-adc7754cf681", // fire dep
    "59df7b7c-44c4-de92-c8a7-d784a27af069",//"3c5cd5a7-da41-b842-099c-5fdfe908dfad", // cop

    "ddea300f-50ec-b948-46d1-20071bf303a6", // p dic
    "00af41d4-1fc6-90b0-266f-e4c7b32fce2b" // cop dic
];



integer GI_Listen_Base = -200000;
integer GI_Listen_Range = 100000;
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}




// map the link set
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    integer last_a = -1;
    integer last_b = -1;
    integer next_a = -1;
    integer next_b = -1;
    integer cur_a = -1;
    integer cur_b = -1;
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName(i);
        if( name == ".D" ) {
            string data = llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC]), 0 );
            if( data == "L1" ) {
                last_a = i;
            } else if( data == "L2" ) {
                last_b = i;
            } else if( data == "N1" ) {
                next_a = i;
            } else if( data == "N2" ) {
                next_b = i;
            } else if( data == "C1" ) {
                cur_a = i;
            } else if( data == "C2" ) {
                cur_b = i;
            }
        } else if( name == ".B" ) {
            string data = llList2String( llGetLinkPrimitiveParams( i, [PRIM_DESC]), 0 );
            if( data == "LAST" ) {
                GI_Last = i;
            } else if( data == "SELECT" ) {
                GI_Pick = i;
            } else if( data == "NEXT" ) {
                GI_Next = i;
            }
        }
    }
    GL_Last = [last_a,last_b];
    GL_Next = [next_a,next_b];
    GL_Cur = [cur_a,cur_b];
}


setStatDisp( integer link, integer face, integer lev, key texture ) {
    float off = 0.333;
    integer x = lev % 3;
    integer y = ((lev-x)/3);
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, texture, <off,off,0>,  <-off+(off*x), -off+(off*y), 0>, 0] );
}

// correct index for under or overflow and apply offset for unselectable roles
integer fixIndex( integer index ) {
    while( index < 0 ) {
        index = 6 + index;
    }
    while( index >= 6 ) {
        index = index - 6;
    }
    index += 3;
    return index;
}

// set display textures for current index
integer GI_Point = 0;
setPicker( integer index ) {
    GI_Point = index;
    
    integer pick = fixIndex( index );
    integer last = fixIndex( index-1 );
    integer next = fixIndex( index+1 );
    
    setStatDisp( llList2Integer( GL_Last, 0 ), ALL_SIDES, last, GK_Icons );
    setStatDisp( llList2Integer( GL_Last, 1 ), ALL_SIDES, last, GK_Descs );

    setStatDisp( llList2Integer( GL_Cur, 0 ), ALL_SIDES, pick, GK_Icons );
    setStatDisp( llList2Integer( GL_Cur, 1 ), ALL_SIDES, pick, GK_Descs );

    setStatDisp( llList2Integer( GL_Next, 0 ), ALL_SIDES, next, GK_Icons );
    setStatDisp( llList2Integer( GL_Next, 1 ), ALL_SIDES, next, GK_Descs );
}


// apply selection and broadcast to triggering agents to update their hud
select( integer index, key id ) {
    integer pick = fixIndex( index );
    string role = llList2String(GL_Class_Icons, pick );
    integer chan = key2Chan( id, GI_Listen_Base, GI_Listen_Range );
    llRegionSayTo( id, chan, "OpenChan" );
    llSleep( 0.5 );
    llRegionSayTo( id, chan, "SetRole:"+ role );
}



default {
    state_entry() {
        map();
        llOwnerSay( llDumpList2String( GL_Last, "," ) );
        llOwnerSay( llDumpList2String( GL_Next, "," ) );
        llOwnerSay( llDumpList2String( GL_Cur, "," ) );
        setPicker( GI_Point );
    }

    touch_start( integer num ) {
        integer link = llDetectedLinkNumber( 0 );
        if( link == GI_Last ) {
            setPicker( GI_Point-1 );
        } else if( link == GI_Next ) {
            setPicker( GI_Point+1 );
        } else if( link == GI_Pick ) {
            select( GI_Point, llDetectedKey( 0 ) );
        }
    }
}

