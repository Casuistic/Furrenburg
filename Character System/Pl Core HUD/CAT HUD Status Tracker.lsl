/*
// STATUS TRACKING AND HANDLING!
//
// 201925120855
// 202001091740
// 202001242210 // pre saving before changing channel / lm handeling
*/
#include <LM Chan Ref.lsl> // link message chan ref

#include <oups.lsl> // debugging
string GS_Script_Name = "CAT HUD Status"; // debugging



integer GI_Status_Interval = 15;
integer GI_Time_Interval = 1; // time between ticks of status interval

list GL_Status_Id = [];
list GL_Status_Effects = [];
list GL_Status_Duration = [];
integer GI_Running = FALSE;

list GL_Condition_Id = [];
list GL_Condition_Effects = [];
list GL_Condition_Duration = [];

key GK_Anim_Down = "down";






setup() {
    GL_Status_Id = [];
    GL_Status_Effects = [];
    GL_Status_Duration = [];
    GI_Running = FALSE;
    GI_Set = FALSE;
    if( llGetAttached() != 0 ) {
        reqPermissions( llGetOwner(), FALSE );
    }
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
        GI_Running = TRUE;
        llSetTimerEvent( 1 );//GI_Status_Interval );
    }
    pushAugs();
}

addCondition( string src, string cond, integer dur ) {
    integer index = llListFindList( GL_Condition_Id, [src] );
    dur = dur * GI_Status_Interval;
    if( index == -1 ) {
        GL_Condition_Id += src;
        GL_Condition_Effects += cond;
        GL_Condition_Duration += dur;
    } else {
        GL_Condition_Id = llListReplaceList( GL_Condition_Id, [src], index, index );
        GL_Condition_Effects = llListReplaceList( GL_Condition_Effects, [cond], index, index );
        GL_Condition_Duration = llListReplaceList( GL_Condition_Duration, [dur], index, index );
    }
    integer len = llGetListLength( GL_Status_Id );
    if( len != llGetListLength( GL_Status_Id ) || len != llGetListLength( GL_Status_Id ) ) {
        llOwnerSay( "Condition Tracker Has Gone Wrong!" );
        llOwnerSay( "Con_ids: "+ llDumpList2String( GL_Status_Id, " / " ) );
        llOwnerSay( "Con_Efs: "+ llDumpList2String( GL_Status_Effects, " / " ) );
        llOwnerSay( "Con_Dus: "+ llDumpList2String( GL_Status_Duration, " / " ) );
        llOwnerSay( "Please Inform Casuistic Resident(Sophist) of this!" );
        setup();
    } else if( !GI_Running ) {
        GI_Running = TRUE;
        llSetTimerEvent( GI_Time_Interval );//GI_Status_Interval );
    }
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
        string status = llList2String( GL_Status_Id, index );
        GL_Status_Id = llDeleteSubList( GL_Status_Id, index, index );
        GL_Status_Effects = llDeleteSubList( GL_Status_Effects, index, index );
        GL_Status_Duration = llDeleteSubList( GL_Status_Duration, index, index );
    }
    if( llGetListLength( remove ) != 0 ) {
        llOwnerSay( "You Feel Different...(Status Expired)" );
        pushAugs();
    }
    if( llGetListLength( GL_Status_Id ) == 0 ) {
        return FALSE;
    }
    return TRUE;
}

integer doConditionCheck() {
    integer i;
    integer num = llGetListLength( GL_Condition_Id );
    list remove = [];
    for( i=0; i<num; ++i ) {
        integer dur = llList2Integer( GL_Condition_Duration, i ) - 1;
        if( dur <= 0 ) {
            parseCondition( llList2String( GL_Condition_Effects, i ), FALSE );
            remove += i;
        } else {
            GL_Condition_Duration = llListReplaceList( GL_Condition_Duration, [dur], i, i );
        }
    }
    num = llGetListLength( remove ) -1;
    for( ; num>= 0; --num ) {
        integer index = llList2Integer( remove, i );
        GL_Condition_Id = llDeleteSubList( GL_Condition_Id, index, index );
        GL_Condition_Effects = llDeleteSubList( GL_Condition_Effects, index, index );
        GL_Condition_Duration = llDeleteSubList( GL_Condition_Duration, index, index );
    }
    if( llGetListLength( remove ) != 0 ) {
        llOwnerSay( "You Feel Different...(Condition Expired)" );
    }
    if( llGetListLength( GL_Condition_Id ) == 0 ) {
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
                            llList2Integer( mods, stat )
                            + (integer)llList2String( break, 1 )
                        ], stat, stat );
    }
    llMessageLinked( LINK_ROOT, 555, llDumpList2String( mods, "," ), "STAT_ADJ" );
}




clearAnims() {
    integer i;
    integer num = llGetInventoryNumber( INVENTORY_ANIMATION );
    for( i=0; i<num; ++i ) {
        llStopAnimation( llGetInventoryName( INVENTORY_ANIMATION, i ) );
    }
}


reqPermissions( key id, integer lock ) {
    integer perms = PERMISSION_TRIGGER_ANIMATION;
    if( lock ) {
        perms = perms | PERMISSION_TAKE_CONTROLS;
    } else {
        llReleaseControls();
    }
    llRequestPermissions( id, perms );
}


parseCondition( string cond, integer active ) {
    cond = llToUpper( cond );
    if( cond == "DOWN" ) {
        if( active ) {
            addCondition( "DOWN", "DOWN", 2 );
            llStartAnimation( GK_Anim_Down );
            reqPermissions( llGetOwner(), TRUE );
        } else {
            llStopAnimation( GK_Anim_Down );
            reqPermissions( llGetOwner(), FALSE );
        }
    }
}



integer GI_Set = FALSE;
default {
    run_time_permissions( integer flag ) {
        if( flag & PERMISSION_TRIGGER_ANIMATION ) {
            if( !GI_Set ) {
                GI_Set = TRUE;
                clearAnims();
            }
        }
        if( flag & PERMISSION_TAKE_CONTROLS ) {
            llTakeControls( 
                        CONTROL_FWD |
                        CONTROL_BACK |
                        CONTROL_LEFT |
                        CONTROL_RIGHT |
                        CONTROL_ROT_LEFT |
                        CONTROL_ROT_RIGHT |
                        CONTROL_UP |
                        CONTROL_DOWN
                    , TRUE, FALSE );
        }
    }


    state_entry() {
        safeLoad();
        setup();
    }

    attach( key id ) {
        if( id != NULL_KEY ) {
            GI_Set = FALSE;
            reqPermissions( llGetOwner(), FALSE );
        }
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( num == -1 ) {
            if( id == "Debug" ) {
                llOwnerSay( "Aug_ids: "+ llDumpList2String( GL_Status_Id, " / " ) );
                llOwnerSay( "Aug_Efs: "+ llDumpList2String( GL_Status_Effects, " / " ) );
                llOwnerSay( "Aug_Dus: "+ llDumpList2String( GL_Status_Duration, " / " ) );
                
                llOwnerSay( "Eff_ids: "+ llDumpList2String( GL_Condition_Id, " / " ) );
                llOwnerSay( "Eff_Efs: "+ llDumpList2String( GL_Condition_Effects, " / " ) );
                llOwnerSay( "Eff_Dus: "+ llDumpList2String( GL_Condition_Duration, " / " ) );
            }
            return;
        }
        if( num == GI_LM_STAT_AUG ) {
            if( id == "Stat Augment" ) {
                //llOwnerSay( "SAA: "+ msg );
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
                //llOwnerSay( "SAB: "+ msg );
                list data = llParseString2List( msg, [","], [] );
                if( llGetListLength( data ) != 3 ) {
                    llOwnerSay( "Err: Bad Stat Adjust: '"+ msg +"'" );
                    return;
                }
                if( llList2String( data, 1 ) == "he" ) {
                    llOwnerSay( "Healed by "+ llList2String( data, 2 ) +" from "+ llList2String( data, 0 ) );
                    llMessageLinked( LINK_THIS, 556, llList2String( data, 2 ), "HP_Adj" );
                }
            }
        } else if( num == GI_LM_CONDITION ) {
            if( id == "CONDITION" ) {
                parseCondition( msg, TRUE );
            }
        }
        
        else if( id == "CAT_RESET" ) {
            llResetScript();
        }
    }

    timer() {
        if( !doStatCheck() && !doConditionCheck() ) {
            GI_Running = FALSE;
            llSetTimerEvent( 0 );
        }
    }
}
