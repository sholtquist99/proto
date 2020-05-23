import java.util.*;
import java.io.*;
import java.nio.file.*;
import javax.imageio.ImageIO;
import java.awt.image.*;

final int scaledImgDim = 50;//dimensions to scale character data to before generating 3D models

int screenState = 0;//which screen is to be displayed

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
  
  } else if(screenState == 2) {//view 4D
  
    view3D();
    
  } else if(screenState == 3) {
  
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

}

void splitSourceFiles() {

  key = '0';//reset input to prevent sticking
  
  try {
    DirectoryStream<Path> stream = Files.newDirectoryStream(writing_systems);
    for (Path file: stream) {
      println("Processing the " + file.toFile().getName() + " writing system");
      splitSystem(file);
    }
  } catch (Exception e) {
    println("Oh no! " + e);
  }

}

void generate3D() {

  key = '0';//reset input to prevent sticking
  
  ArrayList<int[][]> characterData = new ArrayList();
  Path english_chars = Paths.get(sketchPath("input\\writing_systems\\Latin\\characters\\English"));
  
  try {
    DirectoryStream<Path> stream = Files.newDirectoryStream(english_chars);
    for (Path file: stream) {
        BufferedImage img = ImageIO.read(file.toFile());
        trimImage(img);
        characterData.add(scaleImg(trimImage(img), scaledImgDim, scaledImgDim));
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

//process the source folder for a given writing system
void splitSystem(Path path) {
  
  Path source = Paths.get(path.toString() + "\\source");
  
  try {
    DirectoryStream<Path> stream = Files.newDirectoryStream(source);
    for (Path file: stream) {
        if(file.toFile().isDirectory()) {//writing system contains subsets for different languages/language groups
        
          File directory = file.toFile();
          println("\tProcessing subset " + directory.getName());
          
        } else {//writing system data is monolithic
        
          File resource = file.toFile();
          println("\tProcessing resource " + resource.getName());
          
        }
    }
  } catch (Exception e) {
    println("Oh no! " + e);
  }

}

void view4D() {

  
  
}

//crop a BufferedImage to remove white/transparent space outside the boundary of the subject
int[][] trimImage(BufferedImage img) {
  
  int[][] ret;
  
  final byte[] pixels = ((DataBufferByte) img.getRaster().getDataBuffer()).getData();
  
  boolean hasAlpha = img.getAlphaRaster() != null;
  
  int imgHeight = img.getHeight();
  int imgWidth = img.getWidth();
  
  int highest = imgHeight - 1;
  int lowest = 0;
  int left = imgWidth - 1;
  int right = 0;
  
  int size = hasAlpha ? 4 : 3;
  
  //find bounds
  for (int pixel = hasAlpha ? 1 : 0, row = 0, col = 0; pixel + size - 1 < pixels.length; pixel += size) {
    
    int argb = 0;
    argb += ((int) pixels[pixel] & 0xff); // blue
    argb += (((int) pixels[pixel + 1] & 0xff)); // green
    argb += (((int) pixels[pixel + 2] & 0xff)); // red
    argb /= 3;//convert to grayscale
    
    if(argb != 255) {//non-white pixel
    
      if(highest > row) {
        highest = row;
      } else if (lowest < row) {
        lowest = row;
      }
      
      if(left > col) {
        left = col;
      } else if(right < col) {
        right = col;
      }
    
    }
    
    col++;
    if (col == imgWidth) {
     col = 0;
     row++;
    }
    
  }
  
  ret = new int[(lowest - highest) + 1][(right - left) + 1];//rows by columns = height by width
  
  //copy relevant section
  for(int i = highest; i <= lowest; i++) {
  
    for(int j = left; j <= right; j++) {
    
      int pixelidx = (((i * imgWidth) + j) * (hasAlpha ? 4 : 3)) + (hasAlpha ? 1 : 0);
      
      int argb = 0;
      argb += ((int) pixels[pixelidx] & 0xff); // blue
      argb += (((int) pixels[pixelidx + 1] & 0xff)); // green
      argb += (((int) pixels[pixelidx + 2] & 0xff)); // red
      argb /= 3;//grayscale
      
      ret[i - highest][j - left] = argb;
    
    }
  
  }
  
  return ret;

}

int[][] scaleImg(int[][] img, int w, int h) {

  int[][] ret = new int[h][w];//rows by columns
  
  int originalHeight = img.length;
  int originalWidth = img[0].length;
  
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
      
      float topRowLerp = lerp(topLeft, topRight, xScale);
      float bottomRowLerp = lerp(bottomLeft, bottomRight, xScale);
      
      int val = (int)lerp(topRowLerp, bottomRowLerp, yScale);
      
      ret[y][x] = val;
    
    }
  
  }
  
  return ret;
  
}

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

void keyPressed() {

  if(key == 9) {//return to main menu when TAB is pressed
  
    screenState = 0;
    
  }
  
}
