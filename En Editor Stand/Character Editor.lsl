/*
// Cats makes the best programmers!  
// 
// Core Script of the Character Editor Stand
//
// 201908251950
//
//
*/

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

integer GI_Listen_A = -1;
//integer GI_Listen_B = -1;


/*  channel generation variables  */
integer GI_OChan_A = -22; // open channel for hud to overhead communication
integer GI_Listen_Base = -100000; // set the minimum value
integer GI_Listen_Range = 100000; // set the range of values


integer GI_OChan_B = -22; // open channel for hud to overhead communication



setup() {
    map();
    clear();
}

// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

/*  Use Target Prim To Display Value  */
setStatDisp( integer link, integer face, integer lev ) {
    integer x = lev % 3;
    integer y = ((lev-x)/3);
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, GK_Disp_Texture, <.333,.333,0>,  <-.333+(0.333*x), -.333+(0.333*y), 0>, 0] );
}

/*  MAP THE LINKS TO FIND THE DISPLAY PRIMS  */
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    list tot;
    list sta;
    for( i=1; i<=num; ++i ) {
        string name = llGetLinkName( i );
        if( name == ".D SD" ) {
            setStatDisp( i, ALL_SIDES, 0 );
            string desc = llList2String(llGetLinkPrimitiveParams( i, [PRIM_DESC] ), 0 );
            if( llGetSubString( desc, 0, 2 ) == "TOT" ) {
                llSetLinkColor(i,<1,1,1>,ALL_SIDES);
                tot += [desc, i];
            } else {
                llSetLinkColor(i,<1,1,1>,ALL_SIDES);
                sta += [desc, i];
            }
        }
    }
    
    GI_Disp_Total = llList2ListStrided( llList2List( llListSort( tot, 2, FALSE ), 1, -1 ), 0, -1, 2 );
    GI_Disp_Stats = llList2ListStrided( llList2List( llListSort( sta, 2, FALSE ), 1, -1 ), 0, -1, 2 );
}

/*  UPDATE DISPLAY PRIMS  */
update() {
    integer sum = 0;
    integer i;
    integer num = llGetListLength(GL_Stats);
    list set_max = [];
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
        llWhisper( 0, "Only One Stat may be at Maximum value: "+ addSign(GI_Max_Stat) );
        for(i=0;i<llGetListLength(set_max);++i) {
            llSetLinkColor(llList2Integer(set_max,i),<1,1,0>,ALL_SIDES);
        }
    }

    integer abs = llAbs( GI_Points-sum );
    integer over = (abs/10);
    
    setStatDisp( llList2Integer(GI_Disp_Total,0), ALL_SIDES, over );
    setStatDisp( llList2Integer(GI_Disp_Total,1), ALL_SIDES, (abs-(over*10)) );
    
    vector col = getCol( sum );
    for(i=0;i<2;++i) {
        send();
        llSetLinkColor(llList2Integer(GI_Disp_Total,i),col,ALL_SIDES);
    }
}

clear() {
    llListenRemove( GI_Listen_A );
    //llListenRemove( GI_Listen_B );
    GL_Stats = [0,0,0,0,0];
    GI_OChan_A = -22;
    
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
    if( val > 0 ) {
        return "+"+ (string)val;
    } else if( val < 0 ) {
        return "-"+ (string)val;
    }
    return (string)val;
}


openChannel( key id ) {
    llListenRemove( GI_Listen_A );
    //llListenRemove( GI_Listen_B );
    
    GI_OChan_A = key2Chan( id, GI_Listen_Base, GI_Listen_Range );
    GI_OChan_B = key2Chan( id, GI_Listen_Base, GI_Listen_Range );
    
    GI_Listen_A = llListen( GI_OChan_A, "", "", "" );
    //GI_Listen_B = llListen( GI_OChan_B, "", "", "" );
    
    llSay( GI_OChan_B, "PING" );
    llWhisper( 0, "Channel Open" );
}

//dialog( key id, string text, list buttons ) {
    //GI_OChan_A
//}

text( key id, string text ) {
    llTextBox( id, text, GI_OChan_A );
}

send( ) {
    key id = llAvatarOnSitTarget();
    if( id != NULL_KEY ) {
        llRegionSayTo( id, GI_OChan_B, "SetStats:"+ llDumpList2String(GL_Stats,",") );
    }
}






/*
setup() {
    map();
    GI_OChan_A = key2Chan( llGetOwner(), GI_Listen_Base, GI_Listen_Range );
    GI_Chan_B = key2Chan( llGetOwner(), GI_Listen_B_Base, GI_Listen_B_Range );
    llListenRemove( GI_Listen_B );
    GI_Listen_B = llListen( GI_Chan_B, "", "", "OpenChan" );
    updateStats(); // update the stats
}


openChan() {
    llListenRemove( GI_Listen_B2 );
    GI_Listen_B2 = llListen( GI_Chan_B, "", "", "" );
    llSetTimerEvent( 120 );
}


closeChan() {
    llListenRemove( GI_Listen_B2 );
}
*/

default {
    state_entry() {
        setup();
    }

    changed(integer flag) {
        if( flag & CHANGED_LINK ) {
            key id = llAvatarOnSitTarget();
            if( id != NULL_KEY ) {
                openChannel( id );
                text( id, "Set Stats in format:\nStr,Cha,Dex,Int,Con\nexample: 2,4,8,3,3" );
            } else {
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
        if( chan == GI_Listen_A ) {
        
        }
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
