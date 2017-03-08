Line[] lines;
PVector pv = new PVector();
boolean drift;
boolean freeze;
float alph;
PImage img;
int counter;
int side = 300;
int x_side, y_side;
int [] sign;

void setup() {
  frameRate(30);
  background(255);
  frameCount = 70;
  strokeWeight(2);
  counter = 0;
  size(window.innerWidth, window.innerHeight);
  //size(600, 400);
  sign = new int[2];
  sign[0] = -1;
  sign[1] = 1;
  x_side = 1 + width/side;
  y_side = 1 + height/side;
  float fHeight = float(height);
  float fWidth = float(width);

  freeze = false;
  drift = false;
  noFill();
  //img = loadImage("rectangles_background2.png");
  //for(int i=0; i<x_side; i++) for(int j=0; j<y_side; j++) image(img, i*side, j*side);
  float aspect = fHeight/fWidth;
  float mapAspect = 485./700.;
  int mapWidth = int(fWidth);
  int mapHeight = int(fHeight * 0.8);
  int headMar = int(fHeight * 0.1);
  
  if (mapAspect - aspect > 0) { // wide screen
    mapWidth = int(0.8*fHeight/mapAspect);
    if (mapWidth%2 == 1) mapWidth -= 1;
  }
  if (mapAspect - aspect < 0) { // square screen
    mapHeight = int(fWidth * mapAspect);
    if (mapHeight%2 == 1) mapHeight -= 1;
  }
  float xmin = -480; // input data coordinate boundaries
  float xmax = 1445;
  float ymin = -175;
  float ymax = 1160;
  int xmar = (width - mapWidth) / 2; // map margins
  int ymar = (int(fHeight) - mapHeight) / 2;
  ;
  float x_scale = (fWidth - xmar*2) / (xmax - xmin); // scales objects
  float y_scale = (fHeight - ymar*2) / (ymax - ymin);

  // READ IN DATA
  String [] lineDataIn = loadStrings("data/lines.csv");
  String [] segDataIn = loadStrings("data/segments.csv");
  String [] nodeDataIn = loadStrings("data/nodes.csv");
  int sStart = 0;
  int nStart = 0;
  int nPos = 0;
  int lineID_n = 0;
  int segID_n = 0;
  PVector p = new PVector();
  PVector segPos = new PVector();
  PVector n = new PVector();

  lines = new Line[lineDataIn.length];
  ArrayList <PVector> segs;

  // iterate through Lines
  for (int i=0; i<lineDataIn.length; i++) {
    String [] thisLine = split(lineDataIn[i], ",");
    int lineID = int(thisLine[0]);
    color c = color(int(thisLine[2]), int(thisLine[3]), int(thisLine[4]));
    lines[int(thisLine[0])] = new Line(lineID, thisLine[1], c, int(thisLine[5]));
    segs = new ArrayList();

    // iterate through Segments
    for (int j=sStart; j<segDataIn.length; j++) {
      String [] thisSeg = split(segDataIn[j], ",");
      int lineID_s = int(thisSeg[0]);
      int segID = int(thisSeg[1]);
      float x = map(float(thisSeg[2]), xmin, xmax, xmar, width-xmar);
      float y = headMar + map(float(thisSeg[3]), ymin, ymax, ymar, height-ymar);
      p.set(x, y, 0);
      if (lineID_s == lineID) { // segment belongs to current Line
        segPos.set(p.x, p.y, 0);
        segs = new ArrayList();

        // iterate through Nodes
        while (lineID_n == lineID && segID_n == segID && nPos < nodeDataIn.length) {
          String [] thisNode = split(nodeDataIn[nPos], ",");
          lineID_n = int(thisNode[0]);
          segID_n = int(thisNode[1]);
          if (lineID_n == lineID && segID_n == segID) {
            n = new PVector(x_scale*float(thisNode[2]), y_scale*float(thisNode[3]));
            segs.add(n);
            nPos++;
          }
        }
        lines[lineID].segs[segID] = new Segment(segs, segPos);
      }
      else { // segment belongs to the next Line
        sStart = j; // log array position
        j = segDataIn.length; // escape loop
      }
    }
  }
}

void draw() {
  background(255);
  if(frameCount == 300) {
    frameCount = 70;
    for (Line l:lines) {
      l.newcolor();
      for (Segment s:l.segs) s.initialise();
    }
  }
  //for(int i=0; i<x_side; i++) for(int j=0; j<y_side; j++) image(img, i*side, j*side);

  if (frameCount==180 || freeze) {
    freeze = true;
    counter++;
    frameCount = 179;
    if (counter == 50) {
      freeze = false;
      counter = 0;
      frameCount = 180;
    }
  }

  alph = 0.5 - cos(radians(frameCount))/2;
  for (Line l:lines) for (Segment s:l.segs) {
    stroke(l.col);
    s.p = s.v.get();
    s.p.mult(alph);
    s.p.add(s.o);
    pushMatrix();
    translate(s.p.x, s.p.y);
    beginShape();
    for (PVector v:s.n) vertex(v.x, v.y);
    endShape();
    popMatrix();
  }
}

class Line {
  int id;
  color col;
  String name;
  PVector v = new PVector(0, 0);
  Segment [] segs;

  Line(int ID, String NAME, color C, int S) {
    id = ID;
    name = NAME;
    segs = new Segment[S];
    newcolor();
  }
  void newcolor(){
  col = color(random(255),random(255),random(255));
  }
}

class Segment {
  PVector[] n; // node relative positions
  PVector h, p, o, v, d, dv, a, g;   // pos, origin, speed, acc

  Segment(ArrayList <PVector> data, PVector P) {
    n = new PVector[data.size()];
    for (int i=0; i<data.size(); i++) {
      n[i] = new PVector(data.get(i).x, data.get(i).y);
    }
    h = new PVector (P.x, P.y);
    a = new PVector();
    p = new PVector();
    initialise();
  }
  
  void initialise(){
    float x = 0;
    float w = float(width);
    x = random(w, w*5);
    x *= sign[int(random(2))];
    x += width/2;
    o = new PVector(x, h.y);
    v = PVector.sub(h, o);
  }
}