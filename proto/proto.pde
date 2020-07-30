import java.util.*;
import java.io.*;
import java.io.InputStream;
import java.nio.file.*;
import javax.imageio.ImageIO;
import java.awt.image.*;

final int scaledImgDim = 50;//dimensions to scale character data to before generating 3D models

int screenState = 0;//which screen is to be displayed
String usermsg = "";

Path proj_dir;//paths to useful project directories
Path input_dir;
Path writing_systems;

void setup() {

  size(1280, 720, P3D);
  background(0);
  colorMode(RGB);
  lights();
  
  proj_dir = Paths.get(sketchPath(""));
  input_dir = Paths.get(sketchPath("input"));
  writing_systems = Paths.get(sketchPath("input\\writing_systems"));
  
  String baseDir = writing_systems.toString();
  
  File resource = new File(baseDir + "\\Latin\\source\\latin_accents.jpg");
  File config = new File(baseDir + "\\Latin\\source\\config.txt");
  Path outputDir = Paths.get(baseDir + "\\Latin\\characters");
  
  String fileName = "latin_accents.jpg";
  
  int[][] cclResult = splitFileCCL(resource, config); //<>//
  //log2Darr(cclResult);
  
  float distanceCutoff = 0;
  int areaCutoff = 0;
  
  try {
    
    BufferedReader configReader = new BufferedReader(new FileReader(config));
    String line = "";
    
    while(configReader.ready() && !line.equals(fileName)) {//read until we reach the file at hand
      line = configReader.readLine(); 
    }
    
    if(line.equals(fileName)) {//config file contains info for the resource
      
      String[] explode = configReader.readLine().split(" ");
      distanceCutoff = Float.parseFloat(explode[1]);
      areaCutoff = Integer.parseInt(explode[2]);
      
    }
    
  } catch (Exception e) {
  
    usermsg = "Distance and/or area cutoffs not found - using defaults (0): " + e;
    
  }
  
  ArrayList<Rectangle> bounds = extractBounds(cclResult, distanceCutoff, areaCutoff);
  println("Successfully extracted " + bounds.size() + " bounding boxes from source image");
  
  extractImgRegions(resource, bounds, outputDir);
  println("Character data extracted and saved to individual files!");
  
}

void draw() {
  
  if(screenState == 0) {//main menu
  
    showMenu();
    
    int choice = key - '0';
    
    switch(choice) {
    
      case 1:
        splitSourceFiles();
        break;
      case 2:
        generate3D();
        break;
      case 3:
        screenState = 1;
        list3D();
        break;
      case 4:
        generate4D();
        break;
      case 5:
        screenState = 3;
        view4D();
        break;
    
    }
  
  } else if(screenState == 1) {//view 3D
  
    list3D();
  
  } else if(screenState == 2) {//view 3D
  
    view3D();
    
  } else if(screenState == 3) {//view 4D
  
    view4D();
    
  }

}

void showMenu() {

  background(0);
  textSize(24);
  
  text("1: Split source files into characters", 10, 30);
  text("2: Generate 3D sculpture(s)", 10, 60);
  text("3: View 3D sculpture", 10, 90);
  text("4: Generate 4D sculpture", 10, 120);
  text("5: View 4D sculpture", 10, 150);
  text(usermsg, 10, 180);

}

void generate3D() {

  key = '0';//reset input to prevent sticking
  
  ArrayList<int[][]> characterData = new ArrayList();
  Path english_chars = Paths.get(sketchPath("input\\writing_systems\\Latin\\characters\\English"));
  
  try {
    DirectoryStream<Path> stream = Files.newDirectoryStream(english_chars);
    for (Path file: stream) {
        BufferedImage img = ImageIO.read(file.toFile());
        //do stuff
    }
    println("finished cropping and scaling images in this directory!");
  } catch (Exception e) {
    println("Oh no! " + e);
  }

}

void list3D() {

  
  
}

void view3D() {

  
  
}

void generate4D() {

  key = '0';//reset input to prevent sticking

}

void view4D() {

  
  
}
//convert BufferedImage to 2D int array for easier processing
//code thanks to user Motasim on SO
//https://stackoverflow.com/questions/6524196/java-get-pixel-array-from-image
int[][] imgToArr(BufferedImage img) {

  final byte[] pixels = ((DataBufferByte) img.getRaster().getDataBuffer()).getData();
  
  boolean hasAlpha = img.getAlphaRaster() != null;
  int size = hasAlpha ? 4 : 3;
  
  int imgHeight = img.getHeight();
  int imgWidth = img.getWidth();
  
  int[][] ret = new int[imgHeight][imgWidth];
  
  //copy img into 2D int arr
  for(int i = 0; i < imgHeight; i++) {
  
    for(int j = 0; j < imgWidth; j++) {
    
      int pixelidx = (((i * imgWidth) + j) * size) + (size - 3);
      
      int argb = 0;
      argb += ((int) pixels[pixelidx] & 0xff); // blue
      argb += (((int) pixels[pixelidx + 1] & 0xff)); // green
      argb += (((int) pixels[pixelidx + 2] & 0xff)); // red
      argb /= 3;//grayscale
      
      ret[i][j] = argb;
    
    }
  
  }
  
  return ret;

}

//modified bilinear interpolation
int[][] scaleImg(int[][] img, int minDim) {

  //dimensions of original image array
  int originalHeight = img.length;
  int originalWidth = img[0].length;
  
  int shortestSide = Math.min(originalHeight, originalWidth);
  
  //leave dimensions alone if >= minimum, scale to fit otherwise
  float scaleFactor = shortestSide >= minDim ? 1.0 : (float)minDim / shortestSide;
  int h = (int)Math.round(originalHeight * scaleFactor);
  int w = (int)Math.round(originalWidth * scaleFactor);
  
  int[][] ret = new int[h][w];//rows by columns
  
  for(int y = 0; y < h; y++) {
  
    float yScale = (float)y / h;//percentage of resultant array height traversed
    
    for(int x = 0; x < w; x++) {
      
      float xScale = (float)x / w;//percentage of resultant array width traversed
    
      int x1 = (int)Math.floor(xScale * originalWidth);//coordinates bounding the point of interest
      int x2 = (x1 == originalWidth - 1) ? x1 : x1 + 1;
      int y1 = (int)Math.floor(yScale * originalHeight);
      int y2 = (y1 == originalHeight - 1) ? y1 : y1 + 1;
      
      int topLeft = img[y1][x1];//actual pixel data bounding the point of interest
      int topRight = img[y1][x2];
      int bottomLeft = img[y2][x1];
      int bottomRight = img[y2][x2];
      
      float topRowLerp = lerp(topLeft, topRight, xScale);//lerp along all 4 edges of bounding rectangle
      float bottomRowLerp = lerp(bottomLeft, bottomRight, xScale);
      float leftColLerp = lerp(topLeft, bottomRight, yScale);
      float rightColLerp = lerp(topRight, bottomRight, yScale);
      
      ret[y][x] = (int)((topRowLerp + bottomRowLerp + leftColLerp + rightColLerp) / 4.0f);//average 4 lerp values
    
    }
  
  }
  
  return ret;
  
}
//console log a 2D array with minimum column widths
//NOTE: I didn't bother checking for the widest column present in the source array, so ugliness is possible. May or may not fix later
void printArr2D(int[][] arr, int colWidth) {

  println("[");
  
  for(int i = 0; i < arr.length; i++) {
  
    print("[");
    
    for(int j = 0; j < arr[0].length; j++) {
  
      String val = Integer.toString(arr[i][j]);;
      
      if(j < arr[i].length - 1) {//comma deliniation
      
        val += ", ";
        
        for(int k = val.length(); k < colWidth + 2; k++) {
          val += " ";
        }
        
      }
      
      print(val);
    
    }
    
    println("]");
    
  }
  
  println("]");

}
//dump 2D array into a "log.csv" file in the main project folder
void log2Darr(int[][] arr) {

  String text = "";
  
  for(int i = 0; i < arr.length;  i++) { //<>//
  
    for(int j = 0; j < arr[0].length; j++) {
    
      text += arr[i][j] + (j + 1 < arr[0].length ? "," : "");
    
    }
    
    text += "\n";
  
  }
  
  try {
  
    FileWriter fw = new FileWriter(proj_dir.toString() + "\\log.csv");
    fw.write(text);
    fw.close();
  
  } catch (IOException e) {
  
    println("oh no! " + e);
    
  }

}

void keyPressed() {

  if(key == 9) {//return to main menu when TAB is pressed
  
    screenState = 0;
    
  }
  
}
