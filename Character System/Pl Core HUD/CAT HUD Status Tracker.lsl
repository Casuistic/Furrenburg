/*
// STATUS TRACKING AND HANDLING!
//
// 201925120855
// 202001091740
*/



integer GI_Status_Interval = 15;

list GL_Status_Id = [];
list GL_Status_Effects = [];
list GL_Status_Duration = [];
integer GI_Running = FALSE;



setup() {
    GL_Status_Id = [];
    GL_Status_Effects = [];
    GL_Status_Duration = [];
    GI_Running = FALSE;
}



addEffect( string src, integer mod, integer dur, integer stat ) {
    string ref = src +"_"+ (string)stat;
    integer index = llListFindList( GL_Status_Id, [ref] );
    dur = dur * GI_Status_Interval;
    if( index == -1 ) {
        GL_Status_Id += ref;
        GL_Status_Effects += (string)stat +","+ (string)mod;
        GL_Status_Duration += dur;
    } else {
        GL_Status_Id = llListReplaceList( GL_Status_Id, [ref], index, index );
        GL_Status_Effects = llListReplaceList( GL_Status_Effects, [(string)stat+","+(string)mod], index, index );
        GL_Status_Duration = llListReplaceList( GL_Status_Duration, [dur], index, index );
    }
    integer len = llGetListLength( GL_Status_Id );
    if( len != llGetListLength( GL_Status_Id ) || len != llGetListLength( GL_Status_Id ) ) {
        llOwnerSay( "Stats Tracker Has Gone Wrong!" );
        llOwnerSay( "Aug_ids: "+ llDumpList2String( GL_Status_Id, " / " ) );
        llOwnerSay( "Aug_Efs: "+ llDumpList2String( GL_Status_Effects, " / " ) );
        llOwnerSay( "Aug_Dus: "+ llDumpList2String( GL_Status_Duration, " / " ) );
        llOwnerSay( "Please Inform Casuistic Resident(Sophist) of this!" );
        setup();
    } else if( !GI_Running ) {
        llOwnerSay( "Start" );
        GI_Running = TRUE;
        llSetTimerEvent( 1 );//GI_Status_Interval );
    }
    pushAugs();
}


integer doStatCheck() {
    integer i;
    integer num = llGetListLength( GL_Status_Id );
    list stats = [ "st","ch","de","in","co" ];
    list remove = [];
    for( i=0; i<num; ++i ) {
        string index = llList2String( GL_Status_Id, i );
        list data = llParseString2List( llList2String( GL_Status_Effects, i ), [","], [] );
        integer dur = llList2Integer( GL_Status_Duration, i ) - 1;
        if( dur <= 0 ) {
            remove += i;
        } else {
            GL_Status_Duration = llListReplaceList( GL_Status_Duration, [dur], i, i );
        }
    }
    num = llGetListLength( remove ) -1;
    for( ; num>= 0; --num ) {
        integer index = llList2Integer( remove, i );
        llOwnerSay( "Status Expired: "+ llList2String( GL_Status_Id, index ) );
        GL_Status_Id = llDeleteSubList( GL_Status_Id, index, index );
        GL_Status_Effects = llDeleteSubList( GL_Status_Effects, index, index );
        GL_Status_Duration = llDeleteSubList( GL_Status_Duration, index, index );
    }
    if( llGetListLength( remove ) != 0 ) {
        pushAugs();
    }
    if( llGetListLength( GL_Status_Id ) == 0 ) {
        return FALSE;
    }
    return TRUE;
}


pushAugs() {
    integer i;
    integer num = llGetListLength( GL_Status_Effects );
    list mods = [0,0,0,0,0];
    for( i=0; i<num; ++i ) {
        list break = llParseString2List( llList2String( GL_Status_Effects, i ), [","], [] );
        integer stat = (integer)llList2String( break, 0 );
        mods = llListReplaceList( mods, [
                            llList2Integer( mods, i )
                            + (integer)llList2String( break, 1 )
                        ], stat, stat );
    }
    llMessageLinked( LINK_ROOT, 555, llDumpList2String( mods, "," ), "STAT_ADJ" );
}






default {
    state_entry() {
        setup();
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == -1 ) {
            if( id == "Debug" ) {
                llOwnerSay( "Aug_ids: "+ llDumpList2String( GL_Status_Id, " / " ) );
                llOwnerSay( "Aug_Efs: "+ llDumpList2String( GL_Status_Effects, " / " ) );
                llOwnerSay( "Aug_Dus: "+ llDumpList2String( GL_Status_Duration, " / " ) );
            }
            return;
        }
        if( num == 666 ) {
            if( id == "Stat Augment" ) {
                llOwnerSay( "SAA: "+ msg );
                list data = llParseString2List( msg, [","], [] );
                if( llGetListLength( data ) != 4 ) {
                    llOwnerSay( "Err: Bad Stat Augment: '"+ msg +"'" );
                    return;
                }
                string stat = "Unknown";
                integer stat_index = -1;
                if( llList2String( data, 1 ) == "st"  ) {
                    stat = "Strength";
                    stat_index = 0;
                } else if( llList2String( data, 1 ) == "ch"  ) {
                    stat = "Charm"; 
                    stat_index = 1;
                } else if( llList2String( data, 1 ) == "de"  ) {
                    stat = "Dexterity";
                    stat_index = 2;
                } else if( llList2String( data, 1 ) == "in"  ) {
                    stat = "Intelect";
                    stat_index = 3;
                } else if( llList2String( data, 1 ) == "co"  ) {
                    stat = "Constatution";
                    stat_index = 4;
                } else {
                    llOwnerSay( "Err: Bad Stat Augment: '"+ msg +"'" );
                    return;
                }
                string item = llList2String( data, 0 );
                integer mod = (integer)llList2String( data, 2 );
                integer dur = ((integer)llList2String( data, 3 ));
                addEffect( item, mod, dur, stat_index );
                llSay( 0, llKey2Name( llGetOwner() ) +" augmented their "+ stat +" by "+ (string)mod +" from a "+ item );
            } else if( id == "Stat Adjust" ) {
                llOwnerSay( "SAB: "+ msg );
                list data = llParseString2List( msg, [","], [] );
                if( llGetListLength( data ) != 3 ) {
                    llOwnerSay( "Err: Bad Stat Adjust: '"+ msg +"'" );
                    return;
                }
                if( llList2String( data, 1 ) == "he" ) {
                    llOwnerSay( "Healed by "+ llList2String( data, 2 ) +" from "+ llList2String( data, 0 ) );
                }
            }
        }
    }

    timer() {
        if( !doStatCheck() ) {
            llOwnerSay( "End" );
            GI_Running = FALSE;
            llSetTimerEvent( 0 );
        }
    }
}
