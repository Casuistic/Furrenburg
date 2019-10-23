

integer GI_Inv_Disp = -1;
integer GI_Inv_Data = -1;

/*  INVENTORY STUFF  */
integer GI_Out = FALSE;


key GK_Inv_Icon_Def = TEXTURE_TRANSPARENT;

list GL_Inv_Raw = [];
list GL_Inv_Items = [];
list GL_Inv_Icon = [];
integer GI_Inv_Max = 6;
list GL_Faces = [ 4, 1, 5, 2, 6, 3 ]; // faces of inventory hud, left -> right, top -> bottom

integer GI_Inv_Select = -1;


vector GV_Scale_In = <0.04305, 0.10931, 0.31523>;
vector GV_Scale_Out = <0.04305, 0.47264, 0.31523>;
vector GV_Loc_In = <-0.03540, -0.39216, 0.26000>;
vector GV_Loc_Out = <-0.03540, -0.13480, 0.26000>;




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



// DEBUG Populate Inventory Panel
generate() {
    if( GI_Inv_Disp == -1 ) {
        return;
    }
    
    addItem( "Booster:36957213-c565-5a1d-4104-647571b73061" );
    addItem( "399 Ammo:af8c40de-aa44-fb43-2aed-2a235b62632a" );
    addItem( "Tool Kit:a2b79dc5-885c-1575-bb21-78e23b121b7b" );
    addItem( "Unknown Illegal:21a3600f-67cd-2faf-ac8c-808a1521c979" );
    doPrint();
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
        GL_Inv_Raw += [ item ];
        list data = llParseString2List( item, [":"], [] );
        GL_Inv_Items += llList2String( data, 0 );
        GL_Inv_Icon += (key)llList2String( data, 1 );
    }
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
        
        generate();
        
        llOwnerSay( "Inv Ready!" );
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
            llResetScript();
        }
    }
}
