/*
// Cats makes the best programmers!  
// 
// FB HUD Rezzer and Target Selector for convo function
//
// 201908251950
//
//
*/


/*-------------DIALOG STUFF---------------*/
float GD_Rng = 5.0;
float GD_Ark = TWO_PI;

list GL_Buttons;
list GL_Subjects;

integer GL_Listen = -1;
/*----------------------------*/


float GF_ZOff = 1.75; // z offsetr of rezzed chat balls

string GS_Seek = "Convo Balls"; // used to find post balls if default named doesnt match
string GS_Ball = "Convo Balls v0.45";  // default name od pose balls to look for. should be updated in not found

integer GI_RLVChan = -1812221819; // RLV channel

key GK_Target = NULL_KEY; // target of chat



rezCmd( string cmd, key id ) {
    GK_Target = id;
    vector size = llGetAgentSize( llGetOwner() );
    float zAdj = GF_ZOff - size.z; 
    //llOwnerSay( (string)size );
    llRezAtRoot( 
                GS_Ball, 
                llGetPos()+(<1,0,zAdj>*llGetRot()), 
                ZERO_VECTOR, 
                llGetRot()*llEuler2Rot(<0,0,180>*DEG_TO_RAD), 
                1 
            );
}

/*  Find Pose Balls In Inventory  */
string getBall() {
    list names = [];
    integer len = llStringLength( GS_Seek )-1;
    integer i;
    integer num = llGetInventoryNumber( INVENTORY_OBJECT );
    for( i=0;i<num;++i ) {
        string name = llGetInventoryName( INVENTORY_OBJECT, i );
        if( llGetSubString( name, 0, len ) == GS_Seek ) {
            names += name;
        }
    }
    names = llListSort( names, 1, FALSE );
    return llList2String( names, 0 );
}

string catGetName( key id ) {
    string name = llGetDisplayName( id );
    if( name != "" ) {
        return name;
    } else if( (name = llKey2Name( id )) != "" ) {
        if( llGetSubString( name, -9, -1 ) == " Resident" ) {
            return llGetSubString( name, 0, -10 );
        }
        return name;
    }
    return "Unknown";
}



default {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        GS_Ball = getBall();
    }
    
    link_message( integer src, integer num, string msg, key id ) {
        if( id=="REZZER" ) {
            llSensor( "", "", AGENT, GD_Rng, GD_Ark );
        }
    }
    
    object_rez( key id ) {
        llRegionSayTo( GK_Target, GI_RLVChan, "FBSys,"+ (string)GK_Target +",@sit:"+ (string)id +"=force");
        GK_Target = NULL_KEY;
    }

    listen( integer chan, string name, key id, string msg ) {
        if( llGetOwnerKey(id) == llGetOwner() ) {
            integer index = llListFindList( GL_Buttons, [msg] );
            if( index != -1 ) {
                //llOwnerSay( "Hit: "+ msg +" "+ llList2String( GL_Subjects, index ) );
                rezCmd( msg, llList2Key( GL_Subjects, index ) );
                llListenRemove( GL_Listen );
            } else {
                llOwnerSay( "Rejected: "+ msg );
            }
        }
    }
    
    // found targets for chat
    sensor( integer num ) {
        vector pos = llGetPos();
        list data = [];
        integer i;
        for(i=0;i<num;++i) {
            list t = [llVecDist(pos,llDetectedPos(i)), llDetectedKey(i)];
            data += t;
        }
        data = llListSort( data, 3, TRUE );
        integer end = llGetListLength( data );
        if( end > 12 ) {
            end = 12;
        }
        list data2 = [];
        list data3 = [];
        for(i=0;i<end;i+=2) {
            key id = llList2Key( data, i+1 );
            string test = "#1 "+ catGetName(id);
            if( llStringLength(test) > 24 ) {
                test = llGetSubString( test,0,23 );
            }
            data2 += id;
            data3 += test;
        }
        
        GL_Buttons = data3;
        GL_Subjects = data2;
        
        llDialog( llGetOwner(), "T", GL_Buttons, 55 );
        llListenRemove( GL_Listen );
        GL_Listen = llListen( 55, "", "", "" );
    }
    
    // no target found for scan for chat targets
    no_sensor() {
        llOwnerSay( "No Target Found" );
    }
}

