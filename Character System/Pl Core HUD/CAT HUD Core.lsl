/*
// Cats makes the best programmers!  
// 
// FB RP HUD Core Script
//
// 201908251950
// 201908262051
// 201908270132
// 201910232125
*/



integer gListener; // Identity of the listener associated with the dialog, so we can clean up when not needed

list GL_Stat_Mods = [
    0, // str
    0, // cha
    0, // dex
    0, // int
    0 // con
];

integer GI_Data_Prim = -1;

// store prims that display data
list GL_Stat_Disp; // script sets this

integer GI_Inv_Disp = -1;

// 0-8 tiled texture;
key GK_Display_Text = "6a69e885-99a1-9f04-ee42-c2f160fb452c";
key GK_Role_Icon = "85cd93de-8a05-7a05-b89f-33ecbab7b019";


integer GI_Conc_Chan = -55; // channel on which to chat to the balls

integer GI_Listen_A = -1;
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
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, GK_Display_Text, <.333,.333,0>,  <-.333+(0.333*x), -.333+(0.333*y), 0>, 0] );
}


// SET UP POINT
// CALLED ONCE ON SETUP OR OWNER CHANGE
// NEEDS TO MAP THE LINKS, LOAD DATA, ENABLE LISTENS, THEN DISPLAY STATS
setup() {
    llListenRemove( GI_Listen_A );
    llListenRemove( GI_Listen_B );
    
    map(); // map linked set
    load(); // load stored data
    
    openDisplay( FALSE ); // close display on start up
    updateStats(); // update the stats
    
    GI_Chan_A = key2Chan( llGetOwner(), GI_Listen_A_Base, GI_Listen_A_Range );
    GI_Chan_B = key2Chan( llGetOwner(), GI_Listen_B_Base, GI_Listen_B_Range );
    GI_Listen_A = llListen( GI_Chan_A, "", "", "Ping" );
    GI_Listen_B = llListen( GI_Chan_B, "", "", "OpenChan" );
}


//STA;2,8,4,6,0,f49dbcd0-77e5-6700-9c31-2a057f00fcca;QpruAF6M8x0g6ZZ
integer load() {
    if( GI_Data_Prim != -1 ) {
        list data = llParseString2List( llList2String( llGetLinkPrimitiveParams( GI_Data_Prim, [PRIM_DESC]), 0 ), [";"], [] );
        if( llGetListLength( data ) == 3 && llList2String( data, 0 ) == "STA" ) {
            if( verify( llGetOwner(), llList2String( data, 1 ), llList2String( data, 2 ) ) ) {
                //llOwnerSay( "Loading: "+ llList2String( data, 1 ) );
                integer i;
                list tokens = llParseString2List( llList2String(data,1), [","], [] );
                if( llGetListLength( tokens ) == 6 ) {
                    list stats;
                    for(i=0;i<5;++i) {
                        stats += (integer)llList2String(tokens,i);
                    }
                    //llOwnerSay( "Old: "+ llList2String(data,2) );
                    //llOwnerSay( "New: "+ encode( llGetOwner(), llList2String(data,1) ) );
                    GL_Stat_Mods = stats;
                    GK_Role_Icon = (key)llList2String(tokens,5);
                    return TRUE;
                }
            } else {
                llOwnerSay( "Load Failed: Data Not Valid" );
            }
        } else {
            llOwnerSay( "Load Failed: Data Not Found" );
        }
    }
    return FALSE;
}


//STA;2,8,4,6,0,f49dbcd0-77e5-6700-9c31-2a057f00fcca;QpruAF6M8x0g6ZZ
save() {
    if( GI_Data_Prim != -1 ) {
        string text = llDumpList2String( GL_Stat_Mods,"," ) +","+ (string)GK_Role_Icon;
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_TEXTURE, ALL_SIDES, GK_Role_Icon, <1,1,0>, <0,0,0>, 0 ] );
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_DESC, "STA;"+ text +";"+ encode( llGetOwner(), text )] );
    }
}


// Erase stored data
// used on owner change
wipe() {
    if( GI_Data_Prim != -1 ) {
        list stats = [0,0,0,0,0];
        string text = llDumpList2String( stats,"," ) +",85cd93de-8a05-7a05-b89f-33ecbab7b019";
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_DESC, "STA;"+ text +";"+ encode( llGetOwner(), text )] );
    }
}


string GS_Salt = "CATS_WIN!"; // salt for save data
string encode( key id, string text ) {
    string text = llXorBase64( llStringToBase64( GS_Salt + text ), llIntegerToBase64( key2Chan(id,1000000,1000000) ) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}


integer verify( key id, string str1, string str2 ) {
    return( encode( id, str1 ) == str2 );
    //return TRUE;
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
    string cmd = llToUpper( msg );
    llOwnerSay( "Safe Cmd: "+ cmd );
    if( cmd == "PING" ) {
        updateOverhead();
    }
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
        // md: ROL 3EE99ED2-DB9C-8DAA-5256-52768609DBAD
        list data = llParseString2List( cmd, [":"], [] );
        if( llList2String( data, 0 ) == "SETSTATS" && llGetListLength(data) == 2 ) {
            if( setStats( llParseString2List( llList2String( data, 1 ), [","], [] ) ) ) {
                llSetTimerEvent( 60 );
                return TRUE;
            }
        } else if( llList2String( data, 0 ) == "SETROLE" ) {
            if( setRole( llParseString2List( llList2String( data, 1 ), [","], [] ) ) ) {
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
        //llOwnerSay( llDumpList2String( tokens, " : " ) );
        list stats;
        integer i;
        list off = [0,4,2,1,3];
        // needed: str cha dex int con
        // got   : Str int dex con cha
        for(i=0;i<5;++i) {
            string token = llList2String(tokens,llList2Integer( off, i ));
            integer index = llSubStringIndex( token, ";" );
            if( index != -1 ) {
                token = llGetSubString( token, index+1, -1 );
            }
            stats += (integer)token;
        }
        GL_Stat_Mods = stats;
        save();
        updateStats();
        return TRUE;
    }
    return FALSE;
}


integer setRole( list tokens ) {
    llOwnerSay( "Role Updated" );
    GK_Role_Icon = (key)llList2String( tokens, 0 );
    updateStats();
    updateOverhead();
    save();
    return TRUE;
}


// map prims and find display prims
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    list data =[];
    for( i=1;i<=num;++i ) {
        string cmd = llToUpper(llGetLinkName(i));
        if( cmd == ".D_STAT" ) { // find all the stat display prims
            data += i; // log stat display prims
            setStatDisp( i, 1, 0 ); // set zro value
        } else if( cmd == ".DATA_01" ) {
            GI_Data_Prim = i;
        } else if( cmd == ".T_INV" ) {
            GI_Inv_Disp = i;
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


updateOverhead() {
    llRegionSayTo( llGetOwner(), GI_Chan_A, "ROL "+ (string)GK_Role_Icon );
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
        llSay( 0, llKey2Name( llGetOwner() ) +" runs away like a little Bitch!" );
    } else if( bName == ".B_QST" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_A, "SAI QST" );
    } else if( bName == ".B_HLP" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_A, "SAI HLP" );
    } else if( bName == ".B_INV" ) {
        openDisplay( -1 );
    } else if( bName == ".B_STARTCONV") {
        llMessageLinked( LINK_THIS, 1, "", "REZZER" );
    } else if( bName == ".B_STOPCONV" ) {
        llWhisper( GI_Conc_Chan, "DIE" );
    }
} 


// find clicked incrament button
doInc( string bName ) {
    if( bName == ".I_INC_HP" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_A, "INC HP 1" );
    } else if( bName == ".I_DEC_HP" ){
        llRegionSayTo( llGetOwner(), GI_Chan_A, "INC HP -1" );
    } else if( bName == ".I_INC_WL" ){
        llRegionSayTo( llGetOwner(), GI_Chan_A, "INC WL 1" );
    } else if( bName == ".I_DEC_WL" ){
        llRegionSayTo( llGetOwner(), GI_Chan_A, "INC WL -1" );
    }
}



doInv( integer link, integer face ) {
    llMessageLinked( LINK_SET, 5, "DI:"+ (string)link +":"+ (string)face, "INV_SYS" );
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


integer GI_Out = FALSE;
// Open/Close the display
openDisplay( integer open ) {
    llMessageLinked( LINK_SET, 5, "DC:OPEN:"+ (string)open, "INV_SYS" );
}

/*  END OF INVENTORY STUFF  */


default {
    state_entry() {
        llWhisper( 0, "Initializing" );
        llMessageLinked( LINK_SET, 5, "RESET", "CAT_RESET" );
        setup();
        updateOverhead();
        llOwnerSay( "Core Ready!" );
    }
    
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            llWhisper( 0, "Initializing" );
            setup();
            updateOverhead();
            llOwnerSay( "Core Ready!" );
        }
    }
    
    
    touch_start( integer num ) {
        integer i;
        for( i=0;i<num;++i ) {
            if( llDetectedKey(i) == llGetOwner() ) {
                integer link = llDetectedLinkNumber(i);
                string pressed = llGetLinkName( link );
                string test = llToUpper( pressed );
                string ct = llGetSubString( test, 0,1 );
                if( ct == ".B") {
                    doButton( test );
                } else if( ct == ".I" ) {
                    doInc( test );
                } else if( ct == ".D" ) {
                    doRoll( llToUpper( llList2String(llGetLinkPrimitiveParams(llDetectedLinkNumber(i),[PRIM_DESC]),0) ) );
                } else if( ct == ".T" ) {
                    if( test == ".T_INV" ) {
                        integer face = llDetectedTouchFace( i );
                        doInv( link, face );
                    }
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
    
    
    changed( integer flag ) {
        if( flag & CHANGED_OWNER ) {
            llWhisper( 0, "Owner Change Detected" );
            llWhisper( 0, "Wiping Saved Data" );
            wipe();
            llResetScript();
        }
    }
}
