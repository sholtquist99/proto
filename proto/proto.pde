import java.util.*;
import java.io.*;
import java.nio.file.*;
import javax.imageio.ImageIO;
import java.awt.image.*;

Path proj_dir;
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
      generate4D();
      break;
  
  }

}

void showMenu() {

  background(0);
  textSize(24);
  
  text("1: Split source files into characters", 10, 30);
  text("2: Generate 3D sculptures", 10, 60);
  text("3: Generate 4D sculpture", 10, 90);

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
        System.out.println(file.getFileName());
        BufferedImage img = ImageIO.read(file.toFile());
        trimImage(img);
        characterData.add(trimImage(img));
    }
    println("finished trimming images in this directory!");
  } catch (Exception e) {
    println("Oh no! " + e);
  }

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
    
      int pixelidx = (i * imgWidth) + j + (hasAlpha ? 1 : 0);
      
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
