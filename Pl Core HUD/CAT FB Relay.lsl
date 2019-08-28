/*
// Cats makes the best programmers!  
// 
// Basic Relay included in FB HUD
//
// 201908251950
// 201908272340
//
*/


integer GI_N_Relay = 8200;

integer GI_RLVChan = -1812221819;

string GS_ProtVersion = "1101";
string GS_ImpVersion = "CAT_FB_Relay";

key GK_GroupID = "3e895a38-75a3-c112-3f52-8b1451e97e25";
//"bba4ab91-691d-a362-3245-b6a1469142fb";


integer GI_RLVListen;
 

list GL_Traps = [];
list GL_Resturations = [];


string GS_Safeword = "RED";
integer GI_Safeworded;


integer GI_Enabled = TRUE;




integer setDebug() {
    return ( llGetOwner() == (key)"91ac2b46-6869-48f3-bc06-1c0df87cc6d6" );
}


integer GI_Debug = FALSE;
debug( string msg ) {
    if( GI_Debug ) {
        string output = llGetScriptName() +": "+ msg;
        llOwnerSay( output );
        llWhisper( -9999, output );
    }
}



setup() {
    GI_Debug = setDebug();
    llListenRemove( GI_RLVListen );
    GI_RLVListen = llListen( GI_RLVChan, "", "", "" );
    llOwnerSay( "@clear" );
}


relay( key id, string cmd ) {
    if( GI_Debug ) {
        llRegionSay( GI_RLVChan, cmd );
    } else {
        llRegionSayTo( id, GI_RLVChan, cmd );
    }
}

// this isnt needed yet, but it might be soon....
integer trapValid( key id, string cmd ) {
    if( llGetOwnerKey( id ) == llGetOwner() ) {
        return TRUE;
    }
    if( id == GK_GroupID ) {
        return TRUE;
    }
    return TRUE;
}


updateLimits( key id, string rest ) {
    integer index;
    integer seek = llListFindList( GL_Traps, [id] );
    if( seek == -1 ) {
        seek = llGetListLength( GL_Traps );
        GL_Traps += id;
        index = -1;
    } else {
        index = llListFindList( GL_Resturations, [seek, rest] );
    }
    if( index == -1 ) {
        debug( "Added: "+ rest +" for "+ (string)seek );
        GL_Resturations += [seek, rest];
    } else {
        debug( "??repeated??"+ rest );
    }
}


trapCmd( key id, string cmd ) {
    integer index = llSubStringIndex(cmd, "=");
    if( index >= 0 ) {
        string rest = llGetSubString( cmd, 1, index-1 );
        string peram = llGetSubString( cmd, index+1, -1 );
        if( peram == "n" || peram == "add" ) {
            llOwnerSay( cmd );
            updateLimits( id, rest );
        } else if( peram == "y" || peram == "rem" ){
            if( removeSome( id, rest ) ) {
                llOwnerSay( cmd );
            }
        } else {
            if ( rest == "clear" ) {
                debug( "Clear?" );
                releaseSome( id, peram );
            } else {
                debug( "Forced Action from: "+ llKey2Name( id ) );
                llOwnerSay( cmd );
            }
        }
    } else {
        if ( cmd == "@clear" ) {
            release( id );
        } else {
            debug( "[["+ cmd +"]]" );
            llOwnerSay( cmd );
        }
    }
}


release( key id ) {
    debug( "release" );
    integer seek = llListFindList( GL_Traps, [id] ); // find object ref
    if( seek != -1 ) { // if it isnt there cant clear its limits
        integer index;
        while( (index = llListFindList( GL_Resturations, [seek] )) != -1 ) {
            string rest = llList2String( GL_Resturations, index+1 );
            GL_Resturations = llDeleteSubList( GL_Resturations, index, index+1 );
            if( llListFindList(GL_Resturations, [rest]) == -1 ) { // check that this limit isnt imposed elswhere
                // Only clear restruction if something else isnt applying it too
                llOwnerSay("@" + rest + "=y");
            }
        }
    }
    if( llGetListLength( GL_Resturations ) == 0 ) {
        GL_Traps = [];
        //NYH updateStatus( FALSE );
    }
}

// GL_Traps;
// GL_Resturations;
integer removeSome( key id, string rest ) {
    debug( "Remove: "+ rest );
    integer seek = llListFindList( GL_Traps, [id] );
    if( seek != -1 ) {
        integer index = llListFindList( GL_Resturations, [seek, rest] );
        if( index != -1 ) {
            GL_Resturations = llDeleteSubList( GL_Resturations, index, index+1 );
            if ( llGetListLength(GL_Resturations) == 0 ) {
                GL_Traps = [];
                //NHY updateStatus(FALSE);
            }
        }
    }
    if ( llListFindList( GL_Resturations, [rest] ) < 0 ){
        return TRUE;
    }
    return FALSE;
}



releaseSome( key id, string param ) {
    debug( "PartialRelease" );
    integer seek = llListFindList( GL_Traps, [id]);
    if ( seek != -1 ) {
        integer num = llGetListLength(GL_Resturations);
        integer i;
        for ( i = 0 ; i < num ; i += 2 ) {
            if ( llList2Integer(GL_Resturations, i) == seek ) {
                string rest = llList2String(GL_Resturations, i+1 );
                if ( llSubStringIndex(rest, param) >= 0 ) {
                    GL_Resturations = llDeleteSubList(GL_Resturations, i, i + 1);
                    if ( llListFindList(GL_Resturations, [rest]) < 0 )
                        llOwnerSay("@" + rest + "=y");
                    i -= 2;
                    num -= 2;
                }
            }
        }
    }
    if ( llGetListLength(GL_Resturations) == 0 ) {
        GL_Traps = [];
        //NHY updateStatus(FALSE);
    }
}



parseCommand( key id, string msg ) {
    list data = llCSV2List( msg );
    key subject = llList2String(data, 1);
    if( subject == llGetOwner() ) { // the command is for us
        string tag = llList2String(data, 0);
        list cmds = llParseString2List( llList2String(data, 2), ["|"], [] ); // parse remainder of info
        integer i;
        integer num = llGetListLength( cmds );
        for( i=0; i<num; ++i ) {
            string cmd = llList2String( cmds, i );
            if( llGetSubString(cmd, 0, 0) == "@" ) {
                if( trapValid( id, cmd ) ) { // trap is not blacklisted
                    trapCmd( id, cmd );
                    relay( id, tag +","+ (string)id +","+ cmd +",ok" );
                } else { // trap is blacklisted
                    llOwnerSay( "Err: Trap Not Valid?" );
                }
            } else if( !parseMeta( tag, cmd, id ) ) {
                debug( "Unhandled Meta: ["+ cmd +"]" );
            }
        }
    } else {
        if( llGetOwner() == llGetCreator() ) {
            debug( "Remote: "+ llKey2Name( llGetOwnerKey( id ) ) +"'s "+ llKey2Name( id ) +" : "+ msg );
        }
    }
}


/*
*   Parse Meta Command
*/
integer parseMeta( string tag, string cmd, key id ) {
    if( cmd == "!version" ) {
        // protocol version
        relay( id, tag + "," + (string)id + "," + cmd + "," + GS_ProtVersion );
    } else if( cmd == "!implversion" ) {
        // optional: report relay implamentation
        relay( id, tag + "," + (string)id + "," + cmd + "," + GS_ImpVersion );
    } else if( cmd == "!release" ) {
        release( id ); // clear associated commands
        relay( id, tag + "," + (string)id + "," + cmd + ",ok");
    } else if( cmd == "!pong" ) {
        //The relay message must be "ping,<object_uuid>,ping,ping" 
        //and the object message must be "ping,<user_uuid>,!pong". This allows the                 
        //object to keep a listener open with a static filter, 
        //to reduce lag. <user_uuid> can be retrieved by a llGetOwnerKey() call.
    } else if( cmd == "!ping" ) {
        //integer index = llListFindList( GL_Traps, [id] );
        //if( index == -1 ) {
            relay( id, tag + "," + (string)id + "," + cmd + ",ko");
        //} else {
            //relay( id, tag + "," + (string)id + "," + cmd + ",ok");
        //}
    } else {
        return FALSE;
    }
    return TRUE;
}


doSafeword() {
    llOwnerSay( "@Clear" );
    GL_Traps = [];
    GL_Resturations = [];
    GI_Safeworded = TRUE;
    llOwnerSay( "Safeword Applied" );
    setActive( -1 );
    debug( "SAFEWORD USED" );
}


setActive( integer lev ) {
    if( lev == -1 ) {
        llSetLinkColor( LINK_THIS, <1,0,0>, 1 );
    } else if( lev == 0 ) {
        llSetLinkColor( LINK_THIS, <1,1,0>, 1 );
    } else if( lev == 1 ) {
        llSetLinkColor( LINK_THIS, <0,1,0>, 1 );
    } 
}


enable( integer lev ) {
    GI_Enabled = lev;
    if( GI_Enabled == -1 ) {
        llSetColor( <1,0,0>, 1 );
    } else if( GI_Enabled == 0 ) {
        llSetColor( <1,1,0>, 1 );
    } else if( GI_Enabled == 1 ) {
        llSetColor( <0,1,0>, 1 );
    } else {
        llSetColor( <0,0,1>, 1 );
    }
}



default {
    
    state_entry() {
        setup();
        if( GI_Safeworded ) {
            GI_Safeworded = FALSE;
            llOwnerSay( "Safeword Recover" );
        }
        setActive( 1 );
        llListen( 0, "", "", GS_Safeword );
        llListen( 0, "", "", llToUpper( GS_Safeword ) );
        llListen( 0, "", "", llToLower( GS_Safeword ) );
    }
    
    attach( key id ) {
        if( id != NULL_KEY ) {
            enable( 1 );
        } else {
            
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == GI_N_Relay ) {
            if( msg == "SAFEWORD" && id == llGetOwner() ) {
                state safeword;
            } else {
                parseCommand( id, msg );
            }
        }
    }
    
    listen(integer chan, string name, key id, string msg ) {
        if( llGetOwner() == id && msg == GS_Safeword ) {
            llMessageLinked( LINK_SET, GI_N_Relay, "SAFEWORD", llGetOwner() );
        } else if( msg == "dump" ) {
            integer i;
            for( i=0; i<llGetListLength( GL_Traps ); ++i ) {
                llOwnerSay( "Dump: "+ llList2String( GL_Traps, i ) +" : "+ llKey2Name( llList2Key( GL_Traps, i ) ) );
            }
        }
        if( chan == GI_RLVChan ) {
            parseCommand( id, msg );
        }
    }
    
    touch_start( integer num ) {
        if( llDetectedKey(0) == llGetOwner() ) {
            if( GI_Enabled != 1 ) {
                enable( 1 );
            } else {
                enable( 0 );
            }
        }
    }

    
}

state safeword {
    state_entry() {
        doSafeword();
    }
    
    attach( key id ) {
        if( id ) {
            state default;
        }
    }
}
