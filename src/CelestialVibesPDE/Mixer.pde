import java.lang.Math;

int muteColor = unhex("ffff7d00");
int soloColor = unhex("ffffdd00");
int bgColor = unhex("ff2D4A54");

Fader bassSli, padSli, arpSli, masterSli;

float[] volumes = {1, 1, 1, 1, 1};

float[] channelVolumes = {1, 1, 1, 1, 1};

int sliderPaddingX = 60;
int labelPaddingY = 10;
int sliderPaddingY = 40;
int buttonPaddingY = 10;


void setupMixer() {
  //PFont.list();
  int sliderPosY = height - 200;
  f2 = createFont("Arial", 25, true);
  f3 = createFont("Arial", 20, true);

  bassSli = new Fader("Bass", 1);
  padSli = new Fader("Pad", 2);
  arpSli = new Fader("Arp", 3);
  masterSli = new Fader("Master", 4);
  
  masterSli.setPosition(sliderPaddingX, sliderPosY);
  bassSli.setPosition((int)masterSli.getPosition()[0]+bassSli.getWidth()+sliderPaddingX*2, sliderPosY);
  padSli.setPosition((int)bassSli.getPosition()[0]+bassSli.getWidth()+sliderPaddingX, sliderPosY);
  arpSli.setPosition((int)padSli.getPosition()[0]+padSli.getWidth()+sliderPaddingX, sliderPosY);
  
  cp5.setAutoDraw(false);
}

float sum(float[] a) {
  float sum=0;
  for (int i=0; i<a.length; i++) {
    sum = sum+a[i];
  }
  return sum;
}

void showMixer() {
  bassSli.show();
  padSli.show();
  arpSli.show();
  masterSli.show();
};

void hideMixer() {
  bassSli.hide();
  padSli.hide();
  arpSli.hide();
  masterSli.hide();
}

// MYFADER
class Fader {
  String name;
  Slider fader;
  float volume;
  int id;

  Fader(String theName, int theId) {
    id = theId;
    name = theName;
    fader = cp5.addSlider(name)
      .setSize(width/60, height/8)
      .setRange(0, 3)
      .setValue(2)
      .setSliderMode(Slider.FLEXIBLE)
      .setLabelVisible(false)
      .setColorForeground(unhex("ffff006d"))
      .setColorBackground(bgColor)
      ;
  }

  float getVolume() {
    float val = cp5.getController(name).getValue();
    double vol =  20*Math.log10((double)map(val/2, 0, 3, 0.0001, 3));
    float a = (float)vol;
    a = (float)round(a*100)/100;
    return a;
  }

  int getWidth() {
    return cp5.getController(name).getWidth();
  }

  int getHeight() {
    return cp5.getController(name).getHeight();
  }

  float[] getPosition() {
    return cp5.getController(name).getPosition();
  }

  void setPosition(int x0, int y0) {
    fader.setPosition(x0, y0);
  }

  void setValue(float theVal) {
    double val = constrain(theVal, 0.0001, 1.5);
    volumes[id] = (float)val;

    double vol1 = 20*Math.log10(val);

    float vol = (float)vol1;
    vol = pow(10, vol/20);

    float faderVal = map(vol, 0, 1.5, 0, 3);

    fader.setValue(faderVal);
  };

  void update() {
    volumes[id] = pow(10, getVolume()/20);
    float xcenter = fader.getPosition()[0]+fader.getWidth()/2;
    String volume = String.valueOf(getVolume());

    if (fader.isVisible()) {
      cam.beginHUD();
      // Name Label
      textAlign(CENTER);
      fill(255);
      textFont(f2);
      textSize(25);
      text(name, xcenter, fader.getPosition()[1]-labelPaddingY);

      // Value label

      textFont(f3);
      textSize(18);
      text(volume + " dB", xcenter, fader.getPosition()[1]+fader.getHeight()+ sliderPaddingY/2);
      cam.endHUD();
    }
    setVolume();
  }

  void show() {
    cp5.getController(name).setVisible(true);
  }

  void hide() {
    cp5.getController(name).setVisible(false);
  }

  boolean isInside() {
    return cp5.getController(name).isInside();
  }
  
  void setVolume(){
      OscMessage msg = new OscMessage("/mixerFader");
      msg.add(name);
      msg.add(getVolume());
      oscP5.send(msg, myRemoteLocation);
  }
}
