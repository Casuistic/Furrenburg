#ifdef DEBUG
debug( string text ) {
    llOwnerSay(text);
}
#else
#define debug(dummy)
#endif
