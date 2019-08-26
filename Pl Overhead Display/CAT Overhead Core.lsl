/*
// Cats makes the best programmers!  
// 
// Overhead Dosplay Script
//
// 201908251950
//
//
*/



list GL_Str;
list GL_Bar;


integer GI_HP_Cur = 5; // current health level
integer GI_WL_Cur = 0; // current wanted level

integer GI_HP_Max = 5; // max health level
integer GI_WL_Max = 5; // max wanted level

integer GI_Icon = -1; // role display icon

integer GI_Token_Qst = -1;
integer GI_Token_Hlp = -1;
integer GI_Token_Hit = -1;
integer GI_Token_Mis = -1;


key GK_Alert_Sound = "8ce19ac4-2775-6ff5-2464-086ede57696e";


integer GI_Listen_Base = -100000;
integer GI_Listen_Range = 100000;
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}


prep() {
    string star = ".STAR";
    string heal = ".HEALTH";
    string token = ".TOKEN";
    string icon = ".ROL";

    integer i;
    integer num = llGetNumberOfPrims();
    list str = [];
    list bar = [];
    string name = "";
    for( i=1; i<=num; ++i ) {
        name = llGetLinkName(i);
        if( name == heal ) {
            bar += ["A"+ llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0), i]; 
            llSetLinkAlpha( i, 1, ALL_SIDES );
        } else if( name == star ) {
            str += ["B"+ llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0), i]; 
            llSetLinkAlpha( i, 1, ALL_SIDES );
        } else if( name == icon ) {
            llSetLinkAlpha( i, 1, ALL_SIDES );
            GI_Icon = i;
        } else if( name == token ) {
            string desc = llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0);
            if( desc == "QST" ) {
                llSetLinkAlpha( i, 0, ALL_SIDES );
                GI_Token_Qst = i;
            } else if( desc == "HLP" ) {
                llSetLinkAlpha( i, 0, ALL_SIDES );
                GI_Token_Hlp = i;
            } else if( desc == "HIT" ) {
                llSetLinkAlpha( i, 0, ALL_SIDES );
                GI_Token_Hit = i;
            } else if ( desc == "MIS" ) {
                llSetLinkAlpha( i, 0, ALL_SIDES );
                GI_Token_Mis = i;
            }
        }
    }
    
    str = llListSort( str, 2, TRUE );
    bar = llListSort( bar, 2, TRUE );
    
    GL_Str = llList2ListStrided( llList2List( str, 1,-1 ), 0,-1,2 );
    GL_Bar = llList2ListStrided( llList2List( bar, 1,-1 ), 0,-1,2 );
}


setLev( list tokens, integer lev ) {
    integer i;
    integer num = llGetListLength( tokens );
    for( i=0; i<num; ++i ) {
        if( lev > i ) {
            llSetLinkAlpha( llList2Integer(tokens,i), 1, ALL_SIDES );
        } else {
            llSetLinkAlpha( llList2Integer(tokens,i), 0, ALL_SIDES );
        }
    }
}


//string GS_Name_Of_Hud = "HUD_Comm";
integer GI_OChan_A = -55; // open channel for hud to overhead communication




doHUDCommand( string cmd ) {
    //llOwnerSay( "Command Check: "+ cmd );
    string tag = llGetSubString( cmd, 0, 2 );
    if( tag == "INC" ) {
        parseIncrament( cmd );
    } else if( tag == "SAI" ) {
        parseIcons( cmd );
    } else if( tag == "ROL" ) {
        parseRole( cmd );
    }
}

parseIncrament( string cmd ) {
    list data = llParseString2List( cmd, [" "], [] );
    if( llGetListLength( data ) != 3 ) {
        return;
    }
    integer val = (integer)llList2String( data, 2 );
    if( llList2String( data, 1 ) == "WL" ) {
        GI_WL_Cur += val;
        if( GI_WL_Cur < 0 ) {
            GI_WL_Cur = 0;
        } else if( GI_WL_Cur > GI_WL_Max ) {
            GI_WL_Cur = GI_WL_Max;
        }
        setLev( GL_Str, GI_WL_Cur );
    } else if( llList2String( data, 1 ) == "HP" ) {
        GI_HP_Cur += val;
        if( GI_HP_Cur < 0 ) {
            GI_HP_Cur = 0;
        } else if( GI_HP_Cur > GI_HP_Max ) {
            GI_HP_Cur = GI_HP_Max;
        }
        setLev( GL_Bar, GI_HP_Cur );
    }
}

parseIcons( string cmd ) {
    list data = llParseString2List( cmd, [" "], [] );
    if( llGetListLength( data ) != 2 ) {
        return;
    }
    string token = llList2String( data, 1 );
    if( token == "QST" ) {
        token( [GI_Token_Qst, GI_Token_Hlp, GI_Token_Hit, GI_Token_Mis] );
    } else if( token == "HLP" ) {
        if( GI_Token_Hlp != last && GK_Alert_Sound != NULL_KEY ) {
            llTriggerSound( GK_Alert_Sound, 1 );
        }
        token( [GI_Token_Hlp, GI_Token_Qst, GI_Token_Hit, GI_Token_Mis] );
    } else if( token == "HIT" ) {
        token( [GI_Token_Hit, GI_Token_Hlp, GI_Token_Qst, GI_Token_Mis] );
    } else if( token == "MIS" ) {
        token( [GI_Token_Mis, GI_Token_Hlp, GI_Token_Qst, GI_Token_Hit] );
    } else {
        token( [-1, GI_Token_Mis, GI_Token_Hlp, GI_Token_Qst, GI_Token_Hit] );
    }
}

parseRole( string cmd ) {
    list data = llParseString2List( cmd, [" "], [] );
    if( llGetListLength( data ) != 2 ) {
        return;
    }
    if( llList2String( data, 0 ) == "ROL" ) {
        if( GI_Icon != -1 ) {
            llSetLinkPrimitiveParamsFast( GI_Icon, [PRIM_TEXTURE,ALL_SIDES, (key)llList2String( data, 1 ), <1,1,0>, <0,0,0>, 0 ] );
        }
    }
}

integer last = -1;
token( list items ) {
    integer i;
    integer num = llGetListLength( items );
    integer t = llList2Integer( items, 0 );
    if( t!= -1 ) {
        if( last != t ) {
            last = t;
            llSetLinkAlpha( t, 1, ALL_SIDES );
        } else {
            last = -1;
            llSetLinkAlpha( t, 0, ALL_SIDES );
        }
    }
    for( i=1; i<num; ++i ) {
        t = llList2Integer( items, i );
        if( t!= -1 ) {
            llSetLinkAlpha( t, 0, ALL_SIDES );
        }
    }
}


integer GI_Listen;
default {
    attach( key id ) {
        if( id != NULL_KEY ) {
            llResetScript();
        }
    }
    
    state_entry() {
        GI_OChan_A = key2Chan( llGetOwner(), GI_Listen_Base, GI_Listen_Range );
        llListen( GI_OChan_A, "", "", "" );
        
        prep();

        setLev( GL_Str, GI_WL_Cur );
        setLev( GL_Bar, GI_HP_Cur );
    }
    
    touch( integer num ) {
        llListenRemove( GI_Listen );
        GI_Listen = llListen( 2, "", llGetOwner(), "" );
        llSetTimerEvent( 30 );
        //llOwnerSay( "Listen Open" );
        llDialog( llGetOwner(), "Option", ["Stars", "Health"], 2 );
    }
    
    timer() {
        llSetTimerEvent(0);
        llListenRemove( GI_Listen );
        llOwnerSay( "Listen Closed" );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey( id ) != llGetOwner() ) {
            return; // reject non owner / hud commands
        }
        if( chan == GI_OChan_A ) {
            llOwnerSay( msg );
            doHUDCommand( msg );
            return;
        }
    }
}
