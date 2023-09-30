void init_page() {
  checkpoint = 0;
  
  if (firstTime) {
    noFill();
    img[0] = loadImage("C.png");
    noFill();
    img[1] = loadImage("C#.png");
    noFill();
    img[2] = loadImage("D.png");
    noFill();
    img[3] = loadImage("D#.png");
    noFill();
    img[4] = loadImage("E.png");
    noFill();
    img[5] = loadImage("F.png");
    noFill();
    img[6] = loadImage("F#.png");
    noFill();
    img[7] = loadImage("G.png");
    noFill();
    img[8] = loadImage("G#.png");
    noFill();
    img[9] = loadImage("A.png");
    noFill();
    img[10] = loadImage("A#.png");
    noFill();
    img[11] = loadImage("B.png");
    noFill();
    img[12] = loadImage("fire.png");
    noFill();
    img[13] = loadImage("milky_way3.jpg");
    noFill();
    img[14] = loadImage("Legend.png");
    noFill();
    sx_arr = loadImage("left_arr.png");
    noFill();
    dx_arr = loadImage("right_arr.png");
    noFill();
    sx_arr_on = loadImage("left_arr_on.png");
    noFill();
    dx_arr_on = loadImage("right_arr_on.png");
    
    loaded = true;

    //images (SVG) for Hand recognition
    hand[0] = loadShape("info.svg");
    hand[1] = loadShape("ok_dx.svg");
    hand[2] = loadShape("ok_dx.svg");
    hand[3] = loadShape("palm_dx_off.svg");
    hand[4] = loadShape("palm_sx_off.svg");
    hand[5] = loadShape("one.svg");
    hand[6] = loadShape("one.svg");
    hand[7] = loadShape("two.svg");
    hand[8] = loadShape("two.svg");
    hand[9] = loadShape("three.svg");
    hand[10] = loadShape("three.svg");
    hand[11] = loadShape("four.svg");
    hand[12] = loadShape("four.svg");

    mixerHand[0] = loadShape("one.svg");
    mixerHand[1] = loadShape("two.svg");
    mixerHand[2] = loadShape("three.svg");
    mixerHand[3] = loadShape("four.svg");

    // ok
    hand[1].setFill(color(250, 255, 0)); //Ok R
    hand[2].setFill(color(250, 255, 0));
    hand[2].rotateY(PI);
    hand[2].translate(hand[2].width, 0);  //Ok L
    // palm off
    hand[3].setFill(color(100, 100, 100)); //Palm R
    hand[4].setFill(color(100, 100, 100)); // Palm L
    // One
    hand[5].setFill(color(250, 255, 0)); //One R
    hand[6].setFill(color(250, 255, 0));
    hand[6].rotateY(PI);
    hand[6].translate(hand[6].width, 0);  //One L
    // Two
    hand[7].setFill(color(250, 255, 0)); //Two R
    hand[8].setFill(color(250, 255, 0));
    hand[8].rotateY(PI);
    hand[8].translate(hand[8].width, 0);  //Two L
    //Three
    hand[9].setFill(color(250, 255, 0)); //Three R
    hand[10].setFill(color(250, 255, 0));
    hand[10].rotateY(PI);
    hand[10].translate(hand[10].width, 0);//Three L
    //Four
    hand[11].setFill(color(250, 255, 0)); //Four R
    hand[12].setFill(color(250, 255, 0));
    hand[12].rotateY(PI);
    hand[12].translate(hand[12].width, 0);//Four L
    

    //Mixer hands
    mixerHand[0].setFill(color(255));
    mixerHand[1].setFill(color(255));
    mixerHand[2].setFill(color(255));
    mixerHand[3].setFill(color(255));

    hand[1].setVisible(false);
    hand[2].setVisible(false);
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

    mixerHand[0].setVisible(true);
    mixerHand[1].setVisible(true);
    mixerHand[2].setVisible(true);
    mixerHand[3].setVisible(true);

// PROBABILITY

    // This prob matrix controls which interval between 2 colliding notes will be taken into account
    // Coded as: ("internal_interval & external_interval", number)
    // ran = random(0,100) 
    // if (ran < number) ==> internal_interval is the chosen one
    // if (ran > number) ==> external_interval is the chosen one
    probInterval.put("0&12", 50);
    probInterval.put("1&11", 5);
    probInterval.put("2&10", 6);
    probInterval.put("3&9", 90);
    probInterval.put("4&8", 95);
    probInterval.put("5&7", 25);
    probInterval.put("6&6", 50);
    probInterval.put("7&5", 75);
    probInterval.put("8&4", 5);
    probInterval.put("9&3", 10);
    probInterval.put("10&2", 94);
    probInterval.put("11&1", 95);
    probInterval.put("12&0", 50);

    // This prob matrix controls if the collision happens or not, 
    // basing this choice on the chosen distance between the notes
    // Coded as: ("chosen_interval", number)
    // ran = random(0,100) 
    // if (ran < number) ==> the collision happens
    // if (ran > number) ==> the two colliding planets ingore each other
    probWin.put("0", 0);   // unisono
    probWin.put("1", 0);   // seconda minore
    probWin.put("2", 5);   // seconda maggiore
    probWin.put("3", 95);  // terza minore
    probWin.put("4", 95);  // terza maggiore
    probWin.put("5", 70);  // quarta giusta
    probWin.put("6", 0);   // quinta diminuita
    probWin.put("7", 90);  // quinta
    probWin.put("8", 25);  // sesta minore
    probWin.put("9", 25);  // sesta maggiore
    probWin.put("10", 70); // settima maggiore
    probWin.put("11", 70); // settima minore
    probWin.put("12", 0);  // ottava

    notes.put(1, 60); //midi code
    notes.put(2, 61);
    notes.put(3, 62);
    notes.put(4, 63);
    notes.put(5, 64);
    notes.put(6, 65);
    notes.put(7, 66);
    notes.put(8, 67);
    notes.put(9, 68);
    notes.put(10, 69);
    notes.put(11, 70);
    notes.put(12, 71);
    
    midiToNote.put(60, "C");
    midiToNote.put(61, "C#");
    midiToNote.put(62, "D");
    midiToNote.put(63, "D#");
    midiToNote.put(64, "E");
    midiToNote.put(65, "F");
    midiToNote.put(66, "F#");
    midiToNote.put(67, "G");
    midiToNote.put(68, "G#");
    midiToNote.put(69, "A");
    midiToNote.put(70, "A#");
    midiToNote.put(71, "B");
    midiToNote.put(72, "C");
    midiToNote.put(73, "C#");
    midiToNote.put(74, "D");
    midiToNote.put(75, "D#");
    midiToNote.put(76, "E");
    midiToNote.put(77, "F");
    midiToNote.put(78, "F#");
    midiToNote.put(79, "G");
    midiToNote.put(80, "G#");
    midiToNote.put(81, "A");
    midiToNote.put(82, "A#");
    midiToNote.put(83, "B");

    f = createFont("Arial", 128, true);
    f4 = createFont("Arial", 128, true);
    f5 = createFont("Arial", 18, true);
    scaleName.put(0, " ");
    scaleName.put(1, "C");
    scaleName.put(2, "C#");
    scaleName.put(3, "D");
    scaleName.put(4, "D#");
    scaleName.put(5, "E");
    scaleName.put(6, "F");
    scaleName.put(7, "F#");
    scaleName.put(8, "G");
    scaleName.put(9, "G#");
    scaleName.put(10, "A");
    scaleName.put(11, "A#");
    scaleName.put(12, "B");
    
    scaleType.put(0, " ");
    scaleType.put(1, "maj");
    scaleType.put(2, "min");

    firstTime = false;
  }

  checkpoint++;

  count = 0;
  depth = 500;

  position = new PVector(0, 0, 0);
  size = 1000;
  sizeMax=size;
  octree = new Octree(position, octreeCap, size);
  globalParticles = new ArrayList<Particle>();
  globalSystems = new ArrayList<Particle>();
  leaves = new ArrayList<Octree>();

  checkpoint++;

  centerOfMass = new PVector();

  loaded = false;
  push();
  //La prima particella è il buco nero
  for (int i = 0; i < nPlan; i++) {
    if ( i == 0) {
      PVector pos = new PVector(0, 0, 0);
      float mass = massone;
      Particle particle = new Particle(pos.x, pos.y, pos.z, massone, 0, -1, -1, -1);
      globalParticles.add(particle);
      octree.addParticle(particle);
    } else {
      PVector pos = PVector.random3D().mult(random(500, 2000));
      pos.z = constrain(pos.z, -300, 300);
      float mass = random(minMass, maxMass);
      int note1 = int(random(1, 13));
      noStroke();
      noFill();
      Particle particle = new Particle(pos.x, pos.y, pos.z, mass, 1, note1, -1, -1);
      globalParticles.add(particle);
      octree.addParticle(particle);
    }
  }
  pop();
  loaded = true;

  nLead_old = new ArrayList<Float>();

  checkpoint++;

  setupMixer();

  checkpoint++;

  delay(4000); // Lengthly initialization here: load stuff, compute things, etc.
  checkpoint++; //5
  delay(1000);
  startPhase++;
}

void showLoading() {
  background(0);
  cam.beginHUD();
  image(img_load, width/2 - 529, height/2-200);
  if (loaded) {
    image(img_loading[checkpoint], width/2 -500, height/2 +200);
  }
  cam.endHUD();
}

void homePage() {
  octreeDrawable = false;
  cam.setActive(false);
  img[13].resize(width, height);
  background(img[13]);
  lights();
  for (Particle p : globalParticles) {
    p.display();
  }
  cam.rotateY((double)(PI/70));
  if (started == false && oneTime) {
    cam.beginHUD();
    push();
    image(img_home, width/2 - 433, height/2);
    pop();
    cam.endHUD();
    if (keyPressed) {
      if (key == ' ' && oneTime) {
        oneTime = false;
        cam.reset(2000);
        cam.setDistance(5000, 2000);
        thread("threadStart");
      }
    }
  }
}

void threadStart() {
  delay(2000);
  started = true;
  cam.setActive(true);
  startPhase++;
}
