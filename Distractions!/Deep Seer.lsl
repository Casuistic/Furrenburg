string url;
key urlRequestId;
 

list GL_Store;


string HTML_Top = "<!DOCTYPE html><html><body style=\"background-color:#666666\">";

string HTML_Bot = "</body></html>";

string GS_Canvas = "<div margin-left='auto' margin-right='auto'>
<canvas id='myCanvas' width='200' height='200'></canvas><br/>
</div>";

string GS_Java = "
<script>
var canvas = document.getElementById(\"myCanvas\");
var ctx = canvas.getContext(\"2d\");
ctx.fillStyle = \"black\";
ctx.fillRect(0, 0, canvas.width, canvas.height);

var store = document.getElementById(\"data\");
var data = store.innerHTML;
store.innerHTML = \"pre\";
var arr = data.split( \",\" );
store.innerHTML = \"past\";

var tile = 5;
var range = 25;
var lx = 40;
var ly = 40;
var x;
var y;

var sx = (lx-1) * tile;
var sy = (ly-1) * tile;

var col = [";

string GS_Java_2 = "];
store.innerHTML = col.length;
for( y=0; y<ly; ++y ){
    for( x=0; x<lx; ++x ) {
        var n = arr[(y*ly)+x];
        if( n >= 0 ) {
            var m = Math.floor(((n/100)/range)*col.length);
            store.innerHTML += n +\"<br/>\";
            ctx.fillStyle = ctx.fillStyle = col[m];
            ctx.fillRect( (y*tile), sx-(x*tile), tile, tile );
        }
    }
}
store.innerHTML = col.length;
var img = canvas.toDataURL(\"image/png\");
document.write('<img src=\"'+img+'\"/>');
</script>";



scan() {
    GL_Store = [];
        integer x;
        integer y;
        integer nox = 40;
        integer noy = 40;
        integer ex = nox;
        integer ey = noy;
        float range = 25;
        rotation rot = llGetRot();
        vector pos = llGetPos();
        vector mod = <1,0,0>;
        vector start = <-45,-45,0>;
        float sx = 90.0 / (nox-1);
        float sy = 90.0 / (noy-1);
        list items;
        for( y=0; y<ey; ++y ) {
            for( x=0; x<ex; ++x ) {
                float v1 = (start.x + (sx*x));
                float v2 = (start.y + (sy*y));
                rotation mrot = llEuler2Rot( <0,v1,v2> * DEG_TO_RAD );
                vector m = mod * (mrot*rot);
                vector e = m * range;
                list data = llCastRay( pos + m, pos + e, [RC_MAX_HITS, 1] );
                integer code = llList2Integer( data, -1 );
                if( code <= 0 ) {
                    // missed
                    items += -1;
                } else {
                    //llRezObject( "Object", llList2Vector( data, 1 ), ZERO_VECTOR, ZERO_ROTATION, 1 );
                    items += 
                    //llKey2Name(llList2Key( data, 0 ) ) +" "+ (string)
                    ((integer)llFloor(llVecDist( pos, llList2Vector( data, 1 ) )*100));
                }
                //llRezObject( "Object", pos+e, ZERO_VECTOR, ZERO_ROTATION, 1 );
                //llOwnerSay( llDumpList2String( data, "," ) );
            }
            llSetText( "Progress: "+ (string)((integer)llFloor(((float)y)/ey*100)) +"%", <1,1,1>, 1 );
        }
        llSetText( "Done!", <1,1,1>, 1 );
        GL_Store = items;
}


default {
    state_entry() {
        urlRequestId = llRequestURL();
        integer a;
        integer b;
        list char = [0,1,2,3,4,5,6,7,8,9,"a", "b", "c", "d", "e", "f"];
        list out = [];
        for( a=0; a<16; ++a ) {
            for( b=0; b<16; ++b ) {
                out += "\"#"+ llList2String( char, a ) + llList2String( char, b ) +"0022\"";
            }
        }
        GS_Java += llDumpList2String( out, ",\n" );
        out = [];
        GS_Java += GS_Java_2;
        GS_Java_2 = "";
    }

    on_rez(integer start_param) {
        llResetScript();
    }
 
    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            llResetScript();
        }
        if (change & (CHANGED_REGION | CHANGED_REGION_START | CHANGED_TELEPORT)) {
            urlRequestId = llRequestURL();
        }
    }
 
    http_request(key id, string method, string body) {
        if (id == urlRequestId) {
            if (method == URL_REQUEST_DENIED) {
                llOwnerSay("The following error occurred while attempting to get a free URL for this device:\n \n" + body);
            } else if (method == URL_REQUEST_GRANTED) {
                url = body;
                llMessageLinked( LINK_SET, 5, url, "SET URL" );
            }
        }else if (method == "GET") {
            llSetContentType( id, CONTENT_TYPE_HTML );
            string output = HTML_Top;
            
            output += GS_Canvas;
            
            output += "<div id=\"data\" style=\"background-color:#fff\" word-wrap=\"break-word\">";
            output += llDumpList2String( GL_Store, ", " ) +"<br/>";
            output += "</div>";

            output += GS_Java;

            output += HTML_Bot;
            llHTTPResponse(id,200, output );
        } else {
            llHTTPResponse(id,405,"Unsupported method.");
        }
    }

    touch_start( integer num ) {
        llSay( 0, "Starting Scan" );
        scan();
        llSay( 0, "Scan Compleat" );
        llLoadURL( llDetectedKey( 0 ), "See Scan Map", url );
    }

}
