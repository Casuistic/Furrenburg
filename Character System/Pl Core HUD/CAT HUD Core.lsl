/*
// Cats makes the best programmers!  
// 
// FB RP HUD Core Script
//
// 201908251950
// 201908262051
// 201908270132
// 201910232125
// 201925120855
// 202001091740
// 202001210922
// 202001242210 // pre saving before changing channel / lm handeling
*/
#undef DEBUG
#include <debug.lsl>
#include "CAT oups.lsl" // debugging
string GS_Script_Name = "CAT HUD Core"; // debugging


#include <CAT Chan Ref.lsl> // link message chan ref
#include <CAT Filters.lsl>







list GL_Stat_Mods = [
    0, // str
    0, // cha
    0, // dex
    0, // int
    0 // con
];

list GL_Stat_Augs = [
    0, // str
    0, // cha
    0, // dex
    0, // int
    0 // con
];

integer GI_Stat_HP = 5;

integer GI_Data_Prim = -1;

// store prims that display data
list GL_Stat_Disp; // script sets this

integer GI_Inv_Disp = -1;

integer GI_Cash_Disp = -1; // prim for displaying cash monies!!!

integer GI_Link_Class = 0;

// 0-8 tiled texture;
key GK_Display_Text = "407341b2-03d3-8155-59da-921155be2c85";//"6a69e885-99a1-9f04-ee42-c2f160fb452c";
key GK_Role_Icon = "85cd93de-8a05-7a05-b89f-33ecbab7b019";
key GK_Class_Icon = "e2d52c8e-5ccd-a125-9382-e626ac945664";




integer GI_Conc_Chan = -55; // channel on which to chat to the balls

integer GI_Listen_OH = -1;
integer GI_Chan_OH = -22; // open channel for hud to overhead communication

integer GI_Listen_B = -1; // filtered
integer GI_Listen_B2 = -1; // unfiltered

integer GI_Chan_B = -11; // open channel for hud to Stand Comm

integer GI_Chan_C = -33;
integer GI_Listen_C = -1;

integer GI_Min_Sus = 0;

integer GI_Chan_RollOut = -551;


key GK_Anim_Down = "down";






integer roll( integer max ) {
    debug( "roll() '"+ (string)max +"'" );
    return 1 + llFloor( llFrand( max ) );
}



list getDiceRoll( integer nod, integer nof ) {
    llSetSoundQueueing(TRUE);
    //llPreloadSound("cadca9a8-061d-070f-92ec-24f319d8ebe2");
    //llPreloadSound("4acb00cf-d0bf-be65-d694-57e444994054");
    debug( "getDiceRoll() '"+ (string)nod +"', '"+ (string)nof +"'" );
    list rolls = [];
    integer total = 0;
    while( nod-- ) {
        integer val = roll( nof );
        rolls += val;
        total += val;
    }
    rolls += total;
    
    llPlaySound("cadca9a8-061d-070f-92ec-24f319d8ebe2", 1.0);
    llPlaySound("4acb00cf-d0bf-be65-d694-57e444994054", 1.0);
    return rolls;
}




// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    debug( "key2Chan() '"+ (string)id +"', '"+ (string)base +"', '"+ (string)rng +"'" );
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}


// set a display prims texture offset
setStatDispOld( integer link, integer face, integer lev ) {
    debug( "setStatDispOld() '"+ (string)link +"', '"+ (string)face +"', '"+ (string)lev +"'" );
    integer x = lev % 3;
    integer y = ((lev-x)/3);
    llSetLinkPrimitiveParamsFast( link, [PRIM_TEXTURE, face, GK_Display_Text, <.333,.333,0>,  <-.333+(0.333*x), -.333+(0.333*y), 0>, 0] );
}




setStatDisp( integer link, integer lev, integer aug ) {
    debug( "setStatDisp() '"+ (string)link +"', '"+ (string)lev +"', '"+ (string)aug +"'" );
    
    integer score = lev+aug;
    integer size = llAbs(score);
    
    vector col = <1,1,1>;
    if( aug < 0 ) {
        col = <1,1,0>;
    } else if( aug > 0 ) {
        col = <0,1,0>;
    }
    
    float steps = 1.0 / 4;

    integer one = size%10;
    integer ten = (size-one)/10;
    
    integer sign = 15;
    if( score < 0 ) {
        sign = 10;
    } else {
        sign = 11;
    }

    vector start = <-0.37501, 0.37501, 0>;
    llSetLinkPrimitiveParamsFast( link, [
            PRIM_TEXTURE, 0, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, sign ), 0,
            PRIM_TEXTURE, 1, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, ten ), 0,
            PRIM_TEXTURE, 2, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, one ), 0,
            PRIM_COLOR, ALL_SIDES, col, 1
        ] );
}


vector valToOffset( vector start, float step, integer val ) {
    integer val_x = val % 4;
    integer val_y = ((val_x-val) / 4);
    return start + <step*val_x, step*val_y, 0>;
}


// SET UP POINT
// CALLED ONCE ON SETUP OR OWNER CHANGE
// NEEDS TO MAP THE LINKS, LOAD DATA, ENABLE LISTENS, THEN DISPLAY STATS
setup() {
    debug( "setup()" );
    llListenRemove( GI_Listen_OH );
    llListenRemove( GI_Listen_B );
    llListenRemove( GI_Listen_C );

    map(); // map linked set
    load(); // load stored data
    
    openDisplay( FALSE ); // close display on start up
    updateStats(); // update the stats
    setClass( 5 );
    
    GI_Chan_OH = key2Chan( llGetOwner(), GI_CHAN_OH_BASE, GI_CHAN_OH_RANGE );
    GI_Chan_B = key2Chan( llGetOwner(), GI_CHAN_CS_BASE, GI_CHAN_CS_RANGE );
    GI_Listen_OH = llListen( GI_Chan_OH, "", "", "Ping" );
    GI_Listen_B = llListen( GI_Chan_B, "", "", "OpenChan" );
    GI_Listen_C = llListen( GI_Chan_C, "", "", "" );

    updateOverhead();
}


//STA;2,8,4,6,0,f49dbcd0-77e5-6700-9c31-2a057f00fcca;QpruAF6M8x0g6ZZ
integer load() {
    debug( "load()" );
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
                    GK_Class_Icon = "e2d52c8e-5ccd-a125-9382-e626ac945664";
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
    debug( "save()" );
    if( GI_Data_Prim != -1 ) {
        string text = llDumpList2String( GL_Stat_Mods,"," ) +","+ (string)GK_Role_Icon;
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_TEXTURE, ALL_SIDES, GK_Role_Icon, <1,1,0>, <0,0,0>, 0 ] );
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_DESC, "STA;"+ text +";"+ encode( llGetOwner(), text )] );
    }
}


// Erase stored data
// used on owner change
wipe() {
    debug( "wipe()" );
    if( GI_Data_Prim != -1 ) {
        list stats = [0,0,0,0,0];
        string text = llDumpList2String( stats,"," ) +",85cd93de-8a05-7a05-b89f-33ecbab7b019";
        llSetLinkPrimitiveParamsFast( GI_Data_Prim, [PRIM_DESC, "STA;"+ text +";"+ encode( llGetOwner(), text )] );
    }
}


string GS_Salt = "CATS_WIN!"; // salt for save data
string encode( key id, string text ) {
    debug( "encode() '"+ (string)id +"', '"+ text +"'" );
    string text = llXorBase64( llStringToBase64( GS_Salt + text ), llIntegerToBase64( key2Chan(id,1000000,1000000) ) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}


integer verify( key id, string str1, string str2 ) {
    debug( "verify() '"+ (string)id +"', '"+ str1 +"', '"+ str2 +"'" );
    return( encode( id, str1 ) == str2 );
    //return TRUE;
}


openChan( key id ) {
    debug( "openChan() '"+ (string)id +"'" );
    llListenRemove( GI_Listen_B2 );
    GI_Listen_B2 = llListen( GI_Chan_B, "", id, "" );
    llSetTimerEvent( 60 );
}


closeChan() {
    debug( "closeChan()" );
    llListenRemove( GI_Listen_B2 );
}


integer parseAltCmd( integer chan, string name, key id, string msg ) {
    debug( "parseAltCmd() '"+ (string)chan +"', '"+ name +"', '"+ (string)id +"', '"+ msg +"'" );
    string cmd = llToUpper( msg );
    llOwnerSay( "Alt Cmd: "+ name +": "+ msg +" on "+ (string)chan );
    if( cmd == "XXX" ) {
        return TRUE;
    }
    llOwnerSay( "Unknown Alt Cmd: "+ cmd );
    return FALSE;
}

/*
*/
integer parseSafeCmd( integer chan, string name, key id, string msg ) {
    debug( "parseSafeCmd() '"+ (string)chan +"', '"+ name +"', '"+ (string)id +"', '"+ msg +"'" );
    string cmd = llToUpper( msg );
    if( cmd == "PING" ) {
        updateOverhead();
    }
    return FALSE;
}

/*
*/
integer parseStandCmd( integer chan, string name, key id, string msg ) {
    debug( "parseStandCmd() '"+ (string)chan +"', '"+ name +"', '"+ (string)id +"', '"+ msg +"'" );
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
    llOwnerSay( "Unknown Stand Cmd: "+ cmd );
    return FALSE;
}

/*
*/
integer parseExternalCmd( integer chan, string name, key id, string msg ) {
    debug( "parseExternalCmd() '"+ (string)chan +"', '"+ name +"', '"+ (string)id +"', '"+ msg +"'" );
    string cmd = llToUpper( msg );
    //llOwnerSay( "External Cmd: "+ cmd );
    list data = llParseString2List( cmd, [":"], [] );
    string tag = llList2String( data, 0 );
    string end = llList2String( data, -1 );
    if( tag == "DOROLL" ) {
        list stats = ["STR", "CHA", "DEX", "INT", "CON"];
        integer stat = (integer)llList2String( data, 1 );
        llRegionSayTo( id, chan, "ROLL:"+ (string)doRoll( llList2String( stats, stat ), TRUE ) +":"+ end );
    } else if( tag == "HIT" ) {
        integer adj = llAbs( (integer)llList2String( data, 1 ) );
        adjHitPoints( -adj );
    }
    return FALSE;
}

/*  ADJUST HP UP OR DOWN */
adjHitPoints( integer adj ) {
    debug( "adjhitPoints() '"+ (string)adj +"'" );
    setHitPoints( GI_Stat_HP + adj );
}

/*  SET HP TO A GIVEN VALUE */
setHitPoints( integer hp ) {
    debug( "setHitPoints() '"+ (string)hp +"'" );
    if( hp < 0 ) {
        hp = 0;
    } else if( hp > 5 ) {
        hp = 5;
    }
    GI_Stat_HP = hp;
    llRegionSayTo( llGetOwner(), GI_Chan_OH, "SET HP "+ (string)GI_Stat_HP );
    if( hp == 0 ) {
        zeroHitPoints();
    }
}

setMinSus( integer lev ) {
    debug( "setMinSus() '"+ (string)lev +"'" );
    if( lev < 0 ) {
        lev = 0;
    }
    GI_Min_Sus = lev;
    llRegionSayTo( llGetOwner(), GI_Chan_OH, "SET MinSus "+ (string)lev );
}

/*  HP HAS REACHED ZERO */
zeroHitPoints() {
    debug( "zeroHitPoints()" );
    if( llGetOwner() == "91ac2b46-6869-48f3-bc06-1c0df87cc6d6" ) {
        llSay( 0, llKey2Name( llGetOwner() ) +" goes down like the Bitch he is!" );
    } else {
        llSay( 0, llKey2Name( llGetOwner() ) +" goes down!" );
    }
    llMessageLinked( LINK_THIS, 700, "Down", "CONDITION" );
}


/*
*/
integer setStats( list tokens ) {
    debug( "setStats() ['"+ llDumpList2String( tokens, "', '" ) +"']" );
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
    debug( "setRole() ['"+ llDumpList2String( tokens, "', '" ) +"']" );
    GK_Role_Icon = (key)llList2String( tokens, 0 );
    updateStats();
    updateOverhead();
    setClass( 5 );
    save();
    return TRUE;
}

setClass( integer mark ) {
    debug( "setClass()" );//['"+ llDumpList2String( tokens, "', '" ) +"']" );
    float step = 1.0/4;
    llSetLinkPrimitiveParamsFast( GI_Link_Class, [
            PRIM_TEXTURE, ALL_SIDES, GK_Class_Icon, <1.0/4,1.0/4,0>, valToOffset(<-(step+(step/2)),(step+(step/2)),2>, step, mark), 0 ] );
}


// map prims and find display prims
map() {
    debug( "map()" );
    integer i;
    integer num = llGetNumberOfPrims();
    list data =[];
    
    for( i=1;i<=num;++i ) {
        string cmd = llToUpper(llGetLinkName(i));
        if( cmd == ".D_STAT" ) { // find all the stat display prims
            data += i; // log stat display prims
            setStatDisp( i, 0, 0 ); // set zro value
        } else if( cmd == ".DATA_01" ) {
            GI_Data_Prim = i;
        } else if( cmd == ".T_INV" ) {
            GI_Inv_Disp = i;
        } else if( cmd == ".V_CASH" ) { // find all the stat display prims
            GI_Cash_Disp = i;
        } else if( cmd == ".CLASS" ) {
            GI_Link_Class = i;//e2d52c8e-5ccd-a125-9382-e626ac945664
        }
    }
    GL_Stat_Disp = data; // preserve stat prims in global list
}


// update stat display prims
updateStats() {
    debug( "updateStats()" );
    integer i;
    integer num = llGetListLength(GL_Stat_Disp);
    for( i=0; i<num; ++i ) {
        integer link = llList2Integer( GL_Stat_Disp, i );
        // GL_Stat_Mods = str cha dex int con
        string desc = llToUpper( llList2String(llGetLinkPrimitiveParams(link,[PRIM_DESC]),0) );
        if( desc == "STR" ) {
            setStatDisp( link, llList2Integer( GL_Stat_Mods, 0 ), llList2Integer( GL_Stat_Augs, 0 ) );
        } else if( desc == "CHA" ) {
            setStatDisp( link, llList2Integer( GL_Stat_Mods, 1 ), llList2Integer( GL_Stat_Augs, 1 ) );
        } else if( desc == "DEX" ) {
            setStatDisp( link, llList2Integer( GL_Stat_Mods, 2 ), llList2Integer( GL_Stat_Augs, 2 ) );
        } else if( desc == "INT" ) {
            setStatDisp( link, llList2Integer( GL_Stat_Mods, 3 ), llList2Integer( GL_Stat_Augs, 3 ) );
        } else if( desc == "CON" ) {
            setStatDisp( link, llList2Integer( GL_Stat_Mods, 4 ), llList2Integer( GL_Stat_Augs, 4 ) );
        } else { // unknown stat?
            setStatDisp( link, 0, 0 );
        }
    }
}


updateOverhead() {
    debug( "updateOverhead()" );
    llRegionSayTo( llGetOwner(), GI_Chan_OH, "ROL "+ (string)GK_Role_Icon );
    llRegionSayTo( llGetOwner(), GI_Chan_OH, "SET HP "+ (string)GI_Stat_HP );
    llRegionSayTo( llGetOwner(), GI_Chan_OH, "SET MinSus "+ (string)GI_Min_Sus );
}


// find clicked basic button
doButton( string bName ) {
    debug( "dpButton() '"+ bName +"'" );
    if( bName == ".B_ROL" ) {
        //llSay(0, "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname" + " Makes a Flat Roll");
        //llMessageLinked( LINK_SET, 1, "ROLL 1 20", "ROLL" );
        doRoll( "", FALSE );
    } else if( bName == ".B_ATK" ){
        llOwnerSay( "Augs: "+ llDumpList2String( GL_Stat_Augs, " / " ) );
        llMessageLinked( LINK_SET, -1, "dump augs", "Debug" );
        //llSay( 0, llKey2Name( llGetOwner() ) +" is Attacking!" );
    } else if( bName == ".B_DEF" ){
        llSay( 0, llKey2Name( llGetOwner() ) +" is Defending!" );
    } else if( bName == ".B_RUN" ){
        llSay( 0, llKey2Name( llGetOwner() ) +" runs away like a little Bitch!" );
    } else if( bName == ".B_QST" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "SAI QST" );
    } else if( bName == ".B_HLP" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "SAI HLP" );
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
    debug( "doInc() '"+ bName +"'" );
    if( bName == ".I_INC_HP" ) {
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "INC HP 1" );
    } else if( bName == ".I_DEC_HP" ){
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "INC HP -1" );
    } else if( bName == ".I_INC_WL" ){
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "INC WL 1" );
    } else if( bName == ".I_DEC_WL" ){
        llRegionSayTo( llGetOwner(), GI_Chan_OH, "INC WL -1" );
    }
}

/*
*/
doInv( integer link, integer face ) {
    debug( "parseTouch() '"+ (string)link +"' '"+ (string)face +"'" );
    llMessageLinked( LINK_SET, 5, "DI:"+ (string)link +":"+ (string)face, "INV_SYS" );
}


// do a dice roll
integer doRoll( string tag, integer quiet ) {
    debug( "dpRoll() '"+ tag +"' '"+ (string)quiet +"'" );
    list tags = ["STR", "CHA", "DEX", "INT", "CON"];
    list tags_Title = ["Strength", "Charm", "Dexterity", "Intelligence", "Constitution"];
    integer index = llListFindList( tags, [tag] );
    if( index != -1 ) {
        llMessageLinked( LINK_ALL_CHILDREN, 1000, "cadca9a8-061d-070f-92ec-24f319d8ebe2,4acb00cf-d0bf-be65-d694-57e444994054", "SOUND" );
        integer mod = llList2Integer( GL_Stat_Mods, index );
        integer aug = llList2Integer( GL_Stat_Augs, index );
        //llSay(0, "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname" + " Rolls for "+ llList2String( tags_Title, index ) +" with a "+ sign( mod ) +" Modifier.");
        //llMessageLinked( LINK_SET, 1, "ROLL 1 20 "+ (string)mod, "ROLL" );
        integer nod = 1;
        integer nof = 20;
        list data = getDiceRoll( nod, nof );
        string out = "["+ llDumpList2String( llList2List( data, 0, -2 ), "," ) +"]";
        integer total = llList2Integer( data, -1 );
        if( !quiet ) {
            llSay( 0, 
                    "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname "+
                    "Rolled "+ llList2String( tags_Title, index ) +" on "+ (string)nod 
                    +" D"+ (string)nof 
                    +" and got "+ out 
                    +" Totaling: "+ (string)total
                    +" with a "+ sign( mod ) +" Stat Bonus and "+
                    sign( aug ) +" Modifier, Scoring: "+
                    (string)(total + mod + aug)
                );
        }
        llShout( GI_Chan_RollOut, "Roll,"+ out +","+ (string)total +","+ (string)mod +","+ (string)aug );
        return (total + mod + aug);
    } else {
        llMessageLinked( LINK_ALL_CHILDREN, 1000, "cadca9a8-061d-070f-92ec-24f319d8ebe2,4acb00cf-d0bf-be65-d694-57e444994054", "SOUND" );
        integer nod = 1;
        integer nof = 20;
        list data = getDiceRoll( nod, nof );
        string out = "["+ llDumpList2String( llList2List( data, 0, -2 ), "," ) +"]";
        integer total = llList2Integer( data, -1 );
        if( !quiet ) {
            llSay( 0, 
                    "secondlife:///app/agent/" + (string)llGetOwner() + "/displayname "
                    +"Made a Flat Roll "
                    +" D"+ (string)nof 
                    +" and got "+ out 
                    +" Totaling: "+ (string)total
                );
        }
        llShout( GI_Chan_RollOut, "Roll,"+ out +","+ (string)total );
        return (total);
    }
}


// add a sign to an int and return it as a string
string sign( integer val ) {
    debug( "sign() '"+ (string)val +"'" );
    if( val >= 0 ) {
        return "+"+ (string)val;
    }
    return (string)val;
}


integer GI_Out = FALSE;
// Open/Close the display
openDisplay( integer open ) {
    debug( "openDisplay() '"+ (string)open +"'" );
    llMessageLinked( LINK_SET, 5, "DC:OPEN:"+ (string)open, "INV_SYS" );
}

/*  END OF INVENTORY STUFF  */





integer parseStatAdjust( string msg, string tag ) {
    debug( "parseStatAdjust() '"+ msg +"' '"+ tag +"'" );
    if( tag == "STAT_ADJ" ) {
        list data = llParseString2List( msg, [","], [] );
        if( llGetListLength( data ) == 5 ) {
            list out = [];
            integer i;
            for( i=0; i<5; ++i ) {
                out += (integer)llList2String( data, i );
            }
            GL_Stat_Augs = out;
            updateStats();
            return TRUE;
        }
    }
    return FALSE;
}


parseTouch( integer link, integer face ) {
    debug( "parseTouch() '"+ (string)link +"'" );
    string pressed = llGetLinkName( link );
    string test = llToUpper( pressed );
    string ct = llGetSubString( test, 0,1 );
    if( ct == ".B") {
        if( test == ".B_DIE" ) {
            float f = 0.4;
            float l = f/2;
            vector mod = <l-llFrand(f),l-llFrand(f),l-llFrand(f)>;
            mod = mod / (llVecMag( mod )*2);
            llSetLinkPrimitiveParams( link, [PRIM_OMEGA, mod*llGetLocalRot(),PI,1.0]);
            test = ".B_ROL";
        }
        doButton( test );
    } else if( ct == ".I" ) {
        doInc( test );
    } else if( ct == ".D" ) {
        doRoll( llToUpper( llList2String(llGetLinkPrimitiveParams(link,[PRIM_DESC]),0) ), FALSE );
    } else if( ct == ".T" ) {
        if( test == ".T_INV" ) {
            doInv( link, face );
        }
    }
}



fullReset() {
    debug( "fullReset()" );
    llOwnerSay( "Performing Full Reset!" );
    string me = llGetScriptName();
    integer i;
    integer num = llGetInventoryNumber( INVENTORY_SCRIPT );
    for( i=0; i<num; ++i ) {
        string name = llGetInventoryName( INVENTORY_SCRIPT, i );
        if( name != me ) {
            llResetOtherScript( name );
        }
    }
}


integer GO_Cash_On_Hand = 0;
setCash( integer link, integer val ) {
    GO_Cash_On_Hand = val;
    vector col = <1,1,1>;
    if( val < 0 ) {
        col = <1,0,0>;
        val = llAbs( val );
    }
    float steps = 1.0 / 4;
    vector start = <-0.37501, 0.37501, 0>;
    
    integer end = 0;
    
    if( val > 999999999 ) {
        end = 13;
        val = val / 1000000;
    } else if( val > 9999999 ) {
        end = 12;
        val = val / 1000;
    }
    
    string v = (string)val;
    integer p = llStringLength( v );
    
    integer i;
    integer num = llGetLinkNumberOfSides( link );
    p = num - (1+p);
    if( end != 0 ) {
        p-=1;
    }
    list data = [];
    for( i=0; i<num; ++i ) {
        if( i < p ) {
            data += [PRIM_TEXTURE, i, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, 15 ), 0];
        } else if( i==p ) {
            data += [PRIM_TEXTURE, i, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, 14 ), 0];
        } else if( end != 0 && i==(num-1) ) {
            data += [PRIM_TEXTURE, i, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, end ), 0];
        } else {
            integer m = p+1;
            integer e = (integer)llGetSubString( v, i-m, i-m );
            data += [PRIM_TEXTURE, i, GK_Display_Text, <steps,steps,0>,  valToOffset( start, steps, e ), 0];
        }
    }
    data += [PRIM_COLOR, ALL_SIDES, col, 1];
    llSetLinkPrimitiveParamsFast( link, data );
}



default {
    state_entry() {
        debug( "SE State Entry" );
        safeLoad();
        llWhisper( 0, "Initializing" );
        llMessageLinked( LINK_SET, 5, "RESET", "CAT_RESET" );
        setup();
        llOwnerSay( "Core Ready!" );
        setCash( GI_Cash_Disp, 0 );
        //fullReset();
    }
    
    
    attach( key id ) {
        debug( "AT Attach" );
        if( id != NULL_KEY ) {
            llWhisper( 0, "Initializing" );
            setup();
            llOwnerSay( "Core Ready!" );
        }
    }
    
    
    touch_start( integer num ) {
        debug( "TS Touch" );
        integer i;
        for( i=0;i<num;++i ) {
            if( llDetectedKey(i) == llGetOwner() ) {
                parseTouch( llDetectedLinkNumber(i), llDetectedTouchFace( i ) );
            }
        }
    }
    
    
    listen( integer chan, string name, key id, string msg ) {
        debug( "LI: "+ (string)chan +", "+ name +", "+ (string)id +", "+ msg );
        if( chan == GI_Chan_OH ) { // overhead hud
            debug( "LI Chan_A" );
            if( isUserSafe( id ) ) { // same owner
                parseSafeCmd( chan, name, id, msg );
                return;
            }
        } else if( chan == GI_Chan_B ) { // character stand
            debug( "LI Chan_B" );
            if( isGroup( id ) ) { // FB group
                parseStandCmd( chan, name, id, msg );
                return;
            }
        } else if( chan == GI_Chan_C ) { // external elements // force roll and the like
            debug( "LI Chan_C" );
            if( isGroup( id ) ) { // FB group
                parseExternalCmd( chan, name, id, msg );
                return;
            }
        } else {
            debug( "LI Chan_Unknown" );
            llOwnerSay(  (string)chan +" ? Got: ["+ name +"] "+ msg );
        }
        parseAltCmd( chan, name, id, msg );
    }
    
    
    timer() {
        debug( "TI" );
        llSetTimerEvent( 0 );
        closeChan();
    }
    
    
    changed( integer flag ) {
        if( flag & CHANGED_OWNER ) {
            debug( "CH Owner" );
            llWhisper( 0, "Owner Change Detected" );
            llWhisper( 0, "Wiping Saved Data" );
            wipe();
            llResetScript();
        } else if( flag & CHANGED_INVENTORY ) {
            //fullReset();
            llResetScript();
        }
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        debug( (string)num +":"+ msg +":"+ (string)id );
        if( num == GI_LM_CORE_SUSTEM ) {
            if( id == "COR_SYS" ) {
                debug( "LM 01" );
                list data = llParseString2List( msg, [":"], [] );
                if( llList2String( data, 0 ) == "SS" && llGetListLength( data ) == 2 ) {
                    setMinSus( (integer)llList2String( data, 1 ) );
                }
            }
        } else if( num == GI_LM_DISPLAY_STATS ) {
            debug( "LM 02" );
            parseStatAdjust( msg, (string)id );
        } else if( num == GI_LM_DISPLAY_HP ) {
            if( id == "HP_Adj" ) {
                debug( "LM 03" );
                adjHitPoints( (integer)msg );
            }
        }else if( num == GI_LM_DISPLAY_CASH ) {
            if( id == "CH_Set" ) {
                debug( "LM 04" );
                setCash( GI_Cash_Disp, (integer)msg );
            }
        }
    }
}
