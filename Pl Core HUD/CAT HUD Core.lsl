/*
// Cats makes the best programmers!  
// 
// FB RP HUD Core Script
//
// 201908251950
// 201908262051
//
*/



integer gListener; // Identity of the listener associated with the dialog, so we can clean up when not needed

list GL_Stat_Mods = [
    2, // str
    8, // cha
    4, // dex
    6, // int
    0 // con
];

// store prims that display data
list GL_Stat_Disp; // script sets this

// 0-8 tiled texture;
key id = "6a69e885-99a1-9f04-ee42-c2f160fb452c";


integer GI_Conc_Chan = -55; // channel on which to chat to the balls

integer GI_Chan_A = -22; // open channel for hud to overhead communication
integer GI_Listen_A_Base = -100000; // set the minimum value
integer GI_Listen_A_Range = 100000; // set the range of values

integer GI_Listen_B = -1; // filtered
integer GI_Listen_B2 = -1; // unfiltered

integer GI_Chan_B = -11; // open channel for hud to Stand Comm
integer GI_Listen_B_Base = -200000; // set the minimum value
integer GI_Listen_B_Range = 100000; // set the range of values




// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

// set a display prims texture offset
setStatDisp( integer link, integer face, integer lev ) {
    integer x = lev % 3;
    integer y = ((lev-x)/3);
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, id, <.333,.333,0>,  <-.333+(0.333*x), -.333+(0.333*y), 0>, 0] );
}


setup() {
    map();
    GI_Chan_A = key2Chan( llGetOwner(), GI_Listen_A_Base, GI_Listen_A_Range );
    GI_Chan_B = key2Chan( llGetOwner(), GI_Listen_B_Base, GI_Listen_B_Range );
    llListenRemove( GI_Listen_B );
    GI_Listen_B = llListen( GI_Chan_B, "", "", "OpenChan" );
    updateStats(); // update the stats
}


openChan( key id ) {
    llListenRemove( GI_Listen_B2 );
    GI_Listen_B2 = llListen( GI_Chan_B, "", id, "" );
    llSetTimerEvent( 60 );
}


closeChan() {
    llListenRemove( GI_Listen_B2 );
}


integer parseSafeCmd( integer chan, string name, key id, string msg ) {
    //string cmd = llToUpper( msg );
    /*
    if( cmd == "OPENCHAN" ) {
        openChan( id );
    } else {
        if( cmd == "CLOSECHAN" ) {
            closeChan();
        }
        llOwnerSay( "Safe Cmd: "+ cmd );
    }
    */
    //llOwnerSay( "Safe Cmd: "+ cmd );
    return FALSE;
}


integer parseAltCmd( integer chan, string name, key id, string msg ) {
    string cmd = llToUpper( msg );
    if( cmd == "OPENCHAN" ) {
        openChan( id );
        return TRUE;
    } else if( cmd == "CLOSECHAN" ) {
            closeChan();
            return TRUE;
    } else {
        list data = llParseString2List( cmd, [":"], [] );
        if( llList2String( data, 0 ) == "SETSTATS" && llGetListLength(data) == 2 ) {
            if( setStats( llParseString2List( llList2String( data, 1 ), [","], [] ) ) ) {
                llSetTimerEvent( 60 );
                return TRUE;
            }
        }
    }
    llOwnerSay( "Unknown Alt Cmd: "+ cmd );
    return FALSE;
}

integer setStats( list tokens ) {
    // example: "str;2,int;6,dex;4,con;0,cha;8";
    if( llGetListLength( tokens ) == 5 ) {
        tokens = llListSort( tokens, 1, FALSE );
        llOwnerSay( llDumpList2String( tokens, " : " ) );
        list stats;
        integer i;
        list off = [0,4,2,1,3];
        // needed: str cha dex int con
        // got   : Str int dex con cha
        for(i=0;i<5;++i) {
            //string token = llList2String(tokens, i );
            string token = llList2String(tokens,llList2Integer( off, i ));
            integer index = llSubStringIndex( token, ";" );
            if( index != -1 ) {
                token = llGetSubString( token, index+1, -1 );
            }
            stats += (integer)token;
        }
        GL_Stat_Mods = stats;
        updateStats();
        return TRUE;
    }
    return FALSE;
}

// map prims and find display prims
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    list data =[];
    for( i=1;i<=num;++i ) {
        if( llToUpper(llGetLinkName(i)) == ".D_STAT" ) { // find all the stat display prims
            data += i; // log stat display prims
            setStatDisp( i, 1, 0 ); // set zro value
        }
    }
    GL_Stat_Disp = data; // preserve stat prims in global list
}

// update stat display prims
updateStats() {
    integer i;
    integer num = llGetListLength(GL_Stat_Disp);
    for( i=0; i<num; ++i ) {
        integer link = llList2Integer( GL_Stat_Disp, i );
        // GL_Stat_Mods = str cha dex int con
        string desc = llToUpper( llList2String(llGetLinkPrimitiveParams(link,[PRIM_DESC]),0) );
        if( desc == "STR" ) {
            setStatDisp( link, 1, llList2Integer( GL_Stat_Mods, 0 ) );
        } else if( desc == "CHA" ) {
            setStatDisp( link, 1, llList2Integer( GL_Stat_Mods, 1 ) );
        } else if( desc == "DEX" ) {
            setStatDisp( link, 1, llList2Integer( GL_Stat_Mods, 2 ) );
        } else if( desc == "INT" ) {
            setStatDisp( link, 1, llList2Integer( GL_Stat_Mods, 3 ) );
        } else if( desc == "CON" ) {
            setStatDisp( link, 1, llList2Integer( GL_Stat_Mods, 4 ) );
        } else { // unknown stat?
            setStatDisp( link, 1, 0 );
        }
    }
}

// find clicked basic button
doButton( string bName ) {
    if( bName == ".B_ROL" ) {
        llSay(0, "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname" + " Makes a Flat Roll");
        llMessageLinked( LINK_SET, 1, "ROLL 1 20", "ROLL" );
    } else if( bName == ".B_ATK" ){
        llSay( 0, llKey2Name( llGetOwner() ) +" is Attacking!" );
    } else if( bName == ".B_DEF" ){
        llSay( 0, llKey2Name( llGetOwner() ) +" is Defending!" );
    } else if( bName == ".B_RUN" ){
        llSay( 0, llKey2Name( llGetOwner() ) +" is Being A Coward!" );
    } else if( bName == ".B_QST" ) {
        llSay( GI_Chan_A, "SAI QST" );
    } else if( bName == ".B_HLP" ) {
        llSay( GI_Chan_A, "SAI HLP" );
    } else if( bName == ".B_STARTCONV") {
        llMessageLinked( LINK_THIS, 1, "", "REZZER" );
    } else if( bName == ".B_STOPCONV" ) {
        llSay( GI_Conc_Chan, "DIE" );
    }
} 

// find clicked incrament button
doInc( string bName ) {
    if( bName == ".I_INC_HP" ) {
        llSay( GI_Chan_A, "INC HP 1" );
    } else if( bName == ".I_DEC_HP" ){
        llSay( GI_Chan_A, "INC HP -1" );
    } else if( bName == ".I_INC_WL" ){
        llSay( GI_Chan_A, "INC WL 1" );
    } else if( bName == ".I_DEC_WL" ){
        llSay( GI_Chan_A, "INC WL -1" );
    }
}

// do a dice roll
doRoll( string tag ) {
    list tags = ["STR", "CHA", "DEX", "INT", "CON"];
    list tags_Title = ["Strength", "Charm", "Dexterity", "Intelligence", "Constitution"];
    integer index = llListFindList( tags, [tag] );
    if( index != -1 ) {
        integer mod = llList2Integer( GL_Stat_Mods, index );
        llSay(0, "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname" + " Rolls for "+ llList2String( tags_Title, index ) +" with a "+ sign( mod ) +" Modifier.");
        llMessageLinked( LINK_SET, 1, "ROLL 1 20 "+ (string)mod, "ROLL" );
    }
}

// add a sign to an int and return it as a string
string sign( integer val ) {
    if( val >= 0 ) {
        return "+"+ (string)val;
    }
    return (string)val;
}









default {
    state_entry() {
        setup();
    }
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            llWhisper( 0, "Initializing" );
            setup();
        }
    }
    
    touch_start( integer num ) {
        integer i;
        for( i=0;i<num;++i ) {
            if( llDetectedKey(i) == llGetOwner() ) {
                string pressed = llGetLinkName( llDetectedLinkNumber(i) );
                string test = llToUpper( pressed );
                string ct = llGetSubString( test, 0,1 );
                if( ct == ".B") {
                    doButton( test );
                } else if( ct == ".I" ) {
                    doInc( test );
                } else if( ct == ".D") {
                    doRoll( llToUpper( llList2String(llGetLinkPrimitiveParams(llDetectedLinkNumber(i),[PRIM_DESC]),0) ) );
                }
            }
        }
    }
    
    listen( integer chan, string name, key id, string msg ) {
        llOwnerSay( "Got: ["+ name +"] "+ msg );
        if( llGetOwnerKey( id ) == llGetOwner() && parseSafeCmd( chan, name, id, msg ) ) {
            return;
        }
        parseAltCmd( chan, name, id, msg );
    }
    
    timer() {
        llSetTimerEvent( 0 );
        closeChan();
    }
}
