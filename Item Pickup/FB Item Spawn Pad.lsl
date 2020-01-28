// XXXX
//
//
//
// 201911121730
// 201911131622
// 201911141249
// 201912210620
// 201912240651
// 201925120855
// 202001200633
// 202001211801
// 202001242254
// 202001252033 // added item use sound support
#undef DEBUG
#include <debug.lsl>

#include <CAT Chan Ref.lsl> // link message chan ref
#include <CAT Encode.lsl>

integer chan = -100; // used for death command to rezzed display item

key GK_Rezzed;

//key GK_Subject = NULL_KEY; // potencial pickup target used for listen filtering




integer GI_Respawn_Time = 5;

string GS_Pickup_Sound = "bd884944-ee8c-1b34-96ee-27777eba991a";
string GS_Respawn_Sound = "0a56abd7-4531-3786-118e-e2d5dbb6c66f";

string GS_Item_Name = ""; // item name
//string GS_Item_desc = "";
key GK_Item_Img  = NULL_KEY; // item image
//list GL_Item_Func = [];
//integer GI_Item_Susp = 0; // suspishon to add when item picked up

string GS_JSON_Data = "";
string GS_Encode_Key = ""; // encode();
string GS_End_Flag = "VerFlag"; // verification flag





vector GV_Pad_Offset = <0,0,0.35>;
vector GV_Pad_Colour = <1,1,1>; // pad colour on valid state

rotation GR_Ori = ZERO_ROTATION;


string GS_DataNote = "Data"; // notecard name to be loaded
integer GI_DataNote_Line; // current loading NC line
key GK_Dataserver_Ref; // used during notecard loading

key GK_LoadedCard = NULL_KEY; // notecard key / reloaded if not found on state change



integer GI_Listen = -1; // listen for verification


//string GS_Salt = "CAT_SPAWN_PAD!"; // salt for verification code


key GK_Subject = NULL_KEY;





/////////////////
//  FUNCTIONS  //
/////////////////
// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}


// remove rezed display item
clear() {
    setPadColor( <0.2,0.2,0.2> );
    if( GK_Rezzed != NULL_KEY ) {
        llRegionSayTo( GK_Rezzed, chan, "DIE" );
        llTriggerSound( GS_Pickup_Sound, 1 );
        GK_Rezzed = NULL_KEY;
    }
}

// rez the internal display object
integer rez() {
    string name = "";
    integer num = llGetInventoryNumber( INVENTORY_OBJECT );
    if( num != 0 ) {
        name = llGetInventoryName( INVENTORY_OBJECT, 0 );
        llRezObject( name, llGetPos() + GV_Pad_Offset, ZERO_VECTOR, GR_Ori, chan );
        llTriggerSound( GS_Respawn_Sound, 1 );
        setPadColor( GV_Pad_Colour );
        return TRUE;
    }
    setPadColor( <1,0,0> );
    return FALSE;
}


// badly named. Change to something clearer
// initalises contact to add item to someones inventory
integer verify( key id ) {
    GK_Subject = id;
    //string space = ",";
    string json = llList2Json( JSON_ARRAY, ["IAdd" ,GS_JSON_Data, GS_Encode_Key, GS_End_Flag] );//llList2Json( JSON_ARRAY, GL_Item_Func );
    if( JSON_INVALID == json ) {
        return FALSE;
    }
    //llRegionSayTo( id, GI_CHAN_INV, "FB:IAdd:"+ GS_Item_Name +space+ (string)GK_Item_Img +space+ (string)GI_Item_Susp +space+ json +space+ GS_Encode_Key +":"+ GS_End_Flag );
    llRegionSayTo( id, GI_CHAN_INV, "FB:"+ json );
    return TRUE;
}


// verify all core values are valid
integer isReady() {
    if( GI_Respawn_Time <= 0 ) {
        return FALSE;
    }
    if( GS_Item_Name == "" ) {
        return FALSE;
    }
    if( GK_Item_Img == "" || GK_Item_Img == NULL_KEY ) {
        return FALSE;
    }
    return TRUE;
}


resetItem() {
    GS_Item_Name = "Unknown";
    GK_Item_Img = "1377ee26-6938-c41a-99c4-74bbd2544917";
    GS_JSON_Data = llList2Json( JSON_OBJECT, [
            "name","Unknown",
            "desc","No Item Desc",
            "img","1377ee26-6938-c41a-99c4-74bbd2544917",
            "susp","0"
        ] );
    GS_Encode_Key = encode( llGetKey(), "IAdd", GS_JSON_Data );
}


// notecard value parsing
parse( string raw ) {
    list data = llParseString2List( raw, [";"], [] );
    
    integer i;
    integer num = llGetListLength( data );
    for( i=0; i<num; ++i ) {
        string value = llStringTrim( llList2String( data, i ), STRING_TRIM );
        integer index = llSubStringIndex( value, "=" );
        if( index != -1 ) {
            integer end = llStringLength( value )-1;
            string tag = "NO_KEY";
            if( index != 0 ) {
                tag = llToLower( llGetSubString( value, 0, (index-1) ) );
            }
            string val = "NO_VAL";
            if( index < end ) {
                val = llGetSubString( value, (index+1), -1 );
            }
            if( tag == "item_name" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Item_Name = val;
                GS_JSON_Data = json( GS_JSON_Data, "name", val );
            } else if( tag == "item_desc") {
                //GS_Item_desc = val;
                GS_JSON_Data = json( GS_JSON_Data, "desc", val );
            } else if( tag == "item_icon" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GK_Item_Img = (key)val;
                GS_JSON_Data = json( GS_JSON_Data, "img", val );
            } else if( tag == "item_susp" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                //GI_Item_Susp = (integer)val;
                GS_JSON_Data = json( GS_JSON_Data, "susp", val );
            } else if( tag == "item_func" ) {
                if( llStringLength(val) > 0 ) {
                    //GL_Item_Func += val;
                    GS_JSON_Data = jsonArr( GS_JSON_Data, "func", JSON_APPEND, val );
                }
            } else if( tag == "item_func_sound" ) {
                if( llStringLength(val) > 0 ) {
                    //GL_Item_Func += val;
                    GS_JSON_Data = jsonArr( GS_JSON_Data, "fsnd", JSON_APPEND, val );
                }
            } else if( tag == "item_spawn_time" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GI_Respawn_Time = (integer)val;
            } else if( tag == "pickup_sound" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Pickup_Sound = (key)val;
            } else if( tag == "respawn_sound" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GS_Respawn_Sound = (key)val;
            } else if( tag == "pad_colour" ) {
                //llOwnerSay( "Set: '"+ tag +"' : '"+ val +"'" );
                GV_Pad_Colour = (vector)val;
            } else if( tag == "pad_offset" ) {
                GV_Pad_Offset = (vector)val;
            } else if( tag == "item_ang" ) {
                GR_Ori = llEuler2Rot( (vector)val * DEG_TO_RAD );
            } else {
                llOwnerSay( "Loaded Unknown Info: '"+ tag +"' = '"+ val +"'" );
            }
        }
    }
}



setPadColor( vector col ) {
    llSetLinkPrimitiveParamsFast( LINK_THIS, [
                    PRIM_COLOR, 1, col, 1, 
                    PRIM_TEXTURE, 1, "a0272345-9789-d187-4184-2e0815b2b1da", <1,1,0>, <0,0,0>, 0
                ] );
}


// handle error appearance
error( integer err ) {
    if( !err ) {
        setPadColor( <1,1,1> );
        llSetLinkTextureAnim( LINK_THIS, FALSE, 1, 0, 0, 0.0, 0.0, 1.0 );
    } else {
        setPadColor( <1,0,0> );
        llSetLinkTextureAnim( LINK_THIS, ANIM_ON | SMOOTH | LOOP, 1, 1000, 1, 0.0, 1000.0, 100.0 );
    }
}


parseChange( integer flag ) {
    if( flag & CHANGED_INVENTORY ) {
        llResetScript();
    }
}










//////////////
//  STATES  //
//////////////


default {
    state_entry() {
        key id = (key)llGetObjectDesc();
        llRegionSayTo( id, chan, "DIE" );
        error( FALSE );
        //state respawn;
        
        if( llGetInventoryType( GS_DataNote ) == INVENTORY_NONE ) {
            llOwnerSay( "Notecard '"+ GS_DataNote +"' Not Found!" );
            state broken;
        }
        
        llSetText( "Loading...", <1,1,1>, 1.0 );
        
        GK_LoadedCard = llGetInventoryKey( GS_DataNote );
        
        resetItem();
        GI_DataNote_Line = 0;
        GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, GI_DataNote_Line );
        
    }

    state_exit() {
        llSetText( "", <1,1,1>, 0.0 );
        error( FALSE );
    }
    
    on_rez( integer peram ) {
        llResetScript();
    }
    
    dataserver(key keyQueryId, string strData) {
        if ( keyQueryId == GK_Dataserver_Ref ) {
            llSetTimerEvent( 0 );
            GK_Dataserver_Ref = NULL_KEY;
            if (strData == EOF) {
                GS_Encode_Key = compileKey( "IAdd", GS_JSON_Data );
                if( isReady() ){
                    state respawn;
                }
                state broken;
            }
            
            strData = llStringTrim(strData, STRING_TRIM_HEAD);
            if (llGetSubString (strData, 0, 0) != "#") { // skip comments
                //llOwnerSay( strData );
                parse( strData );
            }
            llSetTimerEvent( 0.5 );
        }
    }
    
    timer() {
        if( GK_Dataserver_Ref == NULL_KEY ) { // next line
            GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, ++GI_DataNote_Line);
            llSetTimerEvent( 15 );
        } else { // retry last
            GK_Dataserver_Ref = llGetNotecardLine( GS_DataNote, GI_DataNote_Line);
            llSetTimerEvent( 15 );
        }
    }
    
    changed( integer flag ) {
        parseChange( flag );
    }
}


state broken {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        llSetText( "Error", <1,1,1>, 1 );
        error( TRUE );
    }
    
    state_exit() {
        llSetText( "", <1,1,1>, 1 );
        error( FALSE );
    }
    
    changed( integer flag ) {
        parseChange( flag );
    }
}


state ready {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    collision_start( integer num ) {
        if( GK_Rezzed == NULL_KEY ) {
            state respawn;
        }
        if( llDetectedType( 0 ) & AGENT_BY_LEGACY_NAME ) {
            GI_Listen = llListen( GI_CHAN_INV, "", "", "" );
            if( GK_Subject == NULL_KEY && verify( llDetectedKey( 0 ) ) ) {
                llSetTimerEvent( 10 );
            }
        }
    }
    
    listen( integer chan, string name,  key id, string msg ) {
        if( llGetOwnerKey( id ) == GK_Subject && llStringLength( msg ) > 3 && llGetSubString( msg, 0, 2 ) == "FB:" ) {
            list data = llJson2List( llGetSubString( msg, 3, -1 ) );
            if( llList2String( data, 0 ) == "ACK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
                state respawn;
            } else if( llList2String( data, 0 ) == "NAK" && llList2String( data, -1 ) == GS_End_Flag ) {
                llListenRemove( GI_Listen );
                GK_Subject = NULL_KEY;
            }
        }
    }
    
    state_entry() {
        GS_End_Flag = ranStr( 3 );
        GK_Subject = NULL_KEY;
    }
    
    state_exit() {
        llSetTimerEvent( 0 );
    }
    
    timer() {
        llListenRemove( GI_Listen );
        GK_Subject = NULL_KEY;
        llSetTimerEvent( 0 );
    }
    
    changed( integer flag ) {
        parseChange( flag );
    }
}


state spawn {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        clear();
        
        if( GK_LoadedCard != llGetInventoryKey( GS_DataNote ) ) {
            llResetScript();
        }
        
        if( !rez() ) {
            error( TRUE );
        }
    }
    
    object_rez( key id ) {
        llSleep( 1 ); // wait 1 second for initalisation
        GK_Rezzed = id;
        llSetObjectDesc( id );
        state ready;
    }
    
    changed( integer flag ) {
        parseChange( flag );
    }
}


state respawn {
    on_rez( integer peram ) {
        llResetScript();
    }

    state_entry() {
        clear();
        llSetTimerEvent( GI_Respawn_Time );
    }

    timer() {
        llSetTimerEvent( 0 );
        clear();
        state spawn;
    }
    
    changed( integer flag ) {
        parseChange( flag );
    }
}


