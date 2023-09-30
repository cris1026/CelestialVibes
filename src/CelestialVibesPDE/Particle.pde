class Particle {
  PVector position, axRotation, axRotation1, axRotation2;
  float mass, radius = 1, angleAxisRot, scale = 0, time = 80, currentPos = 0;
  PVector velocity;
  PVector force;
  color col;
  PVector k;
  int type; // 1-Planet, 2-Sysytem2, 3-System3
  int note1 = -1, note2 = -1, note3 = -1;
  PShape globe0, globe1, globe2, globe3;
  Boolean impacting;

  //costruttore
  Particle(float x, float y, float z, float mass, int type, int note1, int note2, int note3) {
    this.position = new PVector(x, y, z);
    this.axRotation = new PVector(random(0, TWO_PI), random(0, TWO_PI), random(0, TWO_PI)); // random rotated axis of the single planet
    this.axRotation1 = new PVector(random(0, TWO_PI), random(0, TWO_PI), random(0, TWO_PI)); // random rotated axis of the single planet
    this.axRotation2 = new PVector(random(0, TWO_PI), random(0, TWO_PI), random(0, TWO_PI)); // random rotated axis of the single planet
    this.angleAxisRot = 0; // angle of rotation of planets around their axis
    k = new PVector(1, 1, 1);
    k.normalize();
    this.mass = mass;
    impacting = false;
    this.radius = mass;
    float rot;
    if (random(1)>0.5) {
      rot = PI/2;
    } else {
      rot = -PI/2;
    }
    velocity = position.copy().rotate(rot);
    float mag = 0;
    if (position.mag()>0) {
      mag = sqrt(massone*G*(2/position.mag() - 1/position.mag()));
    }
    velocity.setMag(mag);
    force = new PVector();

    //Setting the type. 1-Planet, 2-Sysytem2, 3-System3
    this.type = type;
    this.note1 = note1;
    this.note2 = note2;
    this.note3 = note3;

    noStroke();
    if (this.type == 1) {
      globe1 = createShape(SPHERE, this.radius);
      globe1.setTexture(img[this.note1-1]);
    } else if (this.type == 2) {
      globe1 = createShape(SPHERE, this.radius);
      globe1.setTexture(img[this.note1-1]);
      globe2 = createShape(SPHERE, this.radius/1.5);
      globe2.setTexture(img[this.note2-1]);
      globe3 = createShape(SPHERE, this.radius/2);
    } else if (this.type == 0) {
      this.radius = 70;
      noStroke();
      globe0 = createShape(SPHERE, this.radius);
      globe0.setTexture(img[12]);
    }
  }

  //update particle position
  void update() {
    velocity.add(force.div(mass));
    position.add(velocity);
    force.mult(0);
  }

  void setGlobe3(int note) {
    globe3.setTexture(img[note-1]);
  }

  void applyBruteForce(PVector f) {
    force.add(f);
  }

  void applyForce(PVector f) {
    f.setMag(constrain(f.mag(), 0, forceConstrain));
    force.add(f);
  }

  PVector getMomentum() {
    PVector momentum = PVector.mult(velocity, mass);
    return momentum;
  }

  ArrayList<Float> getNotes() {
    ArrayList notesList = new ArrayList<Float>();
    if (notes.get(this.note1) > notes.get(this.note2)) {
      notesList.add(notes.get(this.note1));
      //notesList.add(notes.get(this.note2)*2);
      notesList.add(notes.get(this.note2)+12);
    } else {
      notesList.add(notes.get(this.note1));
      notesList.add(notes.get(this.note2));
    }
    if (this.note3 != -1) {
      if (notes.get(this.note1) > notes.get(this.note3)) {
        //notesList.add(notes.get(this.note3)*2);
        notesList.add(notes.get(this.note3)+12);
      } else {
        notesList.add(notes.get(this.note3));
      }
    }
    return notesList;
  }
  
  //draw the particle
  void display() {
    //Draw single Planet
    if (this.type == 1) {
      push();
      translate(position.x, position.y, position.z);
      rotateX(this.axRotation.x);
      rotateY(this.axRotation.y);
      rotateZ(this.axRotation.z);
      rotate(angleAxisRot/60);
      shape(globe1);
      pop();
    }
    //Draw System with one orbiting planet
    else if (this.type == 2) {
      // big planet
      push();
      translate(position.x, position.y, position.z);
      if (this.scale <= (this.time)) {
        scale(this.scale/(this.time));
        this.scale++;
      }
      rotateX(this.axRotation.x);
      rotateY(this.axRotation.y);
      rotateZ(this.axRotation.z);
      rotate(angleAxisRot/60);
      shape(globe1);
      pop();

      angleAxisRot++;

      // little planet 1
      push();
      translate(this.position.x, this.position.y, this.position.z);
      rotateX(this.axRotation1.x);
      rotateY(this.axRotation1.y);
      rotateZ(this.axRotation1.z);
      rotate(angleAxisRot/60);
      push();
      scale(this.scale/(this.time));
      stroke(128, 128, 128);
      noFill();
      circle(0, 0, 2*2.5*this.mass);
      pop();
      currentPos = lerp(currentPos, 2.5*this.mass, 0.01);
      translate(currentPos, 0);
      scale(this.scale/(this.time));
      shape(globe2);
      pop();
    }
    //Draw System with two orbiting planets
    else if (this.type == 3) {
      // big planet
      push();
      translate(position.x, position.y, position.z);
      rotateX(this.axRotation.x);
      rotateY(this.axRotation.y);
      rotateZ(this.axRotation.z);
      rotate(angleAxisRot/60);
      shape(globe1);
      pop();

      angleAxisRot++;

      // little planet 1
      push();
      translate(this.position.x, this.position.y, this.position.z);
      rotateX(this.axRotation1.x);
      rotateY(this.axRotation1.y);
      rotateZ(this.axRotation1.z);
      rotate(angleAxisRot/60);
      push();
      stroke(128, 128, 128);
      noFill();
      circle(0, 0, 2*2.5*this.mass);
      pop();
      translate(2.5*this.mass, 0);
      shape(globe2);
      pop();

      //little planet 2

      push();
      translate(this.position.x, this.position.y, this.position.z);
      if (scale <= (time)) {
        scale(scale/(time));
        scale++;
      }
      rotateX(this.axRotation2.x);
      rotateY(this.axRotation2.y);
      rotateZ(this.axRotation2.z);
      rotate(angleAxisRot/60);
      push();
      scale(scale/(time));
      stroke(128, 128, 128);
      noFill();
      circle(0, 0, 2*3*this.mass);
      pop();
      translate(3*this.mass, 0);
      scale(scale/(time));
      shape(globe3);
      pop();
    }
    //Draw buco nero
    else if (this.type == 0) {
      push();
      translate(position.x, position.y, position.z);
      rotateX(this.axRotation.x);
      rotateY(this.axRotation.y);
      rotateZ(this.axRotation.z);
      rotate(angleAxisRot/120);
      //scale(this.radius);
      shape(globe0);
      pop();
    } else println("Error on type draw");
    angleAxisRot++;
  }

  void higlight() {
    push();
    translate(position.x, position.y, position.z);
    fill(255, 255, 153, 50);
    sphere(250);
    pop();
  }
}
