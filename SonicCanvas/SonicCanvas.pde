//import libraries
import ddf.minim.*;
import ddf.minim.signals.*;
import ddf.minim.analysis.*;
import java.io.File;
import fullscreen.*;

FullScreen fs;

//define size of screen
int width = 1024;
int height = 768;
//constants
float pi=3.14159265;

int MY_SRATE = 22050;
int WINDOW_SIZE = 1024;

//global variables
//audio
Minim minim;
AudioInput in;
AudioRecorder recorder;
AudioPlayer player;
FFT fft;

//effects
DelayEffect delayEff;
SinEffect sinEff;

LevelFollower x_level;

//-------untouchable line---------------

//position of paintbrush
float x_acc=0;
float y_acc=0;
float x_pos=0;
float y_pos=0;
float x_vel=5;
float y_vel=5;
int x_dir=1;
int y_dir=1;
float speed=5;
float direction=0;
float e;
int time=0;
int time_record_start=0;
//mondrian globals
int mondrianNos=0;
int mondrianMax=50;
color MondrianColors[] = new color[10];

//mean value of color of paintbrush
float r=125,g=125,b=125,a=150;

//position and size of aquarium
mondrian[] shapes;

void setup()
{  
  //colors
  MondrianColors[0] = #FFFFFF; //black
  MondrianColors[1] = #FFC125; //yellow
  MondrianColors[2] = #DB2929; //red
  MondrianColors[3] = #1E90FF; //blue
  MondrianColors[4] = #380474; //purple
  MondrianColors[5] = #DF2949; //red=purp
  MondrianColors[6] = #EE4000; //orange
  MondrianColors[7] = #1B3F8B; //blue
  MondrianColors[8] = #004F00; //green
  MondrianColors[9] = #000000; //white
  
  //audio
  minim = new Minim(this);
  minim.debugOn();
  
  // get a line in from Minim, default bit depth is 16
  in = minim.getLineIn(Minim.MONO, WINDOW_SIZE, MY_SRATE);
  recorder = minim.createRecorder(in, "myrecording0.wav", true);
  player = minim.loadFile("myrecording.wav", WINDOW_SIZE);

  delayEff = new DelayEffect();
  sinEff = new SinEffect();
  
  //display
  size(width, height, P3D);
  frameRate(15);
  smooth();
  background(255);
  fill(0);
  stroke(0);
  shapes = new mondrian[mondrianMax];  
  
  x_level = new LevelFollower();

  //level followers
  x_level.setTau(0.5,MY_SRATE/WINDOW_SIZE);
  
  fs = new FullScreen(this);
  //fs.enter();
  
  mondrianDefault();
  
}

void draw()
{ 
  //update time and clear slowly
  time++;
  pos_update(1);
  time%=1073741824;
  if (time%100==0)
  {
    //clear history slowly
    strokeWeight(0);
    fill(255,255,255,50);
    rect(0,0,width,height);
  }
  //------------------------------------------
  //get centroid and energy

  float cent = centroid(in.mix.toArray());
  cent = x_level.process(cent);
  float energy = energy(in.mix.toArray());

  //------------------------------------------  
  //set velocity

  direction=(cent-750)*6.5/1000;
//  println(direction);

  x_vel = x_dir*speed*sin(direction);
  y_vel = y_dir*speed*cos(direction);

//------------------------------------------ 
  float eThreshold = 0.01;
  
  strokeWeight(50);
  //if above thereshold
  if (energy>eThreshold)
  {
     //draw stroke
     stroke(255,255,0,0);
     drawSpectrogram(x_pos,y_pos,min(60,(20+5*e)),min(40,(15+5*e)),atan(y_vel/x_vel));
     //record only if energy greater than threshold
     if (!player.isPlaying() && !recorder.isRecording())
        recorder.beginRecord();
  }
  else
  {
     //stop recording
     if (recorder.isRecording())
      recorder.endRecord();
     if (random(1)<0.01)
       x_dir*=-1;
     if (random(1)<0.01)
       y_dir*=-1;
   }
//------------------------------------------ 
  //possibly create a new shape
  if (energy>eThreshold && mondrianNos < mondrianMax && random(1)<0.02 && (time - time_record_start) > 100)
  {
    //parametrize this
    float newsize = min(random(220,300),(time - time_record_start)/2);
    boolean far=true;
    //avoid overlap
    for (int i=0;i<mondrianNos && far;i++)
    { 
      float x_diff = abs(width-x_pos-shapes[i].x_pos);
      float y_diff = abs(height-y_pos-shapes[i].y_pos);
      float maxsize = max(newsize,shapes[i].sizesq);
      if (x_diff < 0.9*maxsize && y_diff < 0.9*maxsize)
        far = false;
    }
    if (far)
    {     
        recorder.endRecord();
        recorder.save();  
        shapes[mondrianNos++] = new mondrian(width-x_pos,height-y_pos,newsize,MondrianColors[int(random(0,9))]);    
        time_record_start = time;
        recorder = minim.createRecorder(in, "myrecording"+Integer.toString(mondrianNos)+".wav", true);
        recorder.beginRecord();
    }  
  }

  //------------------------------------------ 
  //reset state if mondrian nos exceeded
  
  if (mondrianNos == mondrianMax)
  {
    clear();
  }  
  
  //------------------------------------------ 
  //play if inside shape
  for (int i=0;i<mondrianNos;i++) 
  {
    //draw
    shapes[i].draw(in.mix.toArray());
    //play if inside
    if (shapes[i].isInside(x_pos,y_pos))
    {
      if (!player.isPlaying())
      {
        if (recorder.isRecording())
          recorder.endRecord();
//      println("playing :"+Integer.toString(i));
      player = minim.loadFile("myrecording"+Integer.toString(i)+".wav", WINDOW_SIZE);
      float prob=random(1);
      if (prob > 0.5)
        player.addEffect(delayEff);
      if (prob > 0.9)
        player.addEffect(sinEff);
      player.play();
      }
    }
  }
//------------------------------------------
}

void stop()
{
  // always close Minim audio classes when you are done with them
  in.close();
  minim.stop();
  super.stop();
}



//run physics engine
void pos_update(float t)
{    //bounds
    x_pos=x_pos+x_vel*t+x_acc*t*t;
    y_pos=y_pos+y_vel*t+y_acc*t*t;
    
    x_vel+=x_acc;
    y_vel+=y_acc;    

    if (x_pos>width && x_vel>0)
      x_pos-=width;
    if (y_pos>height && y_vel>0)
      y_pos-=height;
    if (x_pos<0 && x_vel<0)
      x_pos+=width;
    if (y_pos<0 && y_vel<0)
      y_pos+=height;
}


void changeAccel(float dx, float dy)
{
  x_acc+=dx;
  y_acc+=dy;
}

void changeVel(float dx, float dy)
{
  x_vel+=dx;
  y_vel+=dy;
}


void clear()
{
  background(255);
  for (int i=0;i<mondrianNos;i++)
  {
    File f = new File("myrecording"+i+".wav");
    if (f.exists()) 
    {
      f.delete();
     }
    
  }
  mondrianNos=0;  
  mondrianDefault();
}

void mondrianDefault()
{
  mondrianNos=6;  
  shapes[0] = new mondrian(0.5*height,0.5*width,random(50,70),MondrianColors[int(random(0,9))]);    
  shapes[1] = new mondrian(0.9*height,0.3*width,random(50,70),MondrianColors[int(random(0,9))]);    
  shapes[2] = new mondrian(0.2*height,0.7*width,random(50,70),MondrianColors[int(random(0,9))]);    
  shapes[3] = new mondrian(0.3*height,0.8*width,random(50,70),MondrianColors[int(random(0,9))]);    
  shapes[4] = new mondrian(0.9*height,0.2*width,random(50,70),MondrianColors[int(random(0,9))]);    
  shapes[5] = new mondrian(0.5*height,0.1*width,random(50,70),MondrianColors[int(random(0,9))]);    
}

