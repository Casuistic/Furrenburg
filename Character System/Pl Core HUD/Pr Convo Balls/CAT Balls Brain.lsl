/*
// Cats makes the best programmers!  
// 
// Brain Script to handle rezzing death and RLV commands of paired pose balls
//
// 201908251950
//
//
*/



integer GI_Conc_Chan = -55;



setup() {
    llListen( GI_Conc_Chan, "", "", "DIE" );
}

doDie() {
    if( llGetStartParameter() != 0 ) {
        llDie();
    } else {
        llOwnerSay( "DEBUG DIE" );
    }
}

list findSitters() {
    integer i;
    integer num = llGetNumberOfPrims();
    list keys = [];
    for( i=1; i<=num; ++i ) {
        key id = llAvatarOnLinkSitTarget(i);
        if( id != NULL_KEY ) {
            keys += id;
        }
    }
    return keys;
}



default {
    on_rez( integer peram ) {
        llSetTimerEvent( 0 );
    }

    state_entry() {
        setup();
    }
    
    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey(id) == llGetOwner() ) {
            if( msg == "DIE" ) {
                llMessageLinked( LINK_SET, 5, "RELEASE", "RELEASE" );
                llSetTimerEvent( 5 );
            }
        } else if( llListFindList( findSitters(),  [llGetOwnerKey(id)] ) != -1 ) {
            if( msg == "DIE" ) {
                llMessageLinked( LINK_SET, 5, "RELEASE", "RELEASE" );
                llSetTimerEvent( 5 );
            }
        }
    }
    
    changed( integer flag ) {
        if( flag & CHANGED_LINK ) {
            integer i;
            integer num = llGetNumberOfPrims();
            for(i=1;i<=num;++i) {
                if( llAvatarOnLinkSitTarget(i) != NULL_KEY ) {
                    return;
                }
            }
            doDie();
        }
    }
    
    timer() {
        llSetTimerEvent( 0 );
        doDie();
    }
}
