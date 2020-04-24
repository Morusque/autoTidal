
// after this sketch is started, you have a few seconds to click on the test.tidal file in an Atom window
// then il will generate random lines of tidal and automatically press on the right keys to send it to supercollider
// it's an extremely ugly way to automate the process and I wish I could skip atom and send lines directly from P5 to an interpreter
// but I didn't successfully find a way to that that yet

import java.awt.AWTException;
import java.awt.Robot;
import java.awt.event.KeyEvent;
import java.awt.event.InputEvent;
import java.awt.AWTKeyStroke;

// import hypermedia.net.*;

Robot robot;


String currentString = "";

float typingDelayMs = 50;

int lastTypingMillis=0;

int toRelease = -1;

int endingPhase = -1;

int shiftPressed = 0;
// 0 = no
// 1 = yes
// 2 = pending release

int nbTracks = 4;

String[] sampleFolders;

String[] limitedSamples;
int[] limitedIndexes;

boolean generateBigFile = false;

// UDP client;

void setup() {
  size(200, 200);
  frameRate(20);
  ArrayList<String> sampleFoldersAL = new ArrayList<String>();
  File[] files = listFiles("bank");
  for (int i = 0; i < files.length; i++) {
    File f = files[i];
    if (f.isDirectory()) {
      sampleFoldersAL.add(f.getName());
    }
  }
  sampleFolders = sampleFoldersAL.toArray(new String[sampleFoldersAL.size()]);
  try {
    robot = new Robot();
  }
  catch (Exception e) {
    println(e);
  }
  shuffleLimitedSamples();
  /*
  try {
   client = new UDP(this);
   // client.listen(false);
   }
   catch (Exception e) {
   println(e);
   }
   */
  if (generateBigFile) {
    ArrayList<String> testLines = new ArrayList<String>();
    testLines.add("hush");
    testLines.add("");
    for (int i=0; i<30; i++) {
      testLines.add(generateLine());
      testLines.add("");
    }
    saveStrings("bigTest.tidal", testLines.toArray(new String[testLines.size()]));
    exit();
  }
  println("start");
}


void draw() {
  if (frameCount>=100) {
    if (frameCount%50==0) {
      String[] ss = new String[1];
      for (int i=0; i<ss.length; i++) {
        if (i%2==1) ss[i] = "";
        else ss[i] = generateLine();
      }
      println("save file");
      saveStrings("test.tidal", ss);
    }
    if (frameCount%50==10) {
      robot.keyPress(KeyEvent.VK_UP);
      println("press UP");
    }
    if (frameCount%50==20) {
      robot.keyRelease(KeyEvent.VK_UP);
      println("release UP");
    }
    if (frameCount%50==30) {
      robot.keyPress(KeyEvent.VK_SHIFT);
      robot.keyPress(KeyEvent.VK_ENTER);
      println("press S+E");
    }
    if (frameCount%50==40) {
      robot.keyRelease(KeyEvent.VK_SHIFT);
      robot.keyRelease(KeyEvent.VK_ENTER);
      println("release S+E");
    }
    /*
    String line = generateLine();
     println(line);
     client.send(line, "127.0.0.1", 57120);
     */
  }
}

void keyPressed() {
}

String generateLine() {
  String s = "";
  float[] probas = new float[]{0.7, 2.0, 0.2};
  float totalProbas = 0;
  for (float p : probas) totalProbas+=p;
  float randomProbValue = random(totalProbas);
  int type = -1;
  float currentThreshold = 0;
  for (int i=0; i<probas.length; i++) {
    if (currentThreshold<randomProbValue) type=i;
    currentThreshold+=probas[i];
  }
  // 0 = silence
  // 1 = sound
  if (type==0) {
    int track = floor(random(nbTracks))+1;
    s += "d"+track+" ";
    s += "silence";
    saveStrings("test.tidal", new String[]{s});
  }
  if (type==1) {
    int track = floor(random(nbTracks))+1;
    int launchType = 0;
    if (random(1)<0.1) launchType = floor(random(2))+1;
    if (launchType==0) s += "d"+track+" ";
    if (launchType==1) s += "anticipate "+track+" ";
    if (launchType==2) s += "xfadeIn "+track+" "+floor(random(16))+1+" ";
    s += "$ ";
    int cats = floor(random(random(4)))+1;
    String catType = (new String[]{"cat", "fastcat", "randcat", "stack"})[floor(random(4))];
    if (cats>1) s += catType+"[";
    for (int cat = 0; cat<cats; cat++) {
      if (random(1)<0.5) {
        int triggerType = floor(random(3));
        if (triggerType==0) s += "every "+floor(random(8)+1)+" ";
        if (triggerType==1) s += "whenmod "+floor(random(16)+1)+" "+floor(random(16)+1)+" ";
        if (triggerType==2) s += "sometimesBy "+random(1)+" ";
        s += "(";
        int funcType = floor(random(6));
        if (funcType==0) s += "rev";
        if (funcType==1) s += "fast "+pow(2, floor(random(-3, 3)));
        if (funcType==2) s += "slow "+pow(2, floor(random(-3, 3)));
        if (funcType==3) s += ((float)floor(random(8.0f))/8.0f)+" <~ ";
        if (funcType==4) s += "degradeBy "+random(1.0f);
        if (funcType==5) {
          s += "const ";
          s += "$ sound ";
          s += "\"";
          s += getSeqDiv(0);
          s += "\"";
        }
        s += ") ";
      }
      s += "(";
      s += "sound ";
      s += "\"";
      String seqDiv = getSeqDiv(0);
      s += seqDiv;
      s += "\"";
      s += ") ";
      s += "# n ";
      s += "\""+getIntSeq(0, 0, 1000)+"\" ";
      s += "# gain \"0.75\" ";
      while (random(1)<0.5) {
        int operatorType = floor(random(2));
        if (operatorType==0) s += "# ";
        if (operatorType==1) s += "|>| ";// TODO review : there might be other operator types
        int funcType = floor(random(22));
        if (funcType==0) s += "gain "+getFloatExpr(0, 0.75);
        if (funcType==1) s += "pan "+getFloatExpr(0, 1);
        if (funcType==2) s += "shape "+getFloatExpr(0, 1);
        if (funcType==3) s += "vowel \""+getVoyelChar()+"\"";
        if (funcType==4) s += "speed \""+getSpeedSeq(0)+"\"";
        if (funcType==5) s += "cutoff "+getFloatExpr(20, 10000);
        if (funcType==6) s += "resonance "+getFloatExpr(0, 1);
        if (funcType==7) s += "bpf "+getFloatExpr(20, 20000);
        if (funcType==8) s += "bandq "+getFloatExpr(0, 1);
        if (funcType==9) s += "crush "+getIntExpr(0, 1);
        if (funcType==10) s += "tremolodepth "+getIntExpr(0, 1);
        if (funcType==11) s += "tremolorate "+getFloatExpr(0, 50);
        if (funcType==12) s += "room "+getFloatExpr(0, 1);
        if (funcType==13) s += "size "+getFloatExpr(0, 1);
        if (funcType==14) s += "dry "+getFloatExpr(0, 1);
        if (funcType==15) s += "phasr "+getFloatExpr(0, 1);
        if (funcType==16) s += "phasdp "+getFloatExpr(0, 1);
        if (funcType==17) s += "up "+getIntExpr(round(random(-32)), round(random(32)));
        if (funcType==18) s += "n "+getNotesExpr();
        if (funcType==19) s += "midinote "+getIntSeq(0, 0, 128);
        if (funcType==20) s += "cut "+floor(random(3));
        if (funcType==21) s += "sustain \""+random(1)+" "+random(1)+"\"";
        s += " ";
      }
      if (cat<cats-1) s+=",";
    }
    if (cats>1) s+="]";
    s += "# orbit "+floor(track-1);
  }
  if (type==2) {
    s += "setcps ";
    s +=constrain(pow(random(1), 1.5)*2, 0.5, 2);
  }
  return s;
}

String getSeqDiv(int level) {
  if (random(1)<0.25) shuffleLimitedSamples();
  String s = "";
  int nbDivs = floor(random(random((16.0/level)))+1+max(1, level));
  for (int i=0; i<nbDivs; i++) {
    int type = floor(random(3));
    // 0 = sample
    // 1 = seq
    // 2 = random
    if (pow(random(1), 1)*5<=(level+2)) type=0;
    if (type==0) {
      if (random(1)<0.75) {
        String sampleFolder = limitedSamples[floor(random(limitedSamples.length))];
        String[] synths = new String[]{"supersaw", "superpwm", "supersquare", "supernoise", "supergong", "superhat", "super808", "superpiano", "superchip"}; 
        if (random(1)<0.05) sampleFolder = synths[floor(random(synths.length))];
        s+=sampleFolder;
        int multType = floor(random(5)); // 0=nothing 1=mult 2=div 3=euclidean 4=randomRemoval
        if (multType == 1) {
          s+="*";
          s+=floor(random(random(5)))+1;
        }
        if (multType == 2) {
          s+="/";
          s+=floor(random(random(5)))+1;
        }
        if (multType == 3) {
          int nA = floor(random(8)+1);
          int nB = nA + floor(random(8)+1);
          s+="(";
          s+=nA;
          s+=",";
          s+=nB;
          s+=")";
        }
        if (multType == 4) {
          s+="?";
        }
      } else {
        s+="~";
      }
      if (random(0.5)<1 && level==0 && i<nbDivs-1) s+= ",";
    }
    if (type==1) {
      s+="[";
      s+=getSeqDiv(level+1);
      s+="]";
    }    
    if (type==2) {
      s+="<";
      s+=getSeqDiv(level+1);
      s+=">";
    }
    s+=" ";
  }
  return s;
}

String[] listFileNames(String dir) {
  File file = new File(dir);
  if (file.isDirectory()) {
    String names[] = file.list();
    return names;
  } else {
    return null;
  }
}

void shuffleLimitedSamples() {
  limitedSamples = new String[floor(random(1, 5))];
  for (int i=0; i<limitedSamples.length; i++) {
    limitedSamples[i] = sampleFolders[floor(random(sampleFolders.length))];
    // if (random(1)<0.9f) limitedSamples[i] = "armoire";
  }
  limitedIndexes = new int[floor(random(1, 5))];
  for (int i=0; i<limitedIndexes.length; i++) {
    limitedIndexes[i] = floor(random(2000));
  }
}

String getVoyelChar() {
  int i = floor(random(5));
  if (i==0) return "a";
  if (i==1) return "e";
  if (i==2) return "i";
  if (i==3) return "o";
  if (i==4) return "u";
  return "";
}

String getFloatExpr(float min, float max) {
  String str = "";
  int type = floor(random(3));
  if (type==0) {
    str += "\""+getFloatSeq(0, min, max)+"\"";
  }
  if (type==1) {
    str+= "(range "+min+" "+max+" $ rand)";
  }
  if (type==2) {
    String oscType = (new String[]{"sine", "tri", "square", "saw"})[floor(random(4))];
    str+= "(density "+random(0, 2)+" $ range "+min+" "+max+" "+oscType+")";
  }
  return str;
}

String getIntExpr(int min, int max) {
  String str = "";
  int type = floor(random(2));
  if (type==0) {
    str += "\""+getIntSeq(0, min, max)+"\"";
  }
  if (type==1) {
    str+= "(irand "+(max-min)+")"+(min>=0?"+":"")+min;
  }
  return str;
}

String getIntSeq(int level, int min, int max) {
  String s ="";
  int nbDivs = floor(random(random((16.0/level)))+max(1, level));
  for (int i=0; i<nbDivs; i++) {
    int type = floor(random(4));
    // 0 = int
    // 1 = seq
    // 2 = random
    if (pow(random(1), 5)*5<=(level+2)) type=0;
    if (type==0) {
      s+=floor(random(min, max));
    }
    if (type==1) {
      s+="[";
      s+=getIntSeq(level+1, min, max);
      s+="]";
    }    
    if (type==2) {
      s+="<";
      s+=getIntSeq(level+1, min, max);
      s+=">";
    }
    if (type==3) {
      s+="{";
      s+=getFloatSeq(level+1, min, max);
      s+="}";
      s+="%"+floor(random(10)+1);
    }    
    s+=" ";
  }
  return s;
}

String getNotesExpr() {
  String str = "";
  int type = floor(random(1));
  if (type==0) {
    str += "\""+getNotesSeq(0)+"\"";
  }
  return str;
}

String getNotesSeq(int level) {
  String s = "";
  int nbDivs = floor(random(random((16.0/level)))+max(1, level));
  String[] notesStr = new String[]{"a", "as", "b", "c", "cs", "d", "ds", "e", "f", "fs", "g", "gs"}; 
  for (int i=0; i<nbDivs; i++) {
    int type = floor(random(2));
    // 0 = single
    // 1 = chord
    if (type==0) {
      s+=notesStr[floor(random(notesStr.length))]+floor(random(1, 5));
      s+="*"+floor(random(1, 5));
    }
    if (type==1) {
      int nbNotes = floor(random(2, 7));
      s+="[";
      for (int j=0; j<nbNotes; j++) {
        s+=notesStr[floor(random(notesStr.length))]+floor(random(1, 5));
        if (j<nbNotes-1) s+=",";
      }
      s+="]";
      s+="*"+floor(random(1, 5));
    }
    s+=" ";
  }
  return s;
}

String getSpeedSeq(int level) {
  String s ="";
  int nbDivs = floor(random(random((16.0/level)))+max(1, level));
  for (int i=0; i<nbDivs; i++) {
    int type = floor(random(4));
    // 0 = sample
    // 1 = seq
    // 2 = random
    if (pow(random(1), 5)*5<=(level+2)) type=0;
    if (type==0) {
      s+=pow(2, floor(random(-3, 3)));
      int multType = floor(random(3)); // 0=nothing 1=mult 2=div
      if (multType == 1) {
        s+="*";
        s+=floor(random(random(5)))+1;
      }
      if (multType == 2) {
        s+="/";
        s+=floor(random(random(5)))+1;
      }
    }
    if (type==1) {
      s+="[";
      s+=getSpeedSeq(level+2);
      s+="]";
    }    
    if (type==2) {
      s+="<";
      s+=getSpeedSeq(level+2);
      s+=">";
    }    
    if (type==3) {
      s+="{";
      s+=getSpeedSeq(level+2);
      s+="}";
      s+="%"+floor(random(10)+1);
    }    
    s+=" ";
  }
  return s;
}

String getFloatSeq(int level, float min, float max) {
  String s ="";
  int nbDivs = floor(random(random((16.0/level)))+max(1, level));
  for (int i=0; i<nbDivs; i++) {
    int type = floor(random(4));
    // 0 = sample
    // 1 = seq
    // 2 = random
    if (pow(random(1), 5)*5<=(level+2)) type=0;
    if (type==0) {
      s+=nf(random(min, max), 1, 2);
      int multType = floor(random(3)); // 0=nothing 1=mult 2=div
      if (multType == 1) {
        s+="*";
        s+=floor(random(random(5)))+1;
      }
      if (multType == 2) {
        s+="/";
        s+=floor(random(random(5)))+1;
      }
    }
    if (type==1) {
      s+="[";
      s+=getFloatSeq(level+1, min, max);
      s+="]";
    }    
    if (type==2) {
      s+="<";
      s+=getFloatSeq(level+1, min, max);
      s+=">";
    }    
    if (type==3) {
      s+="{";
      s+=getFloatSeq(level+1, min, max);
      s+="}";
      s+="%"+floor(random(10)+1);
    }    
    s+=" ";
  }
  return s;
}
