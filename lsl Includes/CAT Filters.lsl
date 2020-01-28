#ifndef INC_FILTERS
#define INC_FILTERS
/*
// 202001272322
*/

key GK_GB_Group = "3e895a38-75a3-c112-3f52-8b1451e97e25"; // FB group uuid

integer isGroup( key id ) {
    key group = llList2Key( llGetObjectDetails( id, [OBJECT_GROUP] ), 0 );
    return( group == GK_GB_Group ); // FB group
}


integer isKey( key id ) {
    return( llGetOwnerKey(id) != NULL_KEY );
}


integer isUserSafe( key id ) {
    return( llGetOwnerKey(id) == llGetOwner() );
}

#else
// no idea why this wanring doesnt work
// REDUNDANT INCLUDE __FILE__ 
#warning Redundant Include INC_FILTERS __FILE__
#endif
