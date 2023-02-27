//----------------------------------------------------------------------------
/*  2-parameter whinny computer sounds by Andrew Lee
    wekinator mod by Rebecca Fiebrink (2009-2015)
    updated by Ge Wang (2023)
    
    USAGE: This example receives Wekinator "/wek/outputs/" messages
    over OSC and maps incoming parameters to musical parameters;
    This example is designed to run with a sender, which can be:
    1) the Wekinator application, OR
    2) another Chuck/ChAI program containing a Wekinator object
    
    This model expects to receive 2 continuous parameters in the
    range [0,1]; these parameters are mapped to musical parameters
    in map2sound().
	
    SOUND: this uses Bowed

    This model is "always on" -- no note triggering with keyboard
    
    expected parameters for this class are:
    0 = volume
    1 = pitch
*/
//----------------------------------------------------------------------------

// create our OSC receiver
OscIn oscin;
// a thing to retrieve message contents
OscMsg msg;
// use port 12000 (default Wekinator output port)
12000 => oscin.port;

// listen for "/wek/output" message with 2 floats coming in
oscin.addAddress( "/wek/outputs, ff" );
// print
<<< "listening for OSC message from Wekinator on port 12000...", "" >>>;
<<< " |- expecting \"/wek/outputs\" with 2 continuous parameters...", "" >>>; 

// synthesis patch
Bowed bar => Gain g => dac;

// set defaults 
0.5 => bar.bowPressure;
0.5 => bar.bowPosition;
0.5 => bar.volume;
60 => Std.mtof => bar.freq;

// expecting 2 output dimensions
2 => int NUM_PARAMS;
float myParams[NUM_PARAMS];

// envelopes for smoothing parameters
// (alternately, can use slewing interpolators; SEE:
// https://chuck.stanford.edu/doc/examples/vector/interpolate.ck)
Envelope envs[NUM_PARAMS];
for( 0 => int i; i < NUM_PARAMS; i++ )
{
    envs[i] => blackhole;
    .5 => envs[i].value;
    10::ms => envs[i].duration;
}

// set the latest parameters as targets
// NOTE: we rely on map2sound() to actually interpret these parameters musically
fun void setParams( float params[] )
{
    // make sure we have enough
    if( params.size() >= NUM_PARAMS )
    {		
        // adjust the synthesis accordingly
        0.0 => float x;
        for( 0 => int i; i < NUM_PARAMS; i++ )
        {
            // get value
            params[i] => x;
            // clamp it
            if( x < 0 ) 0 => x;
            if( x > 1 ) 1 => x;
            // set as target of envelope (for smoothing)
            x => envs[i].target;
            // remember
            x => myParams[i];
        }
    }
}

// function to map incoming parameters to musical parameters
fun void map2sound()
{
    // time loop
    while( true )
    {
        // FYI envs[i] are used for smoothing param values
        envs[0].value() => bar.volume;
        envs[1].value() * 100 + 20 => Std.mtof => bar.freq;
        
        // time
        10::ms => now;
    }
}

// turn volume off!
fun void soundOff()
{
    bar.noteOff;      
}

// turn volume on!
fun void soundOn()
{
    //<<< "SOUUUUUUUND">>>;
    0.5 => bar.startBowing;
    0.8 => bar.noteOn;
}	

fun void waitForEvent()
{
    // array to hold params
    float p[NUM_PARAMS];

    // infinite event loop
    while( true )
    {
        // wait for OSC message to arrive
        oscin => now;

        // grab the next message from the queue. 
        while( oscin.recv(msg) )
        {
            // print stuff
            cherr <= msg.address <= " ";
            
            // unpack our 5 floats into our array p
            for( int i; i < NUM_PARAMS; i++ )
            {
                // put into array
                msg.getFloat(i) => p[i];
                // print
                cherr <= p[i] <= " ";
            }
            
            // print
            cherr <= IO.newline();
            
            // set the parameters
            setParams( p );
        }
    }
}

// spork osc receiver loop
spork ~waitForEvent();
// spork mapping function
spork ~ map2sound();	
// turn on sound
soundOn();

// time loop to keep everything going
while( true ) 1::second => now;
