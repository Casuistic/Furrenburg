
key GK_GB_Group = "3e895a38-75a3-c112-3f52-8b1451e97e25"; // FB group uuid
integer isGroup( key id ) {
    key group = llList2Key( llGetObjectDetails( id, [OBJECT_GROUP] ), 0 );
    return( group == GK_GB_Group ); // FB group
}



