integer GI_Chan = -1;
integer GI_Listen = -1;

// uuid to integer
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
    state_entry() {
        GI_Chan = genChan();
        GI_Listen = llListen( GI_Chan, "", "", "" );
        
    }

    listen( integer chan, string name, key id, string msg ) {
        llSay(0, name +": "+ msg );
    }
}
