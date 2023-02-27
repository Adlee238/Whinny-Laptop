// name: cameraInput.pde (version 1.2)
// desc: a webcam capture example that send OSC to wekinator
// author: Ge Wang (https://ccrma.stanford.edu/~ge/)
// data: Winter 2023
//
// NOTE: at 1280x720 resolution, downsampled by factor of 80 in both width and height
//       with further sample interval of 10, this currently sends 45 numbers
//       (15 sets of R G B value) to Wekinator as inputs
//
// NOTE: to observe the OSC messages send from here, close Wekinator app,
//       and run wek-monitor.ck:
//       > chuck wek-monitor.ck
//       to see the number of arguments as a result of changing the
//       sampleInterval or commonFactor here:
//       https://ccrma.stanford.edu/courses/356-winter-2023/code/wekinate/app/inputs/osc/wek-monitor.ck
//
// NOTE: when you are ready to send this to wekinator, make sure to first
//       close ChucK and miniAudicle and other Wekinator projects (to avoid
//       any port conflict on 6448)

import processing.video.*;
import oscP5.*;
import netP5.*;

// camera input
Capture cam;

// where to send message
NetAddress localhost = new NetAddress( "localhost", 6448 );

// we will use a common factor of the width and height and downsample
int commonFactor = 80;
// factor for further (naively) sampling the downsampled image
int sampleInterval = 8;

// initialization
void setup()
{
    // canvas size
    size( 1280, 720 );    
 
    // get list of available camers
    String[] cameras = Capture.list();

    // check list of cameras
    if( cameras.length == 0 )
    {
        println("There are no cameras available for capture.");
        exit();
    }
    else
    {
        println( "available cameras:" );
        for( int i = 0; i < cameras.length; i++ )
        { println(cameras[i]); }
    
        // the camera can be initialized directly using an 
        // element from the array returned by list():
        cam = new Capture( this,  width, height, cameras[0] );
        // start the camera
        cam.start();
    }
}

void draw()
{
    // read camera
    if (cam.available() == true)
    {
        cam.read();
    }

    // draw the image
    image(cam, 0, 0);
    // get the image
    PImage img = get();
    // resize by commonFactor in each dimension
    img.resize( width / commonFactor, height / commonFactor );

    // make a new OSC message for sending
    OscMessage msg = new OscMessage("/wek/inputs");

    // loop over nubmer of pixels after the downsampling, skipping by sampleInterval
    // this further naively samples the downsampled image (naively means we aren't
    // taking its neighboring pixels into account)
    for( int i = 0; i < img.pixels.length; i += sampleInterval )
    {
        // add pixel RGB values
        msg.add( red( img.pixels[i] ) );
        msg.add( green( img.pixels[i] ) );
        msg.add( blue( img.pixels[i] ) );
    }

    // send (one of several ways to send; this way does so without a OscP5 instance,
    // which would require a listening port; we don't need or want as it ties up that port)
    OscP5.flush( msg, localhost );
}
