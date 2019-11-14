/*
// 
// 201910232125
// 201911141400
*/

integer GI_Inv_Disp = -1;
integer GI_Inv_Data = -1;

/*  INVENTORY STUFF  */
integer GI_Out = FALSE;


key GK_Inv_Icon_Def = TEXTURE_TRANSPARENT;

list GL_Inv_Raw = [];
list GL_Inv_Items = [];
list GL_Inv_Icon = [];
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
        
        vector col = <1,1,1>;
        if( GI_Inv_Select != -1 && GI_Inv_Select == i ) {
            col = <0.5,0.25,0.25>;
        }
        
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
    integer index = llListFindList( GL_Faces, [face] );
    if( index != -1 && (index >= llGetListLength( GL_Inv_Items ) || GI_Inv_Select == index ) ) {
        index = -1;
    }
    
    GI_Inv_Select = index;

    integer i;
    vector col;
    for( i=0; i<6; ++i ) {
        if( GI_Inv_Select == -1 || GI_Inv_Select == i ) {
            col = <1,1,1>;
        } else {
            col = <0.5,0.25,0.25>;
        }
        llSetLinkPrimitiveParamsFast( link, [PRIM_COLOR, llList2Integer( GL_Faces, i ), col, 1] );
    }
    displayText( GI_Inv_Select );
}


ack( key id, integer chan, string tag ) {
    //llOwnerSay( (string)id +", "+ (string)chan +", "+ "FB:ACK:"+ tag );
    llRegionSayTo( id, chan, "FB:ACK:"+ tag );
}

nak( key id, integer chan, string tag ) {
    //llOwnerSay( (string)id +", "+ (string)chan +", "+ "FB:NAK:"+ tag );
    llRegionSayTo( id, chan, "FB:NAK:"+ tag );
}


displayText( integer index ) {
    if( GI_Inv_Disp == -1 ) {
        debug( "Err: GI_Inv_Disp is set to '"+ (string)GI_Inv_Disp +"'" );
        return;
    }
    if( index != -1 ) {
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_TEXT, llList2String( GL_Inv_Items, index ), <1,1,1>, 1] );
    } else {
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_TEXT, "", <1,1,1>, 1] );
    }
}


integer addItem( string item ) {
    if( llGetListLength( GL_Inv_Raw ) < GI_Inv_Max ) {
        list data = llParseString2List( item, [","], [] );
        GL_Inv_Raw += [ item ];
        GL_Inv_Items += llList2String( data, 0 );
        GL_Inv_Icon += (key)llList2String( data, 1 );
        GL_Inv_Susp += (integer)llList2String( data, 2 );
        return TRUE;
    } else {
        llOwnerSay( "Inventory OverLoaded" );
    }
    //debug( "addItem Failed" );
    return FALSE;
}


integer delItem( string item ) {
    integer index = llListFindList( GL_Inv_Items, [item] );
    if( index != -1 ) {
        GL_Inv_Raw = llDeleteSubList( GL_Inv_Raw, index, index );
        GL_Inv_Items = llDeleteSubList( GL_Inv_Items, index, index );
        GL_Inv_Icon = llDeleteSubList( GL_Inv_Icon, index, index );
        GL_Inv_Susp = llDeleteSubList( GL_Inv_Susp, index, index );
        return TRUE;
    }
    debug( "delItem Failed" );
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
        displayText( GI_Inv_Select );
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_POS_LOCAL, GV_Loc_Out, PRIM_SIZE, GV_Scale_Out] );
    } else {
        displayText( -1 );
        llSetLinkPrimitiveParamsFast( GI_Inv_Disp, [PRIM_POS_LOCAL, GV_Loc_In, PRIM_SIZE, GV_Scale_In] );
    }
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
        integer index = llListFindList( GL_Auth_Agent, llGetObjectDetails(id, [OBJECT_CREATOR]) );
        //debug( "Listen msg: "+ msg );
        if( llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            list data = llParseString2List( llGetSubString( msg, 3, -1 ), [":"], [] );
            if( llList2String( data, 0 ) == "IAdd" ) {
                if( addItem( llList2String( data, 1 ) ) ) {
                    ack( id, chan, llList2String( data, 2 ) );
                    doPrint();
                } else {
                    nak( id, chan, llList2String( data, 2 ) );
                }
            } else if( llList2String( data, 0 ) == "IDel" ) {
                if( delItem( llList2String( data, 1 ) ) ) {
                    ack( id, chan, llList2String( data, 2 ) );
                    doPrint();
                } else {
                    nak( id, chan, llList2String( data, 2 ) );
                }
            } else if( llList2String( data, 0 ) == "IChk" ) {
                integer i;
                integer num = llGetListLength( GL_Inv_Items );
                string output = "FB:Items";
                for( i=0; i<num; ++i ) {
                    output += ":"+ llList2String( GL_Inv_Items, i );
                }
                output += ":"+ llList2String( data, llGetListLength(data)-1 );
                llRegionSayTo( id, chan, output );
                //debug( "List Dump: "+ output );
            } else {
                debug( "CAT Err: Vad Inv Command" );
            }
        }
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
