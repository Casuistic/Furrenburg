/*
// Cats makes the best programmers!  
// 
// Core Script of the Character Editor Stand
//
// 201908251950
// 201908262051
// 201908270132
//
*/

integer DEBUG = FALSE;

debug( string msg ) {
    if( DEBUG ) {
        llOwnerSay( msg );
    } else {
        llShout( -9999, msg );
    }
}


// str,int,dex,con,cha
list GL_Stats = [0,0,0,0,0];

// order entered: str,cha,dex,int,con

key GK_Disp_Texture = "f206308a-2095-253d-2124-55ea6f25c66f";

list GI_Disp_Total = [-1];
list GI_Disp_Stats = [-1];

integer GI_Data_Store = -1;


integer GI_Max_Stat = 8;
integer GI_Min_Stat = 0;
integer GI_Points = 20;


integer GI_Listen_B = -1; // stand -> hud
integer GI_Listen_D = -1; // agent -> stand


/*  channel generation variables  */
integer GI_Chan_D = -22; // ACTIVE AGENT (NON OWNER) -> TO STAND
integer GI_Listen_D_Base = -600000; // set the minimum value
integer GI_Listen_D_Range = 100000; // set the range of values

integer GI_Chan_B = -22; // HUD <-> STAND (NON-OWNER)
integer GI_Listen_B_Base = -200000; // set the minimum value
integer GI_Listen_B_Range = 100000; // set the range of values

key GK_Sound_Start = "acafd9dc-d1f1-1074-f5a3-115031e3beb7";
key GK_Sound_Set   = "eda25134-0196-4d49-d906-31cb86a5353b";
key GK_Sound_Done  = "d019dc09-0e81-f744-2976-d87de0d254b6";
key GK_Sound_Error = "f123cda7-f8ed-38b2-9c45-ad9a8507c0b4";

key GK_Agent = NULL_KEY;


setup() {
    debug( "SETUP" );
    map();
    clear();
}

// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    debug( "Key2Chan" );
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

/*  Use Target Prim To Display Value  */
setStatDisp( integer link, integer face, integer lev ) {
    debug( "Set Display" );
    integer x = lev % 3;
    integer y = ((lev-x)/3);
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, GK_Disp_Texture, <.333,.333,0>,  <-.333+(0.333*x), -.333+(0.333*y), 0>, 0] );
}

/*  MAP THE LINKS TO FIND THE DISPLAY PRIMS  */
map() {
    debug( "MAP" );
    integer i;
    integer num = llGetNumberOfPrims();
    list tot;
    list sta;
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( name == ".D SD" ) {
            string desc = llList2String(llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 );
            if( llGetSubString( desc, 0, 2 ) == "TOT" ) {
                tot += [desc, i];
            } else {
                sta += [desc, i];
            }
        }
    }
    
    GI_Disp_Total = llList2ListStrided( llList2List( llListSort( tot, 2, FALSE ), 1, -1 ), 0, -1, 2 );
    GI_Disp_Stats = llList2ListStrided( llList2List( llListSort( sta, 2, FALSE ), 1, -1 ), 0, -1, 2 );
}

/*  UPDATE DISPLAY PRIMS  */
update() {
    debug( "Update" );
    integer sum = 0;
    integer i;
    integer num = llGetListLength(GL_Stats);
    list set_max = [];
    integer valid = TRUE;
    for(i=0;i<num;++i) {
        integer stat = llList2Integer( GL_Stats, i );
        sum += stat;
        if(stat == GI_Max_Stat) {
            set_max += [llList2Integer(GI_Disp_Stats,i)];
        }
        llSetLinkColor(llList2Integer(GI_Disp_Stats,i),<1,1,1>,ALL_SIDES);
        setStatDisp( llList2Integer(GI_Disp_Stats,i), ALL_SIDES, llList2Integer(GL_Stats,i) );
    }
    
    if( llGetListLength(set_max) > 1 ) {
        valid = FALSE;
        llWhisper( 0, "Only One Stat may be at Maximum value: "+ addSign(GI_Max_Stat) );
        for(i=0;i<llGetListLength(set_max);++i) {
            llSetLinkColor(llList2Integer(set_max,i),<1,1,0>,ALL_SIDES);
        }
    }

    integer abs = llAbs( GI_Points-sum );
    integer over = (abs/10);
    vector col = <1,1,1>;
    if( sum != GI_Points ) {
        valid = FALSE;
        col = getCol( sum );
    }
    
    setStatDisp( llList2Integer(GI_Disp_Total,0), ALL_SIDES, over );
    setStatDisp( llList2Integer(GI_Disp_Total,1), ALL_SIDES, (abs-(over*10)) );
    for(i=0;i<2;++i) {
        llSetLinkColor(llList2Integer(GI_Disp_Total,i),col,ALL_SIDES);
    }
    
    
    if( !valid ) {
        llTriggerSound( GK_Sound_Error, 1 );
    } else {
        llTriggerSound( GK_Sound_Set, 1 );
        send();
    }
}

clear() {
    debug( "Clear" );
    llListenRemove( GI_Listen_B );
    GL_Stats = [0,0,0,0,0];
    GI_Chan_B = -22;
    GI_Chan_D = -22;
    
    integer i;
    integer num = llGetListLength(GI_Disp_Total);
    for( i=0;i<num;++i ) {
        llSetLinkColor(llList2Integer(GI_Disp_Total,i),<1,1,1>,ALL_SIDES);
        setStatDisp( llList2Integer(GI_Disp_Total,i), ALL_SIDES, 0 );
    }
    
    num = llGetListLength(GI_Disp_Stats);
    for(i=0;i<num;++i) {
        llSetLinkColor(llList2Integer(GI_Disp_Stats,i),<1,1,1>,ALL_SIDES);
        setStatDisp( llList2Integer(GI_Disp_Stats,i), ALL_SIDES, 0 );
    }
    
    
}

/*  Get Point Based Color  */
vector getCol( integer sum ) {
    debug( "Get Colour" );
    if( sum > GI_Points ) {
        llWhisper( 0, "Not Enough Points");
        return <255,0,0>;
    } else if( sum < GI_Points ) {
        llWhisper( 0, "Points Still Available: "+ addSign(GI_Points-sum));
        return <255,255,0>;
    }
    return <255,255,255>;
}


string addSign( integer val ) {
    debug( "ADD SIGN" );
    if( val > 0 ) {
        return "+"+ (string)val;
    } else if( val < 0 ) {
        return "-"+ (string)val;
    }
    return (string)val;
}


openChannel( key id ) {
    debug( "Open Chan" );
    GI_Chan_B = key2Chan( id, GI_Listen_B_Base, GI_Listen_B_Range );
    GI_Chan_D = key2Chan( id, GI_Listen_D_Base, GI_Listen_D_Range );
    llListenRemove( GI_Listen_D );
    GI_Listen_D = llListen( GI_Chan_D, "", id, "" );
    llRegionSayTo( id, GI_Chan_B, "OpenChan" );
    //llWhisper( GI_Chan_B, "OpenChan" );
}

closeChannel( key id ) {
    llListenRemove( GI_Listen_D );
    llRegionSayTo( id, GI_Chan_B, "OpenChan" );
    //llWhisper( GI_Chan_B, "CloseChan" );
}

text( key id, string text ) {
    debug( "Open Dialog" );
    llTextBox( id, text, GI_Chan_D );
}

send( ) {
    debug( "Send" );
    key id = llAvatarOnSitTarget();
    if( id != NULL_KEY ) {
        list data = [];//"";
        list tokens =[ "str","int","dex","con","cha" ];
        integer i;
        for( i=0; i<5; ++i ) {
            data += llList2String(tokens,i) +";"+ llList2String(GL_Stats,i);
        }
        llRegionSayTo( id, GI_Chan_B, "SetStats:"+ llDumpList2String(data,",") );
        //llWhisper( GI_Chan_B, "SetStats:"+ llDumpList2String(data,",") );
    } else {
        llWhisper( 0, "Agent Lost?" );
    }
}





default {
    state_entry() {
        setup();
    }

    changed(integer flag) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                //llOwnerSay( "New Agent" );
                llTriggerSound( GK_Sound_Start, 1 );
                GK_Agent = id;
                openChannel( id );
                text( id, "Set Stats in format:\nStr,Cha,Dex,Int,Con\nexample: 2,4,8,3,3" );
            } else if( GK_Agent != NULL_KEY ){
                //llOwnerSay( "Agent Left" );
                llTriggerSound( GK_Sound_Done, 1 );
                closeChannel( GK_Agent );
                GK_Agent = NULL_KEY;
                clear();
            }
        }
    }

    touch( integer num ) {
        key id = llDetectedKey( 0 );
        if( id == llAvatarOnSitTarget() ) {
            text( id, "Set Stats in format:\nStr,Cha,Dex,Int,Con\nexample: 2,4,8,3,3" );
        }
    }

    listen( integer chan, string name, key id, string msg ) {
        // ON GI_Chan_D AGENT->STAND
        list data = llParseString2List( msg, [" ", ",", "/n"], [] );
        if( llGetListLength( data ) >= 5 ) {
            integer i;
            GL_Stats = [];
            // Needed: str,int,dex,con,cha
            // Entered: str,cha,dex,int,con
            list off = [0,3,2,4,1]; // correct for order stored and set
            for(i=0;i<5;++i) {
                integer val = llList2Integer( data, llList2Integer( off, i ));
                if( val > GI_Max_Stat ) {
                    val = GI_Max_Stat;
                    llWhisper( 0, "Max Stat Level: "+ addSign(GI_Max_Stat) );
                } else if( val < GI_Min_Stat ) {
                    val = GI_Min_Stat;
                    llWhisper( 0, "Min Stat Level: "+ addSign(GI_Min_Stat) );
                }
                GL_Stats += val;
            }
        }
        update();
    }
}
