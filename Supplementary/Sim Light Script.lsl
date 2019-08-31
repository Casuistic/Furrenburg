integer GV_Chan = -995533; // channel to listen for

list proj = [1]; // light projector prim

list frame = [1]; // glow prim
list GL_Frame_Faces = [1]; // faces to make glow

list GL_Light_Data = [<1,1,0.5>, 1, 20, 0.75]; // projected light info

vector GV_Frame_On = <1.0,1.0,0.5>; // bulb colour when on
vector GV_Frame_Off = <0.15,0.15,0.075>; // bulb colour when off

float GF_Frame_On_Glow = 0.1; // glow level when on
float GF_Frame_Off_Glow = 0.0; // glow level when off



setLight( integer on, vector col, float glow ) {
    integer e;
    integer qnt = llGetListLength( proj );
    for( e=0; e<qnt; ++e ) {
        llSetLinkPrimitiveParamsFast( llList2Integer(proj, e), [PRIM_POINT_LIGHT, on] + GL_Light_Data );
    }
    for( e=0; e<qnt; ++e ){
        integer i;
        integer num = llGetListLength( GL_Frame_Faces );
        for( i=0; i<num; ++i ) {
            integer face = llList2Integer(GL_Frame_Faces,i);
            llSetLinkPrimitiveParamsFast( llList2Integer( frame, e ), [
                    PRIM_COLOR, face, col, 1,
                    PRIM_GLOW, face, glow,
                    PRIM_FULLBRIGHT, face, on
                ]);
        }
    }
}

default {
    on_rez( integer peram ) {
        llResetScript();
    }
    
    state_entry() {
        llListen( GV_Chan, "Light Comm", "", "ON" );
        llListen( GV_Chan, "Light Comm", "", "OFF" );
    }

    listen( integer chan, string name, key id, string msg  ) {
        if( llGetOwnerKey( id ) != llGetOwner() ) {
            return;
        }
        if( msg == "ON" ) {
            setLight( TRUE, GV_Frame_On, GF_Frame_On_Glow );
        } else {
            setLight( FALSE, GV_Frame_Off, GF_Frame_Off_Glow );
        }
    }
}
