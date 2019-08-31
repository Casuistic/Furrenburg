integer GV_Chan = -995533; // channel to listen for

integer GI_On = 0;

list GL_Cmd = [ "OFF", "ON" ];

default {
    touch_start(integer num) {
        GI_On = llAbs( GI_On - 1 );
        llRegionSay( GV_Chan, llList2String( GL_Cmd, GI_On ));
    }
}
