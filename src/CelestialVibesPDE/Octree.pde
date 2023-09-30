class Octree {
  PVector position;
  int capacity;
  float size;
  ArrayList<Particle> particles;
  Octree[] children;
  boolean divided;
  color col;
  float totalMass;
  PVector centerOfMass;

  Octree(PVector position, int capacity, float size) {
    this.position = position;
    this.size = size;
    this.capacity = capacity;
    particles = new ArrayList<Particle>();
    children = new Octree[8];
    this.divided = false;
    col = color(255);
    this.centerOfMass = new PVector();
    this.totalMass = 0;
  }


  boolean contains(Particle particle) {
    float minX = position.x - size/2;
    float minY = position.y - size/2;
    float minZ = position.z - size/2;
    float maxX = position.x + size/2;
    float maxY = position.y + size/2;
    float maxZ = position.z + size/2;

    return particle.position.x >= minX && particle.position.x <= maxX &&
      particle.position.y >= minY && particle.position.y <= maxY &&
      particle.position.z >= minZ && particle.position.z <= maxZ;
  }


  void subdivide() {
    float subSize = size / 2;
    float x = position.x;
    float y = position.y;
    float z = position.z;
    children[0] = new Octree(new PVector(x - subSize/2, y - subSize/2, z + subSize/2), capacity, subSize);
    children[1] = new Octree(new PVector(x + subSize/2, y - subSize/2, z + subSize/2), capacity, subSize);
    children[2] = new Octree(new PVector(x - subSize/2, y + subSize/2, z + subSize/2), capacity, subSize);
    children[3] = new Octree(new PVector(x + subSize/2, y + subSize/2, z + subSize/2), capacity, subSize);
    children[4] = new Octree(new PVector(x - subSize/2, y - subSize/2, z - subSize/2), capacity, subSize);
    children[5] = new Octree(new PVector(x + subSize/2, y - subSize/2, z - subSize/2), capacity, subSize);
    children[6] = new Octree(new PVector(x - subSize/2, y + subSize/2, z - subSize/2), capacity, subSize);
    children[7] = new Octree(new PVector(x + subSize/2, y + subSize/2, z - subSize/2), capacity, subSize);
    this.divided = true;
  }


  int getIndex(Particle particle) {
    int index = -1;
    float x = position.x;
    float y = position.y;
    float z = position.z;
    boolean top = particle.position.y <= y;
    boolean bottom = particle.position.y > y;
    boolean left = particle.position.x <= x;
    boolean right = particle.position.x > x;
    boolean front = particle.position.z > z;
    boolean back = particle.position.z <= z;
    if (front && left && top) {
      index = 0;
    } else if (front && right && top) {
      index = 1;
    } else if (front && left && bottom) {
      index = 2;
    } else if (front && right && bottom) {
      index = 3;
    } else if (back && left && top) {
      index = 4;
    } else if (back && right && top) {
      index = 5;
    } else if (back && left && bottom) {
      index = 6;
    } else if (back && right && bottom) {
      index = 7;
    }
    return index;
  }


  void addParticle(Particle particle) {
    if (!contains(particle)) {
      return;
    }

    particles.add(particle);

    if (particles.size() <= this.capacity && !this.divided) {
      return;
    } else {
      if (!this.divided) {
        subdivide();
      }
      for (int i = particles.size()-1; i>=0; i--) {
        Particle p = particles.get(i);
        int index = getIndex(p);
        if (index!=-1) {
          this.children[index].addParticle(p);
        }
        particles.remove(i);
      }
    }
  }


  void leavesList() {
    if (this.divided) {
      for (Octree child : this.children) {
        child.leavesList();
      }
    } else {
      if (this.particles.size() > 0) leaves.add(this);
    }
  }

  String typeOfImpact(Particle p1, Particle p2) {
    String strType = "";
    if (p1.type == 1 && p2.type == 1) {
      strType = "pp";
    } else if (p1.type == 1 && p2.type == 2) {
      strType = "ps";
    } else if (p1.type == 2 && p2.type == 1) {
      strType = "sp";
    } else if (p1.type != 1 && p2.type != 1) {
      strType = "ss";
    } else if (p1.type == 1 && p2.type == 3) {
      strType = "p_s3";
    } else if (p1.type == 3 && p2.type == 1) {
      strType = "s3_p";
    } else {
    }//println("Error on Impact");
    return strType;
  }

  void impactPP(Particle Planet, Particle otherPlanet) {
    int note1 = Planet.note1;
    int note2 = otherPlanet.note1;
    PVector difference = new PVector();
    difference = PVector.sub(Planet.position, otherPlanet.position);
    difference.setMag(Planet.radius);
    PVector systemPos = PVector.add(Planet.position, difference);
    float systemMass = Planet.mass + otherPlanet.mass;
    Particle system = new Particle(systemPos.x, systemPos.y, systemPos.z, systemMass, 2, Planet.note1, otherPlanet.note1, -1);
    if (Planet.getMomentum().mag() >= otherPlanet.getMomentum().mag()) {
      system.velocity = Planet.velocity.copy();
    } else {
      system.velocity = otherPlanet.velocity.copy();
    }
    globalParticles.remove(Planet);
    globalParticles.remove(otherPlanet);
    globalParticles.add(system);
    globalSystems.add(system);
    systemsNotesOsc();
  }


  void impactPS(Particle Planet, Particle System) {
    float newSystemMass = Planet.mass + System.mass;
    System.type = 3;
    System.note3 = Planet.note1;
    System.mass = newSystemMass;
    System.scale = 0;
    System.setGlobe3(Planet.note1);
    globalParticles.remove(Planet);
    systemsNotesOsc();
  }


  void calculateImpact(ArrayList<Octree> leaves) {
    for (Octree oc : leaves) {
      for (Particle p : oc.particles) {
        for (Particle s : oc.particles) {
          if (oc.particles.indexOf(s) > oc.particles.indexOf(p)) {
            float distance = PVector.dist(p.position, s.position);
            float radiiSum = p.radius + s.radius;
            if (distance <= radiiSum && (p.impacting == false && s.impacting == false)) {
              p.impacting = true;
              s.impacting = true;
              String impactType = typeOfImpact(p, s);
              ArrayList<Float> nLead = new ArrayList<Float>();
              String strLead = "";
              OscMessage msgLead = new OscMessage("/lead_notes");
              switch (impactType) {
                // IMPACT PLANET - PLANET
              case "pp":
                int note1 = p.note1;
                int note2 = s.note1;
                // 1_st case: No system has been created ==> foundScale = 0; rootNote = 0;
                if (globalSystems.isEmpty()) {
                  int collision = probability(note1, note2);

                  if (collision != 0) { // A collision is happening
                    rootNote = collision;

                    //send OSC message with rootNote

                    // in the collision variable the winning note is stored
                    if (collision == p.note1) { //particle p has the winning note
                      impactPP(p, s);
                    } else { //particle s has the winning note
                      impactPP(s, p);
                    }
                  }
                }
                // 2_nd case: at least one system has been created and no scale has been found, but we have a rootNote != 0
                // ==> we have to check for the scale also in this situation
                else if (foundScale == 0) {
                  if (rootNoteSatisfied(note1, note2)) {
                    int collision = probability(note1, note2);

                    if (scaleCounter % 2 != 0) { //per evitare la collisione di due pianeti che rientrano in entrambe le scale
                      if (collision == p.note1) { //particle p has the winning note
                        impactPP(p, s);
                      } else if (collision == s.note1){ //particle s has the winning note
                        impactPP(s, p);
                      }
                    }
                  }
                }
                // 3_rd case: both scaleFound and rootNote are != 0
                else {
                  if (scaleSatisfied(note1, note2)) {
                    int collision = probability(note1, note2);
                    if (collision == p.note1) { //particle p has the winning note
                      impactPP(p, s);
                    } else if (collision == s.note1){ //particle s has the winning note
                      impactPP(s, p);
                    }
                  }
                }
                break;

                // IMPACT PLANET - SYSTEM
              case "ps":
                int note1_ps = s.note1;
                int note2_ps = s.note2;
                int note3_ps = p.note1;
                if (scaleSatisfiedForPS(note1_ps, note2_ps, note3_ps)) {
                  if (probabilityPS(note3_ps, note1_ps) && probabilityPS(note3_ps, note2_ps)) {
                    impactPS(p, s);
                  }
                }
                break;

                // IMPACT SYSTEM - PLANET
              case "sp":  // in this case the particle s is the planet and the particle p is the system
                int note1_sp = p.note1;
                int note2_sp = p.note2;
                int note3_sp = s.note1;
                if (scaleSatisfiedForPS(note1_sp, note2_sp, note3_sp)) {
                  if (probabilityPS(note3_sp, note1_sp) && probabilityPS(note3_sp, note2_sp)) {
                    impactPS(s, p);
                    //println(impactType);
                  }
                }
                break;

                // IMPACT SYSTEM - SYSTEM
              case "ss":
                break;
                
                // IMPACT PLANET - SYSTEM_3 (made by 3 planets)
              case "p_s3":
                nLead = s.getNotes();
                if (nLead_old.size() != 0) {
                  if (!nLead.equals(nLead_old)) {
                    nLead_old = nLead;
                    strLead = nLead.toString();
                    msgLead.add(strLead);
                    oscP5.send(msgLead, myRemoteLocation);
                  }
                } else {
                  nLead_old = nLead;
                  strLead = nLead.toString();
                  msgLead.add(strLead);
                  oscP5.send(msgLead, myRemoteLocation);
                }

                break;

                // IMPACT SYSTEM_3 - PLANET, this case can be linked to the previous
              case "s3_p":
                nLead = p.getNotes();
                if (nLead_old.size() != 0) {
                  if (!nLead.equals(nLead_old)) {
                    nLead_old = nLead;
                    strLead = nLead.toString();
                    msgLead.add(strLead);
                    oscP5.send(msgLead, myRemoteLocation);
                  }
                } else {
                  nLead_old = nLead;
                  strLead = nLead.toString();
                  msgLead.add(strLead);
                  oscP5.send(msgLead, myRemoteLocation);
                }

                break;
              default:
              }
            } else {
              p.impacting = false;
              s.impacting = false;
            }
          }
        }
      }
    }
  }


  int probability(int note1, int note2) {
    int dist1 = abs(note2 - note1);
    int dist2 = 12 - dist1;
    int distWin;
    int firstNote;
    int winner;
    float ran = random(0, 100);

    if (ran <= probInterval.get(Integer.toString(dist1)+"&"+Integer.toString(dist2))) {
      if (note1 <= note2) {
        distWin = dist1;
        firstNote = note1;
        winner = winning(distWin, firstNote);
      } else {
        distWin = dist1;
        firstNote = note2;
        winner = winning(distWin, firstNote);
      }
    } else {
      if (note1 <= note2) {
        distWin = dist2;
        firstNote = note2;
        winner = winning(distWin, firstNote);
      } else {
        distWin = dist2;
        firstNote = note1;
        winner = winning(distWin, firstNote);
      }
    }
    // se c'è un vincitore e sia scala che rootNote non sono ancora state definita, entra in questo if
    // per vedere se la scala sarà definita dal primo impatto o meno
    if (winner != 0 && foundScale == 0 && rootNote == 0 && (distWin == 4 || distWin == 9 || distWin == 11)) {
      foundScale = 1; // Major
    }
    if (winner != 0 && foundScale == 0 && rootNote == 0 && (distWin == 3 || distWin == 8 || distWin == 10)) {
      foundScale = 2; // Minor
    }
    // se c'è un vincitore e la scala non è ancora state definita, ma la rootNote sì, entra in questo if
    if (winner != 0 && foundScale == 0 && rootNote != 0) {
      if ((note1 > rootNote && ( (note1 - rootNote) == 4 || (note1 - rootNote) == 9 ||  (note1 - rootNote) == 11 ) ) ||
        (note2 > rootNote && ( (note2 - rootNote) == 4 || (note2 - rootNote) == 9 ||  (note2 - rootNote) == 11 ) ) ||
        (note1 < rootNote && ( (note1 - rootNote) == (-8) || (note1 - rootNote) == (-3) ||  (note1 - rootNote) == (-1) ) ) ||
        (note2 < rootNote && ( (note2 - rootNote) == (-8) || (note2 - rootNote) == (-3) ||  (note2 - rootNote) == (-1) ) ) ) {
        foundScale = 1; // Major
        scaleCounter += 1;
      }
      if ((note1 > rootNote && ( (note1 - rootNote) == 3 || (note1 - rootNote) == 8 ||  (note1 - rootNote) == 10 ) ) ||
        (note2 > rootNote && ( (note2 - rootNote) == 3 || (note2 - rootNote) == 8 ||  (note2 - rootNote) == 10 ) ) ||
        (note1 < rootNote && ( (note1 - rootNote) == (-9) || (note1 - rootNote) == (-4) ||  (note1 - rootNote) == (-2) ) ) ||
        (note2 < rootNote && ( (note2 - rootNote) == (-9) || (note2 - rootNote) == (-4) ||  (note2 - rootNote) == (-2) ) ) ) {
        foundScale = 2; // Minor
        scaleCounter += 1;
      }
    }
    return winner; // 0: no winner  ||  note1  ||  note2;
  }


  boolean probabilityPS(int note2, int note1) {
    int dist1 = abs(note2 - note1);
    int dist2 = 12 - dist1;
    int distWin;
    int firstNote;
    int winner;
    float ran = random(0, 100);

    if (ran <= probInterval.get(Integer.toString(dist1)+"&"+Integer.toString(dist2))) {
      if (note1 <= note2) {
        distWin = dist1;
        firstNote = note1;
        winner = winning(distWin, firstNote);
      } else {
        distWin = dist1;
        firstNote = note2;
        winner = winning(distWin, firstNote);
      }
    } else {
      if (note1 <= note2) {
        distWin = dist2;
        firstNote = note2;
        winner = winning(distWin, firstNote);
      } else {
        distWin = dist2;
        firstNote = note1;
        winner = winning(distWin, firstNote);
      }
    }
    if (winner != 0) {
      return true;
    } else {
      return false;
    }
  }


  int winning(int dist, int note) {
    float ran = random(0, 100);
    if (ran <= probWin.get(Integer.toString(dist))) {
      return note;
    } else {
      return 0;
    }
  }


  Boolean rootNoteSatisfied(int note1, int note2) {
    return
      (  ( ((note1 - rootNote) >= 0 && (note1 - rootNote) != 1 && (note1 - rootNote) != 6) ||
      ((note1 - rootNote) < 0 && (note1 - rootNote) != (-6) && (note1 - rootNote) != (-11)) )
      &&
      ( ((note2 - rootNote) >= 0 && (note2 - rootNote) != 1 && (note2 - rootNote) != 6) ||
      ((note2 - rootNote) < 0 && (note2 - rootNote) != (-6) && (note2 - rootNote) != (-11)) )  );
  }


  Boolean scaleSatisfied(int note1, int note2) {
    if (foundScale == 1) {
      return
        ( ((note1 - rootNote) >= 0 && (note1 - rootNote) != 1 && (note1 - rootNote) != 3 &&
        (note1 - rootNote) != 6 && (note1 - rootNote) != 8 && (note1 - rootNote) != 10) ||
        ((note1 - rootNote) < 0 && (note1 - rootNote) != (-11) && (note1 - rootNote) != (-9) &&
        (note1 - rootNote) != (-6) && (note1 - rootNote) != (-4) && (note1 - rootNote) != (-2)) )
        &&
        ( ((note2 - rootNote) >= 0 && (note2 - rootNote) != 1 && (note2 - rootNote) != 3 &&
        (note2 - rootNote) != 6 && (note2 - rootNote) != 8 && (note2 - rootNote) != 10) ||
        ((note2 - rootNote) < 0 && (note2 - rootNote) != (-11) && (note2 - rootNote) != (-9) &&
        (note2 - rootNote) != (-6) && (note2 - rootNote) != (-4) && (note2 - rootNote) != (-2)) );
    }
    if (foundScale == 2) {
      return
        ( ((note1 - rootNote) >= 0 && (note1 - rootNote) != 1 && (note1 - rootNote) != 4 &&
        (note1 - rootNote) != 6 && (note1 - rootNote) != 9 && (note1 - rootNote) != 11) ||
        ((note1 - rootNote) < 0 && (note1 - rootNote) != (-11) && (note1 - rootNote) != (-8) &&
        (note1 - rootNote) != (-6) && (note1 - rootNote) != (-3) && (note1 - rootNote) != (-1)) )
        &&
        ( ((note2 - rootNote) >= 0 && (note2 - rootNote) != 1 && (note2 - rootNote) != 4 &&
        (note2 - rootNote) != 6 && (note2 - rootNote) != 9 && (note2 - rootNote) != 11) ||
        ((note2 - rootNote) < 0 && (note2 - rootNote) != (-11) && (note2 - rootNote) != (-8) &&
        (note2 - rootNote) != (-6) && (note2 - rootNote) != (-3) && (note2 - rootNote) != (-1)) );
    } else {
      return false;
    }
  }

  Boolean scaleSatisfiedForPS (int note1, int note2, int note3) {
    if (foundScale == 1) {
      return
        (
        (note3 != note1)
        &&
        (note3 != note2)
        &&
        ((note3 - rootNote) >= 0 && (note3 - rootNote) != 1 &&
        (note3 - rootNote) != 3 && (note3 - rootNote) != 6 &&
        (note3 - rootNote) != 8 && (note3 - rootNote) != 10)
        ||
        ((note3 - rootNote) < 0 && (note3 - rootNote) != (-11) &&
        (note3 - rootNote) != (-9) && (note3 - rootNote) != (-6) &&
        (note3 - rootNote) != (-4) && (note3 - rootNote) != (-2))
        );
    }
    if (foundScale == 2) {
      return
        (
        (note3 != note1)
        &&
        (note3 != note2)
        &&
        ((note3 - rootNote) >= 0 && (note3 - rootNote) != 1 &&
        (note3- rootNote) != 4 && (note3 - rootNote) != 6 &&
        (note3 - rootNote) != 9 && (note3 - rootNote) != 11)
        ||
        ((note3 - rootNote) < 0 && (note3 - rootNote) != (-11) &&
        (note3 - rootNote) != (-8) && (note3 - rootNote) != (-6) &&
        (note3 - rootNote) != (-3) && (note3 - rootNote) != (-1))
        );
    } else {
      return false;
    }
  }

  // FUNCTIONS TO SEND OSC MESSAGES TO SUPERCOLLIDER

  void systemsNotesOsc() {
    ArrayList<ArrayList<Float>> n = new ArrayList<ArrayList<Float>>();
    String str = "";
    for (int i = 0; i< globalSystems.size(); i++) {
      n.add(globalSystems.get(i).getNotes());
    }
    for (int j = 0; j<n.size(); j++) {
      str+= n.get(j).toString()+":";
    }
    OscMessage msg = new OscMessage("/values");
    msg.add(str);
    oscP5.send(msg, myRemoteLocation);
  }

  PVector calculateCenterOfMass() {
    this.totalMass = 0;
    this.centerOfMass = new PVector();
    if (this.divided) {
      for (Octree child : children) {
        PVector childCenter = child.calculateCenterOfMass();
        this.centerOfMass.add(PVector.mult(childCenter, child.totalMass));
        this.totalMass += child.totalMass;
      }
    } else {
      for (Particle p : this.particles) {
        this.centerOfMass.add(PVector.mult(p.position, p.mass));
        this.totalMass += p.mass;
      }
    }
    if (this.totalMass>0) {
      this.centerOfMass.div(this.totalMass);
    }
    return this.centerOfMass;
  }


  void calculateForce(Particle particle, float threshold) {
    if (this.divided) {
      float distance = PVector.dist(particle.position, this.calculateCenterOfMass());
      float ratio = size / distance;

      if (ratio < threshold) {
        PVector force = calculateForceFromNode(particle);
        particle.applyForce(force);
      } else {
        for (Octree child : children) {
          child.calculateForce(particle, threshold);
        }
      }
    } else {
      for (Particle otherParticle : particles) {
        if (otherParticle != particle) {
          PVector force = calculateForceBetweenParticles(particle, otherParticle);
          particle.applyForce(force);
        }
      }
    }
  }


  PVector calculateForceFromNode(Particle particle) {
    PVector force = new PVector(0, 0, 0);
    float distance = PVector.dist(particle.position, this.centerOfMass);
    float magnitude = G * (particle.mass * this.totalMass) / (distance * distance);
    PVector direction = PVector.sub(this.centerOfMass, particle.position);
    direction.normalize();
    force = PVector.mult(direction, magnitude);
    return force;
  }


  PVector calculateForceBetweenParticles(Particle particle1, Particle particle2) {
    PVector force = new PVector(0, 0, 0);
    float distance = PVector.dist(particle1.position, particle2.position);
    float magnitude = G * (particle1.mass * particle2.mass) / (distance * distance);
    PVector direction = PVector.sub(particle2.position, particle1.position);
    direction.normalize();
    force = PVector.mult(direction, magnitude);
    return force;
  }


  void drawOctree() {
    push();
    noFill();
    stroke(0, 255, 0);
    strokeWeight(0.7);
    translate(position.x, position.y, position.z);
    box(size);
    pop();
    if (this.divided) {
      for (Octree child : children) {
        child.drawOctree();
      }
    }
  }
}
