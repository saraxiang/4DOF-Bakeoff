import java.util.ArrayList;
import java.util.Collections;
import java.lang.*;
import processing.sound.*;

//these are variables you should probably leave alone
int index = 0;
int trialCount = 8; //this will be set higher for the bakeoff
float border = 0; //have some padding from the sides
int trialIndex = 0; //what trial are we on
int errorCount = 0;  //used to keep track of errors
float errorPenalty = 0.5f; //for every error, add this to mean time
int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;

final int screenPPI = 72; //what is the DPI of the screen you are using
//you can test this by drawing a 72x72 pixel rectangle in code, and then confirming with a ruler it is 1x1 inch. 

//These variables are for my example design. Your input code should modify/replace these!
float screenTransX = 0;
float screenTransY = 0;
float screenRotation = 0;
float screenZ = 50f;

float prevMouseX = 0;
float prevMouseY = 0;
int phaseNum = 0;

int ROTATION_AND_ZOOM_PHASE = 0;
int MOVE_PHASE = 1;
int BACK_1 = -1;
int BACK_2 = -2;

float prevX;
float prevY;
Target t;
float targetX;
float targetY;

// correct dot properties
float cdotX;
float cdotY;

boolean controllerFlash;
boolean backgroundFlash;
int change; // counter for flash delay

// correct sound
String alertPath = "/Users/tianjunma/Documents/Academic/F17/05-391/4DOF-Bakeoff/processing/bakeoff4DOF/alert.mp3";
String correctPath = "/Users/tianjunma/Documents/Academic/F17/05-391/4DOF-Bakeoff/processing/bakeoff4DOF/correct.wav";
SoundFile correct = new SoundFile(this, correctPath);
SoundFile alert = new SoundFile(this, alertPath);

boolean play = false;
boolean inplay = false;

boolean hovered = false;
boolean showBack = false;

private class Target
{
  float x = 0;
  float y = 0;
  float rotation = 0;
  float z = 0;
}

ArrayList<Target> targets = new ArrayList<Target>();

float inchesToPixels(float inch)
{
  return inch*screenPPI;
}

void setup() {
  size(700,700); 

  rectMode(CENTER);
  textFont(createFont("Arial", inchesToPixels(.2f))); //sets the font to Arial that is .3" tall
  textAlign(CENTER);

  //don't change this! 
  border = inchesToPixels(.3f); //padding of 0.3 inches

  prevX = (float)mouseX;
  prevY = (float)mouseY;

  for (int i=0; i<trialCount; i++) //don't change this! 
  {
    Target t = new Target();
    t.x = random(-width/2+border, width/2-border); //set a random x with some padding
    t.y = random(-height/2+border, height/2-border); //set a random y with some padding
    t.rotation = random(0, 360); //random rotation between 0 and 360
    int j = (int)random(20);
    t.z = ((j%20)+1)*inchesToPixels(.15f); //increasing size from .15 up to 3.0" 
    targets.add(t);
    println("created target with " + t.x + "," + t.y + "," + t.rotation + "," + t.z);
  }

  Collections.shuffle(targets); // randomize the order of the button; don't change this.
}

void draw() {

  if (backgroundFlash) {
    if (change >= 5) {
      background(200,200,200);
      change = 0;
    }
    else {
      change++;
      background(50,50,50);
    }
  }
  else {
    background(60); //background is dark grey
  }

  fill(200);

  noStroke();

  //shouldn't really modify this printout code unless there is a really good reason to
  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, inchesToPixels(.2f));
    text("User had " + errorCount + " error(s)", width/2, inchesToPixels(.2f)*2);
    text("User took " + (finishTime-startTime)/1000f/trialCount + " sec per target", width/2, inchesToPixels(.2f)*3);
    text("User took " + ((finishTime-startTime)/1000f/trialCount+(errorCount*errorPenalty)) + " sec per target inc. penalty", width/2, inchesToPixels(.2f)*4);
    return;
  }
  
  if (phaseNum == ROTATION_AND_ZOOM_PHASE) {
    drawController();
  }

  //===========DRAW TARGET SQUARE=================
  t = targets.get(trialIndex);
  if (phaseNum == MOVE_PHASE) {
    pushMatrix();
    translate(width/2, height/2); //center the drawing coordinates to the center of the screen
    translate(t.x, t.y); //center the drawing coordinates to the center of the screen
    rotate(radians(t.rotation));
    fill(255, 0, 0); //set color to semi translucent
    rect(0, 0, t.z, t.z);

    targetX = width/2 + t.x;
    targetY = height/2 + t.y;
    
    //mark the center with the appropriate margin of error 
    fill(255,255,255);
    rect(0, 0,inchesToPixels(.05f), inchesToPixels(.05f));
    popMatrix();
  }

  //===========DRAW CURSOR SQUARE=================
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  noFill();
  strokeWeight(3f);
  stroke(160);
  rect(0,0, screenZ, screenZ);
  popMatrix();
  
  //===========DRAW CONTROLS=================
  fill(255);
  signalWhenCorrect(t);
  text("Trial " + (trialIndex+1) + " of " +trialCount, width/2, inchesToPixels(.5f));

  //===========DRAW BACK BUTTON===============
  if (showBack) {
    drawButton();
  }
  
  if (phaseNum == ROTATION_AND_ZOOM_PHASE) {
    // line to correct dot
    fill(255,255,255);
    line(mouseX, mouseY, cdotX, cdotY);
    //fill(255);
    drawCorrect(t);
  } else if (phaseNum == MOVE_PHASE) {
    line(mouseX, mouseY, targetX, targetY);
    screenTransX = mouseX - 350;
    screenTransY = mouseY - 350;
  }
  if (!inplay) {
    playSound(); 
  }
}

void playSound() {
  if (play) {
    alert.play();
    inplay = true;
  }
  else {
    alert.stop();
    inplay = false;
  }

}
void signalWhenCorrect(Target t)
{
  if (phaseNum == ROTATION_AND_ZOOM_PHASE) {
    if (calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5 && abs(t.z - screenZ)<inchesToPixels(.05f)) {
      drawCursor(100); //fill background if rotation is correct
      controllerFlash = true;
      play = true;
    }
    else {
      inplay = false;
      controllerFlash = false;
      play = false;
      //alert.stop();
    }
  }

  if (phaseNum == MOVE_PHASE) {
    //inplay = false;
    //play = false;
    if (dist(t.x,t.y,screenTransX,screenTransY)<inchesToPixels(.05f)) {
      drawCursor(100);
      backgroundFlash = true;
      play = true;
    }
    else {
      inplay = false;
      backgroundFlash = false;
      play = false;
    }
  }
}

void drawController() {
  pushMatrix();
  translate(width/2, height/2);
  
  if (controllerFlash) {
    if (change >= 5) {
      fill (200,200,200);
      change = 0;
    }
    else {
      change++;
      fill (50,50,50);
    }
  }
  else {
    fill(150, 150, 0); 
  }

  strokeWeight(0f);
  rect(0, 0, 360, 400);
  popMatrix();
}

void drawButton() {
  pushMatrix();
  translate(width/2, height/2);
  
  if (hovered) {
    fill(100,100,100);
  }

  fill(150,150,150);

  strokeWeight(0f);
  rect(0, 0, 360, 400);
  popMatrix();
}

void drawCorrect(Target t) {
  //90/5 = 18 different possible screen rotations
  //20 * 18 = 360 width ==> 350 - (360/2) = 170 starting x position
  //screenRotation = ((mouseX - 170) / 20) * 5;
  //20 different size options
  //20 * 20 = 400 height ==> 350 - (400/2) = 150 starting y position
  //screenZ = ((mouseY - 150) / 20 + 1) * inchesToPixels(.15f);
  pushMatrix();
  //translate(170 + 10, 150 + 10);
  cdotX = 170 + 10+t.rotation % 90 / 5 * 20;
  cdotY = 150 + 10+(t.z / inchesToPixels(.15f) - 1) * 20;
  translate(cdotX, cdotY);
  fill(25,25,25); 
  strokeWeight(0f);
  rect(0, 0, 20, 20);
  popMatrix();
}

void drawCursor(int Color) {
  pushMatrix();
  translate(width/2, height/2); //center the drawing coordinates to the center of the screen
  translate(screenTransX, screenTransY);
  rotate(radians(screenRotation));
  fill(Color);
  strokeWeight(3f);
  stroke(160);
  rect(0,0, screenZ, screenZ);
  popMatrix();
}

void mousePressed()
{
    if (startTime == 0) //start time on the instant of the first user click
    {
      startTime = millis();
      println("time started!");
    }
}

void mouseMoved() {  
  if (phaseNum == ROTATION_AND_ZOOM_PHASE) {
    if (mouseX >= 170 && mouseX <= 530 && mouseY >= 150 && mouseY <= 550) {
      screenRotation = ((mouseX - 170) / 20) * 5;
      println("rotation: " + screenRotation);
      screenZ = ((mouseY - 150) / 20 + 1) * inchesToPixels(.15f);
      println("Z: " + screenZ);
      println("correct rotation: " + t.rotation );
      println("correct Z: " + t.z);

    }

  } else if (phaseNum == MOVE_PHASE) {
    screenTransX = mouseX - 350;
    screenTransY = mouseY - 350;
  }

  else if (phaseNum == -1) {
      if (mouseX >= width/2 - 180 && mouseX <= width/2 + 180 && mouseY >= height/2-180 && mouseY <= height/2+180) {
        hovered = true;
      }
      hovered = false;
  }
}

void mouseReleased()
{
  if (phaseNum == ROTATION_AND_ZOOM_PHASE) {

    // correct move
    if (calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5 && abs(t.z - screenZ)<inchesToPixels(.05f)) {
      correct.play();
      phaseNum++;
      showBack = false;
    }
    // wrong move, show back button
    else {
      phaseNum = BACK_1;
      showBack = true;
    }

  } else if (phaseNum == MOVE_PHASE) {
      phaseNum = 0;
      if (userDone==false && !checkForSuccess()) {
        showBack = true;
        phaseNum = BACK_2;
      }

      else {
        showBack = false;
        correct.play();

        //and move on to next trial
        trialIndex++;
        
        if (trialIndex==trialCount && userDone==false)
        {
          userDone = true;
          finishTime = millis();
        }
        backgroundFlash = false;
      }

  }

  else if (phaseNum == BACK_1) {
    // if back button is clicked 
    if (mouseX >= width/2 - 180 && mouseX <= width/2 + 180 && mouseY >= height/2-180 && mouseY <= height/2+180) {
      phaseNum ++;
    }

    // else
    else {
      phaseNum = MOVE_PHASE;
    }

    showBack = false;
  }

  else if (phaseNum == BACK_2) {
    // revert to move phase
    if (mouseX >= width/2 - 180 && mouseX <= width/2 + 180 && mouseY >= height/2-180 && mouseY <= height/2+180) {
      phaseNum = MOVE_PHASE;
    }

    // else, proceed
    else {
      phaseNum = ROTATION_AND_ZOOM_PHASE;
      errorCount++;
      trialIndex ++;
      if (trialIndex==trialCount && userDone==false)
      {
        userDone = true;
        finishTime = millis();
      }
      backgroundFlash = false;
    }

    showBack = false;
  }
}

//probably shouldn't modify this, but email me if you want to for some good reason.
public boolean checkForSuccess()
{
  Target t = targets.get(trialIndex); 
  boolean closeDist = dist(t.x,t.y,screenTransX,screenTransY)<inchesToPixels(.05f); //has to be within .1"
  boolean closeRotation = calculateDifferenceBetweenAngles(t.rotation,screenRotation)<=5;
  boolean closeZ = abs(t.z - screenZ)<inchesToPixels(.05f); //has to be within .1"  
  
  println("Close Enough Distance: " + closeDist + " (cursor X/Y = " + t.x + "/" + t.y + ", target X/Y = " + screenTransX + "/" + screenTransY +")");
  println("Close Enough Rotation: " + closeRotation + " (rot dist="+calculateDifferenceBetweenAngles(t.rotation,screenRotation)+")");
  println("Close Enough Z: " +  closeZ + " (cursor Z = " + t.z + ", target Z = " + screenZ +")");
  
  return closeDist && closeRotation && closeZ;  
}

//utility function I include
double calculateDifferenceBetweenAngles(float a1, float a2)
  {
     double diff=abs(a1-a2);
      diff%=90;
      if (diff>45)
        return 90-diff;
      else
        return diff;
 }