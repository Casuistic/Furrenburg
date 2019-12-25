/*
// 
// 201910232125
// 201911141400
// 201925120855
*/

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

integer GI_Inv_Max = 6;
list GL_Faces = [ 4, 1, 5, 2, 6, 3 ]; // faces of inventory hud, left -> right, top -> bottom

integer GI_Inv_Select = -1;


vector GV_Scale_In = <0.04305, 0.10931, 0.31523>;
vector GV_Scale_Out = <0.04305, 0.47264, 0.31523>;
vector GV_Loc_In = <-0.03540, -0.39216, 0.26000>;
vector GV_Loc_Out = <-0.03540, -0.13480, 0.26000>;


integer GI_Inv_Chan = 2121;


list GL_Auth_Agent = [
                "2d965865-ceb7-4a19-93a7-ecc74bffc44a", 
                "91ac2b46-6869-48f3-bc06-1c0df87cc6d6"
            ];


string GS_Salt = "CAT_SPAWN_PAD!"; // salt for verification code


integer GL_Listen_Inv = -1;







      
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



debug( string msg ) {
    llOwnerSay( msg );
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
        //if( GI_Inv_Select != -1 && GI_Inv_Select == i ) {
            //col = <0.5,0.25,0.25>;
        //}
        
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, 
            [
                PRIM_TEXTURE, face, img, <1,1,0>, <0,0,0>, PI/2,
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




integer GI_Active_Index = -1;
string GS_Active_Text = "";
list GL_Active_Item_Funcs = [];
list GL_Active_Item_Buttons = [];
openDialog( integer index ) {
    llListenRemove( GL_Listen_Inv );
    GL_Listen_Inv = llListen( 55, "", llGetOwner(), "" );
    llSetTimerEvent( 30 );

    list funcs = llJson2List( llList2String( GL_Inv_Func, index ) );
    GI_Active_Index = index;
    GS_Active_Text = llList2String( GL_Inv_Items, GI_Active_Index );
    GL_Active_Item_Funcs = [];
    GL_Active_Item_Buttons = [];
    integer i;
    for( i=0; i<llGetListLength( funcs ) && i < 9; ++i ) {
        list func = llParseString2List( llList2String( funcs, i ), [":"], [] );
        integer point = llListFindList( GL_Active_Item_Buttons, llList2List( func, 0, 0 ) );
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
    //llOwnerSay( "Trigger: "+ data );
    list funcs = llParseString2List( data, [":"], [] );
    
    integer i;
    integer num = llGetListLength( funcs );
    
    llOwnerSay( "You Used: "+ llList2String( GL_Inv_Items, GI_Active_Index ) );
    
    for( i=0; i<num; ++i ) {
        list parts = llParseString2List( llList2String( funcs, i ), [","], [] );
        
        integer valid = FALSE;
        
        string act = llList2String( parts, 0 );
        if( act == "sb" ) {
            if( !valid = doStatBonus( [llList2String( GL_Inv_Items, GI_Active_Index )] + llList2List( parts, 1, -1 ) ) ) {
                llOwnerSay( "Err: Stat Bonus Invalid"  );
            }
        } else if( act == "re" ) {
            if( !valid = doRestore( [llList2String( GL_Inv_Items, GI_Active_Index )] + llList2List( parts, 1, -1 ) ) ) {
                llOwnerSay( "Err: Restore Invalid"  );
            }
        }
        
        if( !valid ){
            llOwnerSay( "Unknown Action: '"+ llList2String( funcs, i ) +"'" );
        }
    }
    
    dropItem( GI_Active_Index );
    doPrint();
    clearDialogListen();
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




// ack or nack inventory actions
ack( key id, integer chan, string tag ) {
    //llOwnerSay( (string)id +", "+ (string)chan +", "+ "FB:ACK:"+ tag );
    llRegionSayTo( id, chan, "FB:ACK:"+ tag );
}
// ack or nack inventory actions
nak( key id, integer chan, string tag ) {
    //llOwnerSay( (string)id +", "+ (string)chan +", "+ "FB:NAK:"+ tag );
    llRegionSayTo( id, chan, "FB:NAK:"+ tag );
}



integer addItem( string item ) {
    //string test = encode( id,  ); 
    if( llGetListLength( GL_Inv_Raw ) < GI_Inv_Max ) {
        GL_Inv_Raw += [ item ];
        //list data = llParseString2List( item, [","], [] );
        list data = llJson2List( item );
        integer i;
        integer num = llGetListLength( data );
        list end = [ 
                "Unknown",
                "No Description",
                "1377ee26-6938-c41a-99c4-74bbd2544917",
                "0",
                "" ];
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
            } else {
                debug( "bad item data: '"+ tag +"' Aborting" );
                return FALSE;
            }
        }
        GL_Inv_Items += llList2String( end, 0 );
        GL_Inv_Desc += llList2String( end, 1 );
        GL_Inv_Icon += (key)llList2String( end, 2 );
        GL_Inv_Susp += (integer)llList2String( end, 3 );
        GL_Inv_Func += (string)llList2String( end, 4 );
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
        return TRUE;
    }
    debug( "dropItem Failed" );
    return FALSE;
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




// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}


string encode( key id, string text ) {
    string text = llXorBase64( llStringToBase64( GS_Salt + text ), llIntegerToBase64( key2Chan(id,1000000,1000000) ) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}


integer isValidAction( key id, string data, string ver ) {
    return ( encode( id, data ) == ver );
}








default {
    state_entry() {
        llSetLinkPrimitiveParamsFast( LINK_SET, [PRIM_TEXT, "", <1,1,1>, 1] );
    
        map();
        openDisplay( FALSE );
        doPrint();

        llListen( GI_Inv_Chan, "", "", "" );
        llOwnerSay( "Inv Ready!" );
    }

    
    listen( integer chan, string name, key id, string msg ) {
        if( chan == 55 && id == llGetOwner() ) {
            parseUserCmd( msg );
            return;
        }
        llShout( 9090, msg );
        integer index = llListFindList( GL_Auth_Agent, llGetObjectDetails(id, [OBJECT_CREATOR]) );
        //debug( "Listen msg: "+ msg );
        if( llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            //list data = llParseString2List( llGetSubString( msg, 3, -1 ), [":"], [] );
            list data = llJson2List( llGetSubString( msg, 3, -1 ) );
            if( llList2String( data, 0 ) == "IAdd" ) { // add item to inventory
                if( llGetListLength( data ) != 4 ) {
                    debug( "Add Item Too Short" );
                    // cant nak due to invalid input
                    return;
                }
                if( !isValidAction( id, llList2String( data, 1 ), llList2String( data, 2 ) ) ) {
                    debug( "Verification key invalid" );
                    nak( id, chan, llList2String( data, 3 ) );
                    return;
                }
                // insert verification
                if( addItem( llList2String( data, 1 ) ) ) {
                    ack( id, chan, llList2String( data, 3 ) );
                    doPrint();
                } else {
                    nak( id, chan, llList2String( data, 3 ) );
                }
            } else if( llList2String( data, 0 ) == "IDel" ) {
                if( llGetListLength( data ) != 4 ) {
                    debug( "Del Item Too Short" );
                    // cant nak due to invalid input
                    return;
                }
                if( !isValidAction( id, llList2String( data, 1 ), llList2String( data, 2 ) ) ) {
                    debug( "Verification key invalid" );
                    nak( id, chan, llList2String( data, 3 ) );
                    return;
                }
                if( delItem( llList2String( data, 1 ) ) ) {
                    ack( id, chan, llList2String( data, 2 ) );
                    doPrint();
                } else {
                    nak( id, chan, llList2String( data, 2 ) );
                }
            } else if( llList2String( data, 0 ) == "IClr" ) {
                integer i;
                integer num = llGetListLength( data ) -1;
                for( i=1; i<num; ++i ) {
                    if( delItem( llList2String( data, i ) ) ) {
                        ack( id, chan, llList2String( data, -1 ) );
                    } else {
                        nak( id, chan, llList2String( data, -1 ) );
                    }
                }
                doPrint();
            } else if( llList2String( data, 0 ) == "IChk" ) {
                //debug( "Chk: "+ llDumpList2String( data, " // " ) );
                integer i;
                integer num = llGetListLength( GL_Inv_Items );
                string output = "FB:"+ llList2Json( JSON_ARRAY, ["items"] + GL_Inv_Items );
                llRegionSayTo( id, chan, output );
                //debug( "List Dump: "+ output );
            } else {
                debug( "CAT Err: Vad Inv Command" );
            }
        }
    }
    
    
    timer() {
        llSetTimerEvent(0);
        llListenRemove( GL_Listen_Inv );
        GL_Listen_Inv = -1;
        llOwnerSay( "Listen Expired" );
    }
    
    
    link_message( integer src, integer num, string msg, key id ) {
        //debug( (string)num +":"+ msg +":"+ (string)id );
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
