#ifndef REPORT
    #define report(dummy)

#else
    #ifndef INC_REPORT
        #define INC_REPORT
        integer GI_Rep_Chan = 9090;
        report( string text ) {
            llShout( GI_Rep_Chan, "RP: "+ text );
        }
    
    #endif

#endif
