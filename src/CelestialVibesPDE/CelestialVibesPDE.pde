import controlP5.*;
import peasy.*;
import oscP5.*;
import netP5.*;
import supercollider.*;

Octree octree;
ArrayList<Particle> globalParticles;
ArrayList<Particle> globalSystems;
PVector centerOfMass;
float G = 2;
int nPlan = 100;
PVector position;
float size;
int octreeCap = 5;
int depth;
float sizeMax;
int count;
ArrayList<Octree> leaves;
boolean drawTreeFlag = false;
float threshold = 0.5;
float forceConstrain = 5;
float massone = 50000;
float minMass = 10, maxMass = 30; // mass limits in the planets creation

ControlP5 cp5;

//OSC
OscP5 oscP5;
NetAddress myRemoteLocation;
ArrayList<Float> nLead_old;
//NetAddress bassLocation;

PeasyCam cam;
float current_rot_X = 0;
float current_rot_Y = 0;
float current_zoom = 5000;
float scale = 1;
float current_pan_x=0;
float current_pan_y=0;
float xPan = 0;
float yPan = 0;

PFont f, f2, f3, f4, f5;
float textScale = 0;
float textTarget = 128;

PImage[] img = new PImage[15];
PImage[] img_loading = new PImage[6];
PShape[] hand = new PShape[13];
PShape[] mixerHand = new PShape[4];
int infoHeight = 50;
boolean overInfo = false;
boolean infoActive = false;
boolean overX = false;

// PROBABILITY
HashMap<String, Integer> probInterval = new HashMap<String, Integer>();
HashMap<String, Integer> probWin = new HashMap<String, Integer>();
HashMap<Integer, Integer> notes = new HashMap<Integer, Integer>();
HashMap<Integer, String> scaleName = new HashMap<Integer, String>();
HashMap<Integer, String> scaleType = new HashMap<Integer, String>();
HashMap<Integer, String> midiToNote = new HashMap<Integer, String>();
int rootNote = 0;
int foundScale = 0; // 0: no scale found || 1: Major || 2: Minor
int scaleCounter = 0; // se arriva a 2 significa che in un impatto PP sono state definite entrmbe le scale --> l'impatto non avviene

//Loading Screen
int startPhase = 0;
int checkpoint = 0;
boolean started = false;
boolean oneTime = true;
boolean loaded = false;
PImage img_home, img_load;
boolean firstTime = true;
boolean octreeDrawable = false;
int Y_AXIS = 1;
int X_AXIS = 2;

//PAN ZOOM ROTATION utility
int pan_count = 0;

// System (chords) visualization
boolean highlighting = false;
int chordPosX = 30;
int chordPosY = 30;
int chordsWidth = 300;
int chordsHeight = 210;
int linePosY = 70;
int chordCount = 0;
PImage sx_arr, dx_arr, sx_arr_on, dx_arr_on;
boolean sxFlag = false;
boolean dxFlag = false;
boolean firstChord = false;
int sxCount = 0;
int dxCount = 0;

void setup() {
  frameRate(30);
  size(1440, 900, P3D);
  surface.setLocation(displayWidth/2 - width/2, displayHeight/2 - height/2 - 50);

  cam = new PeasyCam(this, 850);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(5000);

  //OSC Init
  oscP5 = new OscP5(this, 12000); // start OSC and listen port ...
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
  cp5 = new ControlP5(this);

  img_home = loadImage("title.png");
  img_load = loadImage("loading.png");
  img_loading[0] = loadImage("0.png");
  img_loading[1] = loadImage("20.png");
  img_loading[2] = loadImage("40.png");
  img_loading[3] = loadImage("60.png");
  img_loading[4] = loadImage("80.png");
  img_loading[5] = loadImage("100.png");
}


void draw() {
  ////////////////////////////////////////////
  // LOADING
  ////////////////////////////////////////////
  switch(startPhase)
  {
  case 0: //Strat the setup
    thread("init_page");
    startPhase++;
    return;
  case 1: //During the setup
    showLoading();
    return;
  case 2: //Home page
    homePage();
    return;
  }


  ////////////////////////////////////////////
  // MAIN
  ////////////////////////////////////////////

  surface.setTitle("Celestial Vibes " + nf(frameRate, 0, 1) + " P: " + globalParticles.size() + " S: " + globalSystems.size());

  img[13].resize(width, height);
  float coordMax = 0;
  float tempCoordMax = 0;
  PVector posMax = new PVector();
  float massMax = 0;
  Particle tempParticle = new Particle(0, 0, 0, 0, -1, -1, -1, -1);
  background(img[13]);
  lights();

  centerOfMass = octree.calculateCenterOfMass().copy();

  for (Particle particle : globalParticles) {

    octree.calculateForce(particle, threshold);
    particle.update();

    posMax = PVector.sub(particle.position, octree.position);
    coordMax = max(abs(posMax.x), abs(posMax.y), abs(posMax.z));

    if (coordMax > tempCoordMax) {
      tempParticle = particle;
      tempCoordMax = coordMax;
      massMax = particle.mass;
    }
  }
  sizeMax = 2*(tempCoordMax + massMax);
  if (sizeMax > 5000) {
    globalParticles.remove(tempParticle);
    if (tempParticle.type != 1) {
      globalSystems.remove(tempParticle);
    }
  }


  octree = new Octree(centerOfMass, octreeCap, sizeMax);
  for (Particle p : globalParticles) {
    octree.addParticle(p);
    p.display();
  }

  octree.leavesList();
  octree.calculateImpact(leaves);

  if (centerOfMass.mag()>100) {
    //println("Troppo Distantee");
    for (Particle p : globalParticles) {
      PVector force = centerOfMass.copy();
      force.setMag(10/centerOfMass.mag());
      p.applyBruteForce(force.mult(-1));
    }
  }

  if (drawTreeFlag) {

    for (Octree leaf : leaves) {
      leaf.drawOctree();
    }

    push();
    stroke(255, 255, 0);
    strokeWeight(2);
    line(octree.position.x, octree.position.y, octree.position.z, tempParticle.position.x, tempParticle.position.y, tempParticle.position.z);
    pop();
    //println("size: " + sizeMax);
  }

  leaves = new ArrayList<Octree>();

  if (foundScale != 0) {

    cam.beginHUD();
    if (textScale<127) {
      textScale = lerp(textScale, textTarget, 0.1);
    } else {
      textScale = textTarget;
    }

    textFont(f);
    textSize(textScale);
    textAlign(CENTER);
    text(scaleName.get(rootNote), width - 140, height -70);
    textSize(textScale/5);
    text(scaleType.get(foundScale), width - 138, height -40);
    cam.endHUD();
  }

  current_rot_X = lerp(current_rot_X, angle_X, 0.05);
  current_rot_Y = lerp(current_rot_Y, angle_Y, 0.05);
  cam.rotateX(current_rot_X);
  cam.rotateY(current_rot_Y);
  angle_X = 0;
  angle_Y = 0;

  current_pan_x = lerp(current_pan_x, Pan_X, 0.05);
  current_pan_y = lerp(current_pan_y, Pan_Y, 0.05);
  cam.pan(current_pan_x, current_pan_y);

  Pan_X=0;
  Pan_Y=0;

  // CONTROL P5 SLIDERS
  bassSli.update();
  padSli.update();
  arpSli.update();
  masterSli.update();

  cam.beginHUD();
  cp5.draw();


  // Hand Detection rectangle
  push();
  translate(width-140, height-320);
  fill(0, 190);
  stroke(255);
  strokeWeight(4);
  rect(-90, 0, 180, 130, 0, 0, 20, 20);
  line(0, 30, 0, 130);
  line(-90, 30, 90, 30);
  fill(255);
  shapeMode(CENTER);

  shape(hand[1], 45, 80, 60, 63);
  shape(hand[2], -45, 80, 60, 63);
  shape(hand[3], 45, 80, 60, 63);
  shape(hand[4], -45, 80, 60, 63);
  shape(hand[5], 45, 80, 60, 63);
  shape(hand[6], -45, 80, 60, 63);
  shape(hand[7], 45, 80, 60, 63);
  shape(hand[8], -45, 80, 60, 63);
  shape(hand[9], 45, 80, 60, 63);
  shape(hand[10], -45, 80, 60, 63);
  shape(hand[11], 45, 80, 60, 63);
  shape(hand[12], -45, 80, 60, 63);


  textFont(f5);
  textAlign(CENTER, CENTER);
  text("HAND DETECTION", 0, 14);

  pop();

  shape(mixerHand[0], masterSli.getPosition()[0], height - 50, masterSli.getWidth(), 31);
  shape(mixerHand[1], bassSli.getPosition()[0], height - 50, bassSli.getWidth(), 31);
  shape(mixerHand[2], padSli.getPosition()[0], height - 50, padSli.getWidth(), 31);
  shape(mixerHand[3], arpSli.getPosition()[0], height - 50, arpSli.getWidth(), 31);

  cam.endHUD();

  cam.setMouseControlled(true);
  //if (drumSli.isInside() || bassSli.isInside() || padSli.isInside() || arpSli.isInside() || masterSli.isInside() ) {
  if (bassSli.isInside() || padSli.isInside() || arpSli.isInside() || masterSli.isInside() ) {
    cam.setMouseControlled(false);
  }


  // INFO ON HAND CONTROLS
  if (infoActive) {

    cam.beginHUD();
    push();
    fill(0, 200);
    stroke(255);
    rect(width/2 - 700, infoHeight, 1400, 400);
    pop();

    textFont(f4);
    textSize(50);
    text("Useful informations", width/2, infoHeight + 50);
    textSize(30);
    text("You can use your hands to control the system in different ways:", width/2, infoHeight + 100);
    text("1. By touching the index finger and thumb of the RIGHT hand you can control the ROTATION", width/2, infoHeight + 150);
    text("2. By touching the index finger and thumb of the LEFT hand you can control the PAN", width/2, infoHeight + 190);
    text("3. By combining 1. and 2. and moving BOTH HANDS you can ZOOM in and out", width/2, infoHeight + 230);
    text("4. Doing different numbers with the RIGHT hand (e.g. index up for 1) you are selecting", width/2, infoHeight + 270);
    text("different sliders. In the meanwhile, touching index and thumb of the LEFT hand and", width/2, infoHeight + 310);
    text("moving it up and down you can control the level of the desired slider.", width/2, infoHeight + 350);

    cam.endHUD();
  } else {
    cam.beginHUD();
    image(img[14], width - 250, 30, 200, 85);
    cam.endHUD();
  }

  // SEND ROOT NOTE TO BASS
  RootOsc();

  if (highlighting) {
    cam.beginHUD();
    push();
    fill(0, 190);
    stroke(255);
    strokeWeight(4);
    rect(chordPosX, chordPosY, chordsWidth, chordsHeight, 0, 0, 20, 20);
    line(chordPosX, chordPosY + linePosY, chordPosX + chordsWidth, chordPosY + linePosY);
    line(chordPosX, chordPosY + linePosY*2, chordPosX + chordsWidth, chordPosY + linePosY*2);
    line(chordPosX + chordsWidth/2, chordPosY + linePosY*2, chordPosX + chordsWidth/2, chordPosY + chordsHeight);
    pop();

    textAlign(CENTER, CENTER);
    textFont(f4);
    textSize(50);
    text("Chords List", chordPosX + chordsWidth/2, chordPosY + linePosY/2 - 5);

    if (globalSystems.size() != 0) {
      String chord = " ";
      for (int n=0; n<globalSystems.get(chordCount).getNotes().size(); n++) {
        chord = chord + midiToNote.get(globalSystems.get(chordCount).getNotes().get(n)) + "  ";
      }

      textSize(30);
      textAlign(CENTER, CENTER);
      text((chordCount+1) + ". " +chord, chordPosX + chordsWidth/2, chordPosY + linePosY*1.5 - 3);
    }
    //textAlign(CENTER, CENTER);
    //text("D: <=      => :D", chordPosX + chordsWidth/2, chordPosY + linePosY*2.5);

    // LEFT ARROW
    if (sxFlag && sxCount < 10) {
      imageMode(CENTER);
      image(sx_arr_on, chordPosX + chordsWidth/4, chordPosY + linePosY*2.5, 30, 30);
      sxCount ++;
    } else {
      if (sxFlag) {
        sxFlag = false;
      }
      if (sxCount != 0) {
        sxCount = 0;
      }
      imageMode(CENTER);
      image(sx_arr, chordPosX + chordsWidth/4, chordPosY + linePosY*2.5, 30, 30);
    }

    // RIGHT ARROW
    if (dxFlag && dxCount < 5) {
      imageMode(CENTER);
      image(dx_arr_on, chordPosX + chordsWidth*3/4, chordPosY + linePosY*2.5, 30, 30);
      dxCount ++;
    } else {
      if (dxFlag) {
        dxFlag = false;
      }
      if (dxCount != 0) {
        dxCount = 0;
      }
      imageMode(CENTER);
      image(dx_arr, chordPosX + chordsWidth*3/4, chordPosY + linePosY*2.5, 30, 30);
    }
    cam.endHUD();
    imageMode(CORNER);

    if (globalSystems.size() != 0) {
      globalSystems.get(chordCount).higlight();
      if (firstChord) {
        cam.lookAt(globalSystems.get(chordCount).position.x, globalSystems.get(chordCount).position.y, globalSystems.get(chordCount).position.z, (double) 550, 150);
        firstChord = false;
      }
      if (dxCount == 1 || sxCount == 1) {
        cam.lookAt(globalSystems.get(chordCount).position.x, globalSystems.get(chordCount).position.y, globalSystems.get(chordCount).position.z, (double) 550, 150);
      } else {
        cam.lookAt(globalSystems.get(chordCount).position.x, globalSystems.get(chordCount).position.y, globalSystems.get(chordCount).position.z, (double) 550, 0);
        cam.rotateX(PI/500);
        cam.rotateY(PI/500);
      }
    }
  }
}

void mouseClicked() {
  if (mouseButton == RIGHT) {
    if (started) {
      drawTreeFlag = !drawTreeFlag;
    }
  }
}

void keyPressed() {
  if (key == 'i') {
    infoActive = true;
    hand[0].setVisible(false);
  }
  if (key == 'r' && started) {
    println("reset");

    OscMessage msg = new OscMessage("/reset");
    msg.add("RESET!");
    oscP5.send(msg, myRemoteLocation);

    started = false;
    oneTime = true;
    drawTreeFlag = false;
    infoActive = false;
    octreeDrawable = false;
    textScale = 0;
    rootNote = 0;
    foundScale = 0; // 0: no scale found || 1: Major || 2: Minor
    scaleCounter = 0; // se arriva a 2 significa che in un impatto PP sono state definite entrmbe le scale --> l'impatto non avviene
    cp5 = new ControlP5(this);
    background(0);


    cam.reset();
    startPhase = 0;
  }
  if (key == 'c') {
    highlighting = true;
    firstChord = true;
  }
  if (keyCode == RIGHT && highlighting) {
    dxFlag = true;
    if (globalSystems.size() > chordCount+1) {
      chordCount++;
    } else {
      chordCount = 0;
    }
  }
  if (keyCode == LEFT && highlighting) {
    sxFlag = true;
    if (chordCount!=0) {
      chordCount--;
    } else {
      chordCount = globalSystems.size()-1;
    }
  }
}

void keyReleased() {
  if (key == 'i') {
    infoActive = false;
    hand[0].setVisible(true);
  }
  if (key == 'c') {
    highlighting = false;
    chordCount = 0;
    cam.reset(2000);
    cam.setDistance(5000, 2000);
  }
}

boolean overCircle(int x, int y, int diameter) {
  float disX = x - mouseX;
  float disY = y - mouseY;
  if (sqrt(sq(disX) + sq(disY)) < diameter/2 ) {
    return true;
  } else {
    return false;
  }
}

boolean overRect(int x, int y, int w, int h) {
  if (mouseX >= x && mouseX <= x+w &&
    mouseY >= y && mouseY <= y+h) {
    return true;
  } else {
    return false;
  }
}

float startAngle_X;
float startAngle_Y;
float startPan_X;
float startPan_Y;
float start_zoom;

float oldX = 0;
float oldY = 0;
float oldPanX = 0;
float oldPanY = 0;

float old_inc_X = 0;
float old_inc_Y = 0;
float old_inc_Pan_X = 0;
float old_inc_Pan_Y = 0;
float old_inc_zoom = 0;

float maxIncrement = radians(100);
float angle_X = 0;
float angle_Y = 0;
float Pan_X;
float Pan_Y;
float zoom;


void oscEvent(OscMessage theOscMessage) {
  if ( startPhase == 2) {
    /* print the address pattern and the typetag of the received OscMessage */
    print("### received an osc message.");
    print(" || addrpattern: "+theOscMessage.addrPattern());
    println(" || typetag:"+theOscMessage.typetag());

    // PSS ROTATION OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/PSS_rotation_start")==true) {
      if (theOscMessage.checkTypetag("ff")) {

        float x = theOscMessage.get(0).floatValue();
        float y = theOscMessage.get(1).floatValue();

        float inc_X = map(x, 0, 1, -2*PI, 2*PI);
        float inc_Y = map(y, 0, 1, -2*PI, 2*PI);

        startAngle_X = inc_X;
        startAngle_Y = inc_Y;

        old_inc_X = 0;
        old_inc_Y = 0;

        angle_Y = 0;
        angle_X = 0;
      }
    } else if (theOscMessage.checkAddrPattern("/PSS_rotation")==true) {
      if (theOscMessage.checkTypetag("ff")) {

        float x = theOscMessage.get(0).floatValue();
        float y = theOscMessage.get(1).floatValue();

        float inc_X = map(x, 0, 1, -2*PI, 2*PI);
        float inc_Y = map(y, 0, 1, -2*PI, 2*PI);

        angle_Y = -(inc_X - old_inc_X - startAngle_X);
        angle_X = inc_Y - old_inc_Y - startAngle_Y;

        old_inc_X = inc_X - startAngle_X;
        old_inc_Y = inc_Y - startAngle_Y;
      }
    }

    // PSS PAN OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/PSS_pan_start")==true) {
      if (theOscMessage.checkTypetag("ff")) {

        float x = theOscMessage.get(0).floatValue();
        float y = theOscMessage.get(1).floatValue();

        float inc_Pan_X = map(x, 0, 1, -1500, 1500);
        float inc_Pan_Y = map(y, 0, 1, -1500, 1500);

        startPan_X = inc_Pan_X;
        startPan_Y = inc_Pan_Y;

        old_inc_Pan_X = 0;
        old_inc_Pan_Y = 0;

        Pan_X = 0;
        Pan_Y = 0;
      }
    } else if (theOscMessage.checkAddrPattern("/PSS_pan")==true) {
      if (theOscMessage.checkTypetag("ff")) {

        float x = theOscMessage.get(0).floatValue();
        float y = theOscMessage.get(1).floatValue();

        float inc_Pan_X = map(x, 0, 1, -1500, 1500);
        float inc_Pan_Y = map(y, 0, 1, -1500, 1500);

        Pan_X = -(inc_Pan_X - old_inc_Pan_X - startPan_X);
        Pan_Y = -(inc_Pan_Y - old_inc_Pan_Y - startPan_Y);

        old_inc_Pan_X = inc_Pan_X - startPan_X;
        old_inc_Pan_Y = inc_Pan_Y - startPan_Y;
      }
    }

    // PSS ZOOM OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/PSS_zoom_start")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float x = theOscMessage.get(0).floatValue();
        x = constrain(x, 0.1, 0.55);
        float inc_zoom = map(x, 0.1, 0.55, 0, 4000);
        start_zoom = inc_zoom;
        old_inc_zoom = 0;
        zoom = inc_zoom - old_inc_zoom - start_zoom;
        cam.setDistance(cam.getDistance() + zoom);
      }
    } else if (theOscMessage.checkAddrPattern("/PSS_zoom")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float x = theOscMessage.get(0).floatValue();
        x = constrain(x, 0.1, 0.55);
        float inc_zoom = map(x, 0.1, 0.55, 0, 4000);
        zoom = -(inc_zoom - old_inc_zoom - start_zoom);
        old_inc_zoom = inc_zoom - start_zoom;
        cam.setDistance(cam.getDistance() + zoom, 1000);
      }
    }

    // MIXER MASTER CHANGING OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/mixer_1_changing")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float y = theOscMessage.get(0).floatValue();
        float mix1_val = constrain(y, 0.25, 0.75);
        mix1_val= map(mix1_val, 0.25, 0.75, 1.5, 0.0001);
        masterSli.setValue(mix1_val);
        OscMessage msg = new OscMessage("/masterFader");
        msg.add(mix1_val);
        oscP5.send(msg, myRemoteLocation);
      }
    }

    // MIXER BASS CHANGING OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/mixer_2_changing")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float y = theOscMessage.get(0).floatValue();
        float mix1_val = constrain(y, 0.25, 0.75);
        mix1_val= map(mix1_val, 0.25, 0.75, 1.5, 0.0001);
        bassSli.setValue(mix1_val);
        OscMessage msg = new OscMessage("/bassFader");
        msg.add(mix1_val);
        oscP5.send(msg, myRemoteLocation);
      }
    }

    // MIXER PAD CHANGING OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/mixer_3_changing")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float y = theOscMessage.get(0).floatValue();
        float mix1_val = constrain(y, 0.25, 0.75);
        mix1_val= map(mix1_val, 0.25, 0.75, 1.5, 0.0001);
        padSli.setValue(mix1_val);
        OscMessage msg = new OscMessage("/padFader");
        msg.add(mix1_val);
        oscP5.send(msg, myRemoteLocation);
      }
    }

    // MIXER PAD CHANGING OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/mixer_4_changing")==true) {
      if (theOscMessage.checkTypetag("f")) {

        float y = theOscMessage.get(0).floatValue();
        float mix1_val = constrain(y, 0.25, 0.75);
        mix1_val= map(mix1_val, 0.25, 0.75, 1.5, 0.0001);
        arpSli.setValue(mix1_val);
        OscMessage msg = new OscMessage("/arpFader");
        msg.add(mix1_val);
        oscP5.send(msg, myRemoteLocation);
      }
    }

    // HAND DETECTION IMAGES OSC MESSAGE
    if (theOscMessage.checkAddrPattern("/gesture")==true) {
      if (theOscMessage.checkTypetag("")) {
        hand[1].setVisible(false);
        hand[2].setVisible(false);
        hand[3].setFill(color(100, 100, 100));
        hand[4].setFill(color(100, 100, 100));
        hand[3].setVisible(true);
        hand[4].setVisible(true);
        hand[5].setVisible(false);
        hand[6].setVisible(false);
        hand[7].setVisible(false);
        hand[8].setVisible(false);
        hand[9].setVisible(false);
        hand[10].setVisible(false);
        hand[11].setVisible(false);
        hand[12].setVisible(false);
      } else if (theOscMessage.checkTypetag("s")) {
        String[] msg = new String[1];
        msg[0] = theOscMessage.get(0).toString();
        setHandVisible(msg);
      } else if (theOscMessage.checkTypetag("ss")) {
        String[] msg = new String[2];
        msg[0] = theOscMessage.get(0).toString();
        msg[1] = theOscMessage.get(1).toString();
        setHandVisible(msg);
      }
    }

    if (theOscMessage.checkAddrPattern("/EXIT")==true) {
      OscMessage msg = new OscMessage("/exit");
      oscP5.send(msg, myRemoteLocation);
      exit();
    }
  }
}

void setHandVisible(String[] osc) {
  if (osc.length == 1) {
    if (osc[0].charAt(0) == 'R') {
      hand[2].setVisible(false);
      hand[4].setFill(color(100, 100, 100));
      hand[4].setVisible(true);
      hand[6].setVisible(false);
      hand[8].setVisible(false);
      hand[10].setVisible(false);
      hand[12].setVisible(false);
    } else if (osc[0].charAt(0) == 'L') {
      hand[1].setVisible(false);
      hand[3].setFill(color(100, 100, 100));
      hand[3].setVisible(true);
      hand[5].setVisible(false);
      hand[7].setVisible(false);
      hand[9].setVisible(false);
      hand[11].setVisible(false);
    }
  }
  for (String s : osc) {
    if (s.charAt(0) == 'R') {
      if (s.length() == 1) {
        hand[1].setVisible(false);
        hand[3].setFill(color(250, 255, 0));
        hand[3].setVisible(true);
        hand[5].setVisible(false);
        hand[7].setVisible(false);
        hand[9].setVisible(false);
        hand[11].setVisible(false);
      } else {
        switch(s.charAt(1)) {
        case '1':
          hand[1].setVisible(false);
          hand[3].setVisible(false);
          hand[5].setVisible(true);
          hand[7].setVisible(false);
          hand[9].setVisible(false);
          hand[11].setVisible(false);
          break;
        case '2':
          hand[1].setVisible(false);
          hand[3].setVisible(false);
          hand[5].setVisible(false);
          hand[7].setVisible(true);
          hand[9].setVisible(false);
          hand[11].setVisible(false);
          break;
        case '3':
          hand[1].setVisible(false);
          hand[3].setVisible(false);
          hand[5].setVisible(false);
          hand[7].setVisible(false);
          hand[9].setVisible(true);
          hand[11].setVisible(false);
          break;
        case '4':
          hand[1].setVisible(false);
          hand[3].setVisible(false);
          hand[5].setVisible(false);
          hand[7].setVisible(false);
          hand[9].setVisible(false);
          hand[11].setVisible(true);
          break;
        case 'O':
          hand[1].setVisible(true);
          hand[3].setVisible(false);
          hand[5].setVisible(false);
          hand[7].setVisible(false);
          hand[9].setVisible(false);
          hand[11].setVisible(false);
          break;
        }
      }
    } else if (s.charAt(0) == 'L') {
      if (s.length() == 1) {
        hand[2].setVisible(false);
        hand[4].setFill(color(250, 255, 0));
        hand[4].setVisible(true);
        hand[6].setVisible(false);
        hand[8].setVisible(false);
        hand[10].setVisible(false);
        hand[12].setVisible(false);
      } else {
        switch(s.charAt(1)) {
        case '1':
          hand[2].setVisible(false);
          hand[4].setVisible(false);
          hand[6].setVisible(true);
          hand[8].setVisible(false);
          hand[10].setVisible(false);
          hand[12].setVisible(false);
          break;
        case '2':
          hand[2].setVisible(false);
          hand[4].setVisible(false);
          hand[6].setVisible(false);
          hand[8].setVisible(true);
          hand[10].setVisible(false);
          hand[12].setVisible(false);
          break;
        case '3':
          hand[2].setVisible(false);
          hand[4].setVisible(false);
          hand[6].setVisible(false);
          hand[8].setVisible(false);
          hand[10].setVisible(true);
          hand[12].setVisible(false);
          break;
        case '4':
          hand[2].setVisible(false);
          hand[4].setVisible(false);
          hand[6].setVisible(false);
          hand[8].setVisible(false);
          hand[10].setVisible(false);
          hand[12].setVisible(true);
          break;
        case 'O':
          hand[2].setVisible(true);
          hand[4].setVisible(false);
          hand[6].setVisible(false);
          hand[8].setVisible(false);
          hand[10].setVisible(false);
          hand[12].setVisible(false);
          break;
        }
      }
    }
  }
}

void RootOsc() {
  if (rootNote!=0) {
    int midi = notes.get(rootNote);
    String str = Integer.toString(midi-24);
    OscMessage msg = new OscMessage("/bass");
    msg.add(str);
    oscP5.send(msg, myRemoteLocation);
  }
}
