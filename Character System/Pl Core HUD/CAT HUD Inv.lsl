/*
// 
// 201910232125
// 201911141400
// 201925120855
// 202001091740
// 202001200445
// 202001210922
// 202001222222 // new hud
// 202001242210 // pre saving before changing channel / lm handeling
// 202001252033 // added item use sound support
// 202001272322
*/
#define DEBUG
#define REPORT

#include "debug.lsl"
#include "report.lsl"
#include "CAT oups.lsl" // debugging
string GS_Script_Name = "CAT HUD Inv"; // debugging

#include <CAT Filters.lsl>
#include <CAT Encode.lsl>
#include <CAT Chan Ref.lsl> // link message chan ref


integer GI_Inv_Disp = -1;
integer GI_Inv_Data = -1;


/*  INVENTORY STUFF  */
integer GI_Out = FALSE;


key GK_Inv_Icon_Def = TEXTURE_TRANSPARENT;

list GL_Inv_Raw = [];
list GL_Inv_Items = [];
list GL_Inv_Desc = [];
list GL_Inv_Icon = [];
list GL_Inv_Func = [];
list GL_Inv_Susp = [];
list GL_Inv_FSnd = [];


integer GI_Inv_Max = 6;
list GL_Faces = [6,5,4,3,2,1];//[ 4, 1, 5, 2, 6, 3 ]; // faces of inventory hud, left -> right, top -> bottom

integer GI_Inv_Select = -1;


vector GV_Scale_In = <0.020000, 0.300000, 0.100000>; // <0.04305, 0.10931, 0.31523>;
vector GV_Scale_Out = <0.020000, 0.300000, 0.450000>; // <0.04305, 0.47264, 0.31523>;
vector GV_Loc_In = <-0.35, 0, -0.200000>; // <-0.03540, -0.39216, 0.26000>;
vector GV_Loc_Out = <-0.35, 0, 0.275>; // <-0.03540, -0.13480, 0.26000>;




list GL_Auth_Agent = [
                "2d965865-ceb7-4a19-93a7-ecc74bffc44a", 
                "91ac2b46-6869-48f3-bc06-1c0df87cc6d6"
            ];



integer GL_Listen_Inv = -1;



integer GO_Cash_On_Hand = 0;




/*
// FOR THE DIALOG SYSTEM AND ITEM USE
*/
integer GI_Active_Index = -1;
string GS_Active_Text = "";
list GL_Active_Item_Funcs = [];
list GL_Active_Item_Buttons = [];
list GL_Active_Item_Sounds = [];




// map prims and find display prims
map() {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=1;i<=num;++i ) {
        string cmd = llToUpper(llGetLinkName(i));
        if( cmd == ".T_INV" ) {
            GI_Inv_Disp = i;
        } else if( cmd == ".DATA_02" ) {
            GI_Inv_Data = i;
        }
    }
}



doPrint() {
    if( GI_Inv_Disp == -1 ) {
        debug( "Err: GI_Inv_Disp is set to '"+ (string)GI_Inv_Disp +"'" );
        return;
    }
    integer i;
    integer num = llGetListLength( GL_Faces );
    for( i=0; i<num; ++i ) {
        integer face = llList2Integer( GL_Faces, i );
        key img = GK_Inv_Icon_Def;
        if( llGetListLength( GL_Inv_Icon ) > i ) {
            img = llList2Key( GL_Inv_Icon, i );
        }
        
        displayText( -1, GI_Inv_Select = -1 );
        
        vector col = <1,1,1>;
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [
                PRIM_TEXTURE, face, img, <1,1,0>, <0,0,0>, 0,//PI/2,
                PRIM_COLOR, face, col, 1
            ] );
    }

    num = llGetListLength( GL_Inv_Susp );
    integer total;
    for( i=0; i<num; ++i ) {
        total += llList2Integer( GL_Inv_Susp, i );
    }
    
    llMessageLinked( LINK_THIS, 4, "SS:"+(string)total, "COR_SYS" );
}



doInv( integer link, integer face ) {
    //llOwnerSay( "DI: "+ (string)link +" : "+ (string)face );
    integer index = llListFindList( GL_Faces, [face] );
    if( index < 0 || index >= llGetListLength( GL_Inv_Items ) ) {
        index = -1;
        if( index != GI_Inv_Select ) {
            showInvSelect( link, index );
        }
    } else if( GI_Inv_Select == index && GI_Inv_Select >= 0 && GI_Inv_Select < llGetListLength( GL_Inv_Items ) ) {
        // double tap open 
        openDialog( GI_Inv_Select );
    } else {
        // new item selected
        showInvSelect( link, index );
    }
}


showInvSelect( integer link, integer index ) {
    //llOwnerSay( "SIS: "+ (string)link +" : "+ (string)index );
    GI_Inv_Select = index;
    
    integer i;
    vector col;
    for( i=0; i<6; ++i ) {
        if( index == -1 || index == i ) {
            col = <1,1,1>;
        } else {
            col = <0.5,0.25,0.25>;
        }
        llSetLinkPrimitiveParamsFast( link, [PRIM_COLOR, llList2Integer( GL_Faces, i ), col, 1] );
    }
    
    displayText( link, index );
}


displayText( integer link, integer index ) {
    //llOwnerSay( "DT: "+ (string)link +" : "+ (string)index );
    if( link == -1 && (link = GI_Inv_Disp) == -1 ) {
        debug( "Err: link is set to '"+ (string)link +"'" );
        return;
    }
    if( index != -1 ) {
        llSetLinkPrimitiveParamsFast( link, [PRIM_TEXT, 
                llList2String( GL_Inv_Items, index )
                +"\nTouch Again To Examin"
                , <1,1,1>, 1] );
    } else {
        llSetLinkPrimitiveParamsFast( link, [PRIM_TEXT, "", <1,1,1>, 1] );
    }
}





openDialog( integer index ) {
    llListenRemove( GL_Listen_Inv );
    GL_Listen_Inv = llListen( 55, "", llGetOwner(), "" );
    llSetTimerEvent( 30 );

    list funcs = llJson2List( llList2String( GL_Inv_Func, index ) );
    list sref = llJson2List( llList2String( GL_Inv_FSnd, index ) );

    GI_Active_Index = index;
    GS_Active_Text = llList2String( GL_Inv_Items, GI_Active_Index );
    GL_Active_Item_Funcs = [];
    GL_Active_Item_Buttons = [];
    
    GL_Active_Item_Sounds = [];
    integer num = llGetListLength( sref );
    for( ; num-- >= 0; ) {
        GL_Active_Item_Sounds += llParseString2List( llList2String( sref, num ), [":"], [] );
    }
    debug( "AO Key + Sound: "+ llDumpList2String( GL_Active_Item_Sounds, " / " ) );
    integer i;
    for( i=0; i<llGetListLength( funcs ) && i < 9; ++i ) {
        list func = llParseString2List( llList2String( funcs, i ), [":"], [] );
        list cmd = llList2List( func, 0, 0 );
        integer point = llListFindList( GL_Active_Item_Buttons, cmd );
        if( point == -1 ) {
            GL_Active_Item_Buttons += llList2String( func, 0 );
            GL_Active_Item_Funcs += llList2String( func, 1 );
        } else {
            GL_Active_Item_Funcs = llListReplaceList( GL_Active_Item_Funcs, 
                    [llList2String( GL_Active_Item_Funcs, point ) 
                    +":"+ llList2String( func, 1 )],
                point, point );
        }
    }
    presentDialog();
}


presentDialog() {
    llDialog( llGetOwner(), GS_Active_Text, ["Cancel", "Examin", "Drop"] + GL_Active_Item_Buttons, 55 );
}


clearDialogListen() {
    llSetTimerEvent(0);
    llListenRemove( GL_Listen_Inv );
    GL_Listen_Inv = -1;
    
    GI_Active_Index = -1;
    GS_Active_Text = "";
    GL_Active_Item_Funcs = [];
    GL_Active_Item_Buttons = [];
}


integer parseUserCmdCommon( string msg ) {
    if( msg == "Cancel" ) { // check for cancel
        clearDialogListen();
        llSensor( "", "", AGENT, 10, PI );
        return TRUE;
    } else if( msg == "Examin" ) { // check for examin
        llOwnerSay( llList2String( GL_Inv_Desc, GI_Active_Index ) );
        return TRUE;
    } else if( msg == "Drop" ) { // check for drop
        string item = llList2String( GL_Inv_Items, GI_Active_Index );
        if( dropItem( GI_Active_Index ) ) {
            llOwnerSay( "You Dropped: "+ item );
        } else {
            llOwnerSay( "Err: Drop item Failed!" );
        }
        clearDialogListen();
        doPrint();
        return TRUE;
    }
    return FALSE;
}


parseUserCmd( string msg ) {
    integer index = llListFindList( GL_Active_Item_Buttons, [msg] );
    if( index == -1 ) { // button is not custom item action
        parseUserCmdCommon( msg );
        return;
    }
    
    string data = llList2String( GL_Active_Item_Funcs, index );
    list funcs = llParseString2List( data, [":"], [] );

    llOwnerSay( "You Used: "+ llList2String( GL_Inv_Items, GI_Active_Index ) );
    integer used = FALSE;
    
    integer i;
    integer num = llGetListLength( funcs );
    for( i=0; i<num; ++i ) {
        list parts = llParseString2List( llList2String( funcs, i ), [","], [] );
        integer valid = FALSE;
        string act = llList2String( parts, 0 );
        if( act == "sb" ) {
            if( valid = doStatBonus( [llList2String( GL_Inv_Items, GI_Active_Index )] + llList2List( parts, 1, -1 ) ) ) {
                used = TRUE;
            } else {
                llOwnerSay( "Err: Stat Bonus Invalid"  );
            }
        } else if( act == "re" ) {
            if( llGetListLength( parts ) == 4 ) {
                string tar = llList2String( parts, -1 );
                if( tar == "ot" ) {
                    fetchTargets();
                } else if( tar == "se" ) {
                    if( (valid = doRestore( [llList2String( GL_Inv_Items, GI_Active_Index )] + llList2List( parts, 1, -2 ) ) ) ) {
                        used = TRUE;
                    } else {
                        llOwnerSay( "Err: Restore Invalid"  );
                    }
                }
            } else if( (valid = doRestore( [llList2String( GL_Inv_Items, GI_Active_Index )] + llList2List( parts, 1, -1 ) ) ) ) {
                used = TRUE;
            } else {
                llOwnerSay( "Err: Restore Invalid"  );
            }
        } else if( act == "ca" ) {
            string tar = llList2String( parts, -1 );
            if( tar == "ot" ) {
                //fetchTargets();
                // give to other???
            }
            if( valid = doCashAdjust( llList2List( parts, 1, 1 ) ) ) {
                used = TRUE;
            } else {
                llOwnerSay( "Err: Cash Adjust Invalid"  );
            }
        }
        
        if( !valid ){
            llOwnerSay( "Unknown Action: '"+ llList2String( funcs, i ) +"'" );
        }
    }
    
    if( used ) {
        index = llListFindList( GL_Active_Item_Sounds, [msg] );
        if( index != -1 ) {
            key sound = llList2Key( GL_Active_Item_Sounds, index+1 );
            if( isKey( sound ) ) {
                llTriggerSound( sound, 1 );
            }
        }
        dropItem( GI_Active_Index );
        doPrint();
    }
    clearDialogListen();
}


integer doCashAdjust( list data ) {
    data = llJson2List( llList2String( data, 0 ) );
    debug( "doCashAdjust( ["+ llDumpList2String( data, ", " ) +"] )" );
    if( llGetListLength( data ) == 1 ) {
        integer val = (integer)llList2String( data, 0 );
        llOwnerSay( "Cash Adjust: "+ (string)val );
        GO_Cash_On_Hand += val;
        llMessageLinked( LINK_THIS, GI_LM_DISPLAY_CASH, (string)GO_Cash_On_Hand, "CH_Set" );
        return TRUE;
    } else {
        debug( "doCashAdjust Error: Bad List" );
    }
    return FALSE;
}


integer doPay( list data ) {
    debug( "doPay() ["+ llDumpList2String( data, ", " ) +"]" );
    if( llGetListLength( data ) == 1 ) {
        integer val = llAbs( (integer)llList2String( data, 0 ) );
        if( GO_Cash_On_Hand - val >= 0 ) {
            GO_Cash_On_Hand -= val;
            llMessageLinked( LINK_THIS, GI_LM_DISPLAY_CASH, (string)GO_Cash_On_Hand, "CH_Set" );
            return TRUE;
        }
    }
    return FALSE;
}


integer doStatBonus( list data ) {
    //llOwnerSay( "DSB: "+ llDumpList2String( data, ", " ) );
    if( llGetListLength( data ) == 4 ) {
        llMessageLinked( LINK_THIS, 666, llDumpList2String( data, "," ), "Stat Augment" );
        return TRUE;
    }
    return FALSE;
}


integer doRestore( list data ) {
    //llOwnerSay( "DR: "+ llDumpList2String( data, ", " ) );
    if( llGetListLength( data ) == 3 ) {
        llMessageLinked( LINK_THIS, 666, llDumpList2String( data, "," ), "Stat Adjust" );
        return TRUE;
    }
    return FALSE;
}







integer addItem( string item ) {
    //string test = encode( id,  ); 
    if( llGetListLength( GL_Inv_Raw ) < GI_Inv_Max ) {
        GL_Inv_Raw += [ item ];
        list data = llJson2List( item );
        integer i;
        integer num = llGetListLength( data );
        list end = [ 
                    "Unknown",
                    "No Description",
                    "1377ee26-6938-c41a-99c4-74bbd2544917",
                    "0",
                    "",
                    "" 
                ];
        for( i=0; i<num; i+=2 ) {
            string tag = llList2String( data, i );
            if( tag == "name" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 0,0 );
            } else if( tag == "desc" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 1,1 );
            } else if( tag == "img" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 2,2 );
            } else if( tag == "susp" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 3,3 );
            } else if( tag == "func" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 4,4 );
            } else if( tag == "fsnd" ) {
                end = llListReplaceList( end, [llList2String( data, i+1 )], 5,5 );
            }else {
                debug( "bad item data: '"+ tag +"' Aborting" );
                return FALSE;
            }
        }
        GL_Inv_Items += llList2String( end, 0 );
        GL_Inv_Desc += llList2String( end, 1 );
        GL_Inv_Icon += (key)llList2String( end, 2 );
        GL_Inv_Susp += (integer)llList2String( end, 3 );
        GL_Inv_Func += (string)llList2String( end, 4 );
        GL_Inv_FSnd += (string)llList2String( end, 5 );
        debug( "Add Item Func: "+ (string)llList2String( end, 4 ) );
        return TRUE;
    } else {
        llOwnerSay( "Inventory OverLoaded" );
    }
    debug( "addItem Failed" );
    return FALSE;
}


integer delItem( string item ) {
    integer index = llListFindList( GL_Inv_Items, [item] );
    return dropItem( index );
}


integer dropItem( integer index ) {
    if( index >= 0 && index < llGetListLength( GL_Inv_Raw ) ) {
        GL_Inv_Raw = llDeleteSubList( GL_Inv_Raw, index, index );
        GL_Inv_Items = llDeleteSubList( GL_Inv_Items, index, index );
        GL_Inv_Desc = llDeleteSubList( GL_Inv_Desc, index, index );
        GL_Inv_Icon = llDeleteSubList( GL_Inv_Icon, index, index );
        GL_Inv_Func = llDeleteSubList( GL_Inv_Func, index, index );
        GL_Inv_Susp = llDeleteSubList( GL_Inv_Susp, index, index );
        GL_Inv_FSnd = llDeleteSubList( GL_Inv_FSnd, index, index );
        return TRUE;
    }
    debug( "dropItem Failed" );
    return FALSE;
}


fetchTargets() {
    llSensor( "", "", AGENT, 20, TWO_PI );
}


clearTargets() {
    llListenRemove( GI_Listen_Target );
    GL_Indexed_Targets = [];
}


integer GI_Listen_Target = -1;
integer GI_Target_Dialog_Chan = -9988;
list GL_Indexed_Targets = [];
gotTargets( list subs, integer index ) {
    debug( "Got Targets() : ["+ llDumpList2String( subs, "," ) +"], "+ (string)index );
    llListenRemove( GI_Listen_Target );
    GI_Listen_Target = llListen( GI_Target_Dialog_Chan, "", "", "" );
    
    list seek = llList2ListStrided( subs, 0, -1, 2 );
    integer len = llGetListLength( seek );
    
    GL_Indexed_Targets = subs;
    list end;
    if( len > 9 ) {
        if( index == 0 ) {
            end = [">>", "Cancel", "Rescan"];
        } else {
            end = ["<<", "Cancel", "Rescan"];
        }
    } else {
        index = 0;
        end = [" ", "Cancel", "Rescan"];
    }
    if( len > 9 ) {
        if( index == 0 ) {
            seek = llList2List( seek, 0, 8 );
        } else {
            seek = llList2List( seek, 9, -1 );
        }
    }
    llDialog( llGetOwner(), "Pick Target", end + seek, GI_Target_Dialog_Chan );
}


actOnTarget( key id ) {

}


parseTargetCmd( string data ) {
    integer index;
    if( data == "Cancel" ) {
        clearTargets();
    } else if( data == "<<" ) {
        gotTargets( GL_Indexed_Targets, 0 );
    } else if( data == ">>" ) {
        gotTargets( GL_Indexed_Targets, 1 );
    } else if( data =="Rescan" ) {
        fetchTargets();
    } else if( (index = llListFindList( GL_Indexed_Targets, [data] )) != -1 ) {
        actOnTarget( llList2Key( GL_Indexed_Targets, index+1 ) );
        clearTargets();
    }
}


openDisplay( integer open ) {
    if( GI_Inv_Disp == -1 ) {
        debug( "Err: GI_Inv_Disp is set to '"+ (string)GI_Inv_Disp +"'" );
        return;
    }
    if( open == -1 ) {
        open = (GI_Out = ~GI_Out);
    }
    
    if( open ) {
        displayText( -1, GI_Inv_Select );
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_POS_LOCAL, GV_Loc_Out, PRIM_SIZE, GV_Scale_Out] );
    } else {
        displayText( -1, -1 );
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_POS_LOCAL, GV_Loc_In, PRIM_SIZE, GV_Scale_In] );
    }
}










string strTrim( string text, integer len, string pad_b, string pad_e ) {
    if( llStringLength( text ) > len ) {
        text = llGetSubString( text, 0, len-1 );
    } else if( llStringLength( text ) < len && (pad_b != "" || pad_e != "") ) {
        integer cur = llStringLength( text );
        while( cur < len ) {
            if( cur+2 < len || pad_b == "" ) {
                text = pad_b + text;
            }
            if( pad_e == "" ) {
                text += pad_e;
            }
            cur = llStringLength( text );
        }
    }
    return text;
}






parseExternalCmd( key id, integer chan, string raw ) {
    debug( "parseExternalCmd() "+ (string)id +", "+ (string)chan +", "+ raw );
    list data = llJson2List( llGetSubString( raw, 3, -1 ) );

    if( llGetListLength( data ) != 4 ) {
        debug( "Rejected Too Short: "+ raw +" {L:"+ (string)llGetListLength(data)+ "}" );
        return;
    }
    
    string cmd = llList2String( data, 0 );
    string info = llList2String( data, 1 );
    string secKey = llList2String( data, 2 );
    string flag = llList2String( data, 3 );
    
    if( !validSecKey( id, cmd, info, secKey ) ) {
        debug( "parseExternalCmd() Rejected: ["+ llDumpList2String( data, ", " ) +"]" );
        return;
    } else {
        debug( "parseExternalCmd() : parseExternalCmd() Passed" );
    }

    if( cmd == "IAdd" ) { // add item to inventory
        if( addItem( llList2String( data, 1 ) ) ) {
            ack( id, chan, llList2String( data, -1 ) );
            doPrint();
        } else {
            nak( id, chan, llList2String( data, -1 ) );
        }
        return;
    } else if( cmd == "IDel" ) {
        if( delItem( llList2String( data, 1 ) ) ) {
            ack( id, chan, llList2String( data, -1 ) );
            doPrint();
        } else {
            nak( id, chan, llList2String( data, -1 ) );
        }
    } else if( cmd == "IClr" ) {
        list items = llJson2List( llList2String( data, 1 ) );
        integer i;
        integer num = llGetListLength( items );
        for( i=0; i<num; ++i ) {
            string item = llList2String( items, i );
            if( delItem( item ) ) {
                ack_d( id, chan, [item], llList2String( data, -1 ) );
            } else {
                nak_d( id, chan, [item], llList2String( data, -1 ) );
            }
        }
        doPrint();
    } else if( cmd == "IChk" ) {
        doShowItems( id, chan );
    } else if( cmd == "CMod"  ) {
        doCashAdjust( [llList2String( data, 1 )] );
        ack_d( id, chan, [cmd, "Cash Mod"], llList2String( data, -1 ) );
    } else if( cmd == "CPay"  ) {
        if( doPay( llJson2List( llList2String( data, 1 ) ) ) ) {
            ack_d( id, chan, [cmd, "Payment Made"], llList2String( data, -1 ) );
        } else {
            nak_d( id, chan, [cmd, "DoPay Failed"], llList2String( data, -1 ) );
        }
    } else if( cmd == "CChk"  ) {
        doShowCash( id, chan );
    } else {
        debug( "CAT Err: Bad Inv Command: "+ llList2String( data, 0 ) );
    }
}

doShowItems( key id, integer chan ) {
    string output = "FB:"+ llList2Json( JSON_ARRAY, ["items"] + GL_Inv_Items );
    llRegionSayTo( id, chan, output );
}

doShowCash( key id, integer chan ) {
    string output = "FB:"+ llList2Json( JSON_ARRAY, ["Cash", GO_Cash_On_Hand] );
    llRegionSayTo( id, chan, output );
}






default {
    sensor( integer num ) {
        list subs = [];
        integer i;
        for( i=0; i<num; ++i ) {
            string name = strTrim( llDetectedName( i ), 12, "", "" );
            key id = llDetectedKey( i );
            subs += [name, id];
        }
        gotTargets( subs, 0 );
    }


    no_sensor() {
        llOwnerSay( "No Targets in Range" );
        clearTargets();
    }


    state_entry() {
        llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1] );
        map();
        openDisplay( FALSE );
        doPrint();
        llListen( GI_CHAN_INV, "", "", "" );
        llOwnerSay( "Inv Ready!" );
    }


    // used for add/delete items / clear inv and req inv list
    listen( integer chan, string name, key id, string msg ) {
        llOwnerSay( msg );
        if( chan == 55 && id == llGetOwner() ) {
            parseUserCmd( msg ); // parse user input
            return;
        }
        if( chan == GI_Target_Dialog_Chan && id == llGetOwner() ) {
            parseTargetCmd( msg );
            return;
        }
        report( msg );
        debug( "Listen msg: "+ msg );
        if( !isGroup(id) ) { // REJECT NON GROUP OBJECT MESSAGES
            debug( "Non Target Group" );
            return;
        }
        if( llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            parseExternalCmd( id, chan, msg );
        }
    }
    
    
    timer() {
        llSetTimerEvent(0);
        llListenRemove( GL_Listen_Inv );
        GL_Listen_Inv = -1;
        llOwnerSay( "Listen Expired" );
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        debug( "Inv LM: "+ (string)num +":"+ msg +":"+ (string)id );
        if( num == 5 && id == "INV_SYS" ) {
            list data = llParseString2List( msg, [":"], [] );
            if( llList2String( data, 0 ) == "DI" && llGetListLength( data ) == 3 ) {
                integer link = (integer)llList2String( data, 1 );
                integer face = (integer)llList2String( data, 2 );
                doInv( link, face );
            } else if( llList2String( data, 0 ) == "DC" && llGetListLength( data ) == 3 ) {
                if( llList2String( data, 1 ) == "OPEN" ) {
                    openDisplay( (integer)llList2String( data, 2 ) );
                }
            }
        } else if( id == "CAT_RESET" ) {
            debug( "Resetting" );
            llResetScript();
        }
    }
}
