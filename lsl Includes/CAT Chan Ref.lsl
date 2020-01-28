#ifndef INC_CHAN_REF
#define INC_CHAN_REF
/*
// 202001272322
*/
// LISTEN CHANNELS
integer GI_CHAN_INV = 2121; // used by spawn pads and item gives to give items to the inventory system

integer GI_CHAN_ALERT_SYS_COP = 814; // used for alert notifications
integer GI_CHAN_ALERT_SYS_FIR = 815; // used for alert notifications
integer GI_CHAN_ALERT_SYS_GEN = 813; // used for alert notifications

// LISTEN GENERATED DATA
// OVERHEAD HUD
integer GI_CHAN_OH_BASE = -100000; // set the minimum value
integer GI_CHAN_OH_RANGE = 100000; // set the range of values
// CHARACTER STAND
integer GI_CHAN_CS_BASE = -200000; // set the minimum value
integer GI_CHAN_CS_RANGE = 100000; // set the range of values



// Link Message flags
integer GI_LM_STAT_AUG = 666; // augment a stat in effects tracker
integer GI_LM_STAT_ADJ = 666; // set a stat in effects tracker

integer GI_LM_CONDITION = 700; // set or clear a condition

integer GI_LM_CORE_SUSTEM = 4; // used only to set min suspision
integer GI_LM_DISPLAY_STATS = 555;
integer GI_LM_DISPLAY_HP = 556;
integer GI_LM_DISPLAY_CASH = 557;

#endif
