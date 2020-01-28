#undef DEBUG
#include <debug.lsl>
#include <oups.lsl> // debugging
string GS_Script_Name = "CAT Alert Cliant"; // debugging


#include <CAT Filters.lsl>
#include <CAT Chan Ref.lsl> // link message chan ref





integer GI_Link_Alert = 0; // set by script. leave as 0 here
// GI_CHAN_ALERT_SYS_COP = 814; // used for alert notifications
// GI_CHAN_ALERT_SYS_FIR = 815; // used for alert notifications
// GI_CHAN_ALERT_SYS_GEN = 813; // used for alert notifications

string GS_Alert_Sound = "40c552ae-1c62-2da4-da43-b015b7bd0527";

list GL_Alert_Pos = [
    <0.2,0.0,0.65>,
    <-0.2,0.0,0.65>
];

list GL_Alerts_Flag = [
        "PD SEVEN",
        "PD CHEERS",
        "PD DONUT",
        "PD GAS",
        "PD EAGLE",
        "PD BUS",
        "PD BANK",
        "PD HALL",
        "PD MUSIC",
        "PD GUN",
        "PD POST",
        "PD DOCK"
];

list GL_Alerts_Info = [
        "Alarm Triggered at the 7/11. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Cheers. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Mr. Donut. Dispatching Unit to Investigate.",
        "Alarm Triggered at WN Auto Repair. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Spread Eagle. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Bus Stop in Lower Furrenburg. Dispatching Unit to Investigate.",
        "Alarm Triggered at the 1st Bank of Furrenburg. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Town Hall. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Music Store. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Gun Store. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Post Office. Dispatching Unit to Investigate.",
        "Alarm Triggered at the Docks. Dispatching Unit to Investigate."
];






map() {
    integer i;
    integer num = llGetNumberOfPrims();
    for( i=2; i<=num; ++i ) {
        string name = llToUpper( llGetLinkName( i ) );
        if( name == ".ALERT" ) {
            GI_Link_Alert = i;
        }
    }
}


alert( integer index ) {
    llSetLinkPrimitiveParamsFast( GI_Link_Alert, [PRIM_POS_LOCAL, llList2Vector( GL_Alert_Pos, 1 )] );
    llOwnerSay( llList2String( GL_Alerts_Info, index ) );
    llPlaySound(GS_Alert_Sound,1);
    llSetTimerEvent( 15 );
}




default {
    state_entry() {
        safeLoad();
        map();
        llListen( GI_CHAN_ALERT_SYS_COP, "", NULL_KEY, "" );
        llSetTimerEvent( 0.1 );
    }

    timer() {
        llSetTimerEvent( 0 );
        llSetLinkPrimitiveParamsFast( GI_Link_Alert, [PRIM_POS_LOCAL, llList2Vector( GL_Alert_Pos, 0 )] );
    }

    listen(integer channel, string name, key id, string msg ) {
        if( !isGroup( id ) ) {
            return;
        }
        integer index = llListFindList( GL_Alerts_Flag, [msg] );
        if( index != -1 ) {
            alert( index );
        }
    }
}
