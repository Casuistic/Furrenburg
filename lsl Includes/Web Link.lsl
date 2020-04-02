

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


// prep the verification key
string compileKey( string cmd, string data ) {
    return encode( llGetKey(), cmd, data );
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