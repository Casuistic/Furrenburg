#ifndef INC_ENCODE
#define INC_ENCODE
/*
// 202001272322
*/

#include <CAT Encode.lsl>
#include <CAT Chan Ref.lsl> // link message chan ref



string GS_Salt = "CAT_SPAWN_PAD!"; // salt for verification code // used by external devices

string GS_Salt_Data = "GS_Salt"; // used in hud storage




/////////////////
//  FUNCTIONS  //
/////////////////
// uuid to integer
integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}


string encode( key id, string cmd, string data ) {
    integer mark = key2Chan(id,1000000,1000000);
    string text = llXorBase64( llStringToBase64( llMD5String( GS_Salt+cmd+data, mark ) ), llIntegerToBase64(mark) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}

// encode data for storage in hud
// used to store character data in prim desc
string encodeStoreData( key id, string text ) {
    integer mark = key2Chan(id,1000000,1000000);
    string text = llXorBase64( llStringToBase64( GS_Salt_Data + text ), llIntegerToBase64(mark) );
    if( llStringLength( text ) < 15 ) {
        text += llGetSubString( "qwertyuiopasdfg", 0, 14-llStringLength(text) );
    } else if( llStringLength( text ) > 15 ) {
        text = llGetSubString( text, 0, 14 );
    }
    return text;
}

// verify stored data
// used in hud to verify stored character data
integer verifyStoreData( key id, string str1, string str2 ) {
    return( encodeStoreData( id, str1 ) == str2 );
}



// prep the verification key
string compileKey( string cmd, string data ) {
    return encode( llGetKey(), cmd, data );
}


integer doRawInvCmd( key id, string cmd, string data, string flag ) {
    string json_d = llList2Json( JSON_ARRAY, [cmd , data, compileKey( cmd, data ), flag] );
    if( JSON_INVALID == json_d ) {
        return FALSE;
    }
    string line = "FB:"+ json_d;
    llRegionSayTo( id, GI_CHAN_INV, line );
    return TRUE;
}


string json( string jObj, string index, string val ) {
    string jObj = llJsonSetValue( GS_JSON_Data, [index], val );
    //GS_JSON_Data =jObj;
    return jObj;
}


string jsonArr( string jObj, string index, integer num, string val ) {
    string jObj = llJsonSetValue( GS_JSON_Data, [index,num], val );
    //GS_JSON_Data = Obj;
    return jObj;
}


integer validSecKey( key id, string cmd, string data, string secKey ) {
    return encode( id, cmd, data ) == secKey;
}


// used to generate verification flag
string ranStr( integer length ) {
    string chars = "1234567890abcdefghijklmnopqrstuvwxyz";
    integer len = llStringLength( chars );
    string output;
    integer i;
    integer index;
    do {
       index = (integer) llFrand(len);
       output += llGetSubString(chars, index, index);
    } while( ++i < length );                                                    
    return output;
}




sendClearItems( key id, list items, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, items );
    string secKey = encode( llGetKey(), "IClr", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["IClr", jobj, secKey, flag] );
    llRegionSayTo( id, GI_CHAN_INV, line );
}


sendInvReq( key id, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, ["NA"] );
    string secKey = encode( llGetKey(), "IChk", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["IChk", jobj, secKey, flag] );
    llRegionSayTo( id, GI_CHAN_INV, line );
}


sendCashCheck( key id, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, ["NA"] );
    string secKey = encode( llGetKey(), "CChk", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["CChk", jobj, secKey, flag] );
    llRegionSayTo( id, GI_CHAN_INV, line );
}


sendPayReq( key id, integer val, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, [val] );
    string secKey = encode( llGetKey(), "CPay", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["CPay", jobj, secKey, flag] );
    llRegionSayTo( id, GI_CHAN_INV, line );
}


sendCash( key id, integer val, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, [val] );
    string secKey = encode( llGetKey(), "CMod", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["CMod", jobj, secKey, flag] );
    llRegionSayTo( id, GI_CHAN_INV, line );
}






// ack or nack inventory actions
ack( key id, integer chan, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, ["NA"] );
    string secKey = encode( llGetKey(), "ACK", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["ACK", jobj, secKey, flag] );
    debug( "Sending ACK: "+ line );
    llRegionSayTo( id, chan, line );
    //llRegionSayTo( id, chan, "FB:ACK:"+ flag );
}

ack_d( key id, integer chan, list data, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, data );
    string secKey = encode( llGetKey(), "ACK", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["ACK", jobj, secKey, flag] );
    debug( "Sending ACK: "+ line );
    llRegionSayTo( id, chan, line );
    //llRegionSayTo( id, chan, "FB:ACK:"+ flag );
}

// ack or nack inventory actions
nak( key id, integer chan, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, ["NA"] );
    string secKey = encode( llGetKey(), "NAK", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["NAK", jobj, secKey, flag] );
    llRegionSayTo( id, chan, line );
    //llRegionSayTo( id, chan, "FB:NAK:"+ flag );
}

nak_d( key id, integer chan, list data, string flag ) {
    string jobj =  llList2Json( JSON_ARRAY, data );
    string secKey = encode( llGetKey(), "NAK", jobj );
    string line =  "FB:"+ llList2Json( JSON_ARRAY, ["NAK", jobj, secKey, flag] );
    llRegionSayTo( id, chan, line );
    //llRegionSayTo( id, chan, "FB:NAK:"+ flag );
}

#endif
