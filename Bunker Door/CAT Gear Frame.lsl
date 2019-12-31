/*
*   Bunker Gear Door crappy rezzer script 
*
*
*   201912301700
*   201912310711
*/



integer GI_Chan = 1000;
integer GI_Chan_Base = 42;

integer key2Chan ( key id, integer base, integer rng ) {
    integer sine = 1;
    if( base < 0 ) { sine = -1; }
    return (base+(sine*(((integer)("0x"+(string)id)&0x7FFFFFFF)%rng)));
}

integer genChan() {
    integer offset = (integer)llGetObjectDesc();
    integer number = key2Chan( llGetOwner(), 499999, 500000 );
    integer chan = offset + number;
    if( chan == 0 ) {
        chan = number - offset;
        if( chan == 0 ) {
            chan = number;
        }
    }
    llOwnerSay( "Active Chan: "+ (string)chan );
    return chan;
}

integer genBaseChan() {
    integer chan = (integer)llGetObjectDesc();
    if( chan == 0 ) {
        chan = 42;
    }
    return chan;
}




default {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry( ) {
        GI_Chan_Base = genBaseChan();
        llListen( GI_Chan_Base, "", "", "Need Ref" );
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( msg == "Need Ref" ) {
            llOwnerSay( "Giving Ref To: '"+ name +"'" );
            llRegionSayTo( id, chan, "SetRef" );
        }
    }
}
