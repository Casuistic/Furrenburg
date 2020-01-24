#ifdef REPORT
integer GI_Rep_Chan = 9090;
report( string text ) {
    llShout( GI_Rep_Chan, text );
}
#else
#define report(dummy)
#endif
