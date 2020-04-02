#ifndef DEBUG
    #define debug(dummy)

#else
    #ifndef INC_DEBUG
    #define INC_DEBUG
        debug( string text ) {
            llOwnerSay( "DB: "+ text);
        }

    #endif

#endif
// END OF FILE
