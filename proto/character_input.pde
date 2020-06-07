import java.awt.Rectangle;

final float pixelCutoff = 0.95f;//cutoff for pixels being considered part of a character - otherwise, consider as background
final float distanceCutoff = 4;

void splitSourceFiles() {

  key = '0';//reset input to prevent sticking
  
  try {
    DirectoryStream<Path> stream = Files.newDirectoryStream(writing_systems);
    for (Path file: stream) {
      println("Processing the " + file.toFile().getName() + " writing system");
      splitSystem(file);
    }
    usermsg = "Files split successfully!";
  } catch (Exception e) {
    usermsg = "Oh no! " + e;
  }

}

//process the source folder for a given writing system
void splitSystem(Path path) {
  
  Path source = Paths.get(path.toString() + "\\source");
  
  try {
    
    DirectoryStream<Path> stream = Files.newDirectoryStream(source);
    for (Path file: stream) {
        //writing system contains subsets for different languages/language groups
        if(file.toFile().isDirectory()) {
        
          File directory = file.toFile();
          String dirName = directory.getName();
          println("----Processing " + dirName + " subset");
          
          Path subsetSource = Paths.get(source.toString() + "\\" + dirName);
          DirectoryStream<Path> subsetStream = Files.newDirectoryStream(subsetSource);
          
          File config = new File(subsetSource.toString() + "\\config.txt");
          
          for(Path subsetFile: subsetStream) {
            
            File resource = subsetFile.toFile();
            String fileName = resource.getName();
            
            if(fileName.equals("config.txt")) {//don't split the config file!
              continue;
            }
            
            println("\tProcessing resource " + fileName);
            
            Path outputDir = Paths.get(path.toString() + "\\characters\\" + dirName);
            splitFileCCL(resource, config, outputDir);
            
          }
          
          println("----End " + dirName + " subset");
          
        } else {//writing system data is monolithic
        
          File resource = file.toFile();
          String fileName = resource.getName();
          
          if(fileName.equals("config.txt")) {//don't split the config file!
            continue;
          }
          
          println("\tProcessing resource " + fileName);
          
          File config = new File(source.toString() + "\\config.txt");
          Path outputDir = Paths.get(path.toString() + "\\characters");
          splitFileCCL(resource, config, outputDir);
          
        }
    }
    
  } catch (Exception e) {
    println("Oh no! " + e);
  }

}

//Connected-Component Labeling, slightly adapted to fit the needs of the project
int[][] splitFileCCL(File resource, File config, Path outputDir) {//handle individual file splitting

  String fileName = resource.getName();
  
  try {
    
    int[][] imgArr = imgToArr(ImageIO.read(resource));
    BufferedReader configReader = new BufferedReader(new FileReader(config));
    
    String line = "";
    
    while(configReader.ready() && !line.equals(fileName)) {//read until we reach the file at hand
    
      line = configReader.readLine();
    
    }
    
    Rectangle[] exclusionRegions;
    
    if(line.equals(fileName)) {//config file contains info for the resource
      
      //get exclusion region info from config file
      int numRegions = Integer.parseInt(configReader.readLine());
      exclusionRegions = new Rectangle[numRegions];
      
      for(int i = 0; i < numRegions; i++) {
      
        line = configReader.readLine();
        String[] explode = line.split(" ");
        
        if(explode.length < 4) {
        
          usermsg = "Oh no! Config file entry for " + fileName + " doesn't have enough data";
          return new int[1][1];//dummy return data for fail state
        
        }
        
        int[] parsed = new int[4];//parse data
        for(int j = 0; j < 4; j++) parsed[j] = Integer.parseInt(explode[j]);
        
        exclusionRegions[i] = new Rectangle(parsed[0], parsed[1], (parsed[2]-parsed[0]) + 1, (parsed[3]-parsed[1]) + 1);
        
      }
      
      //modified two-pass CCR process begins
      
      int h = imgArr.length;
      int w = imgArr[0].length;
      
      //HashMap<Integer, DisjointSet> linked = new HashMap();
      DisjointSet linked = new DisjointSet(0);
      int[][] labels = new int[h][w];//rows x cols
      int nextLabel = 1;
      
      for(int i = 0; i < h; i++) {
        for(int j = 0; j < w; j++) {
          labels[i][j] = 0;//initialize all labels to background - not strictly required in Java due to 0-initizliation with numeric arrays
        }
      }
      
      //first pass
      for(int i = 0; i < h; i++) {
        
        widthwise:
        for(int j = 0; j < w; j++) {
          
          for(Rectangle exclusion : exclusionRegions) {//don't process points within exclusion zones
            if(exclusion.contains(j, i)) {
              /*println("point (" + j + ", " + i + ") is within exclusion zone {" + 
                (int)exclusion.x + ", " + (int)exclusion.y + ", " + exclusion.width + ", " + exclusion.height + "}");*/
              continue widthwise;
            }
          }
          
          if((float)imgArr[i][j] / 255.0f <= pixelCutoff) {//pixel is not background
            
            //neighbors
            boolean top  = i > 0 && (float)imgArr[i - 1][j] / 255.0f <= pixelCutoff;
            boolean left = j > 0 && (float)imgArr[i][j - 1] / 255.0f <= pixelCutoff;
            
            ArrayList<Integer> neighbors = new ArrayList();
            
            if(top) {
              neighbors.add(labels[i - 1][j]);
            }
            
            if(left) {
              neighbors.add(labels[i][j-1]);
            }
            
            if(neighbors.size() == 0) {//has no neighbors
              
              linked.unite(nextLabel);
              labels[i][j] = nextLabel;
              nextLabel++;
              
            } else {//has at least one neighbor
              
              int minL = neighbors.size() == 1 ? neighbors.get(0) : Math.min(neighbors.get(0), neighbors.get(1));
              labels[i][j] = minL;
              
              for(Integer label : neighbors) {
              
                linked.unite(labels[i][j], label);
              
              }
            
            }
            
          }
          
        }
        
      }
      
      //second pass
      for(int i = 0; i < h; i++) {
        
        for(int j = 0; j < w; j++) {
          
          int label = labels[i][j];
          
          if(label != 0) {//pixel is not background
            
            labels[i][j] = linked.find(labels[i][j]);
          
          }
          
        }
        
      }
      
      return labels;//victory! return the label matrix for further processing
    
    } else {//missing entry
    
      usermsg = "Oh no! No match in config for " + fileName;
      
    }
    
    configReader.close();
    
  } catch (Exception e) {
    usermsg = "Oh no! " + e;
  }
  
  return new int[1][1];//dummy return data for fail state

}

//find the distinct values present in the array, except for background values
HashSet<Integer> distinctNonBG(int[][] arr, int background) {

  HashSet<Integer> vals = new HashSet();
  
  for(int i = 0; i < arr.length; i++) {
  
    for(int j = 0; j < arr[0].length; j++) { 
    
      vals.add(arr[i][j]);
    
    }
    
  }
  
  return vals;

}

ArrayList<PVector> findMatchingVals(int[][] arr, int target) {

  ArrayList<PVector> matches = new ArrayList();
  
  for(int i = 0; i < arr.length; i++) {//rows by cols
  
    for(int j = 0; j < arr[0].length; j++) {
    
      if(arr[i][j] == target) {
      
        //swap i-j order to convert from row-col to (x, y)
        matches.add(new PVector(j, i));
        
      }
      
    }
    
  }
  
  return matches;

}

float closestDist(Rectangle r1, Rectangle r2) {
  
  PVector[] r1points = new PVector[4];
  PVector[] r2points = new PVector[4];
  
  r1points[0] = new PVector(r1.x, r1.y);
  r1points[1] = new PVector(r1.x + r1.width, r1.y);
  r1points[2] = new PVector(r1.x, r1.y + r1.height);
  r1points[3] = new PVector(r1.x + r1.width, r1.y + r1.height);
  
  r2points[0] = new PVector(r2.x, r2.y);
  r2points[1] = new PVector(r2.x + r2.width, r2.y);
  r2points[2] = new PVector(r2.x, r2.y + r2.height);
  r2points[3] = new PVector(r2.x + r2.width, r2.y + r2.height);
  
  float dist = Float.MAX_VALUE;
  
  for(int i = 0; i < 4; i++) {
  
    for(int j = 0; j < 4; j++) {
  
      float pointDist = r1points[i].dist(r2points[j]);
      
      if(pointDist < dist) {
        dist = pointDist;
      }
    
    }
    
  }
  
  return dist;
  
}

ArrayList<Rectangle> extractBounds(int[][] arr, int background) {

  HashSet<Integer> regions = distinctNonBG(arr, 0);
  ArrayList<Rectangle> boundaries = new ArrayList();
  
  for(Integer region : regions) {
    
    if(region == background) {
      continue;
    }
  
    ArrayList<PVector> matches = findMatchingVals(arr, region);
    
    int minX = Integer.MAX_VALUE;
    int maxX = Integer.MIN_VALUE;
    int minY = Integer.MAX_VALUE;
    int maxY = Integer.MIN_VALUE;
    
    for(PVector point : matches) {
    
      if(point.x < minX) {
        minX = (int)point.x;
      }
      
      if(point.x > maxX) {
        maxX = (int)point.x;
      }
      
      if(point.y < minY) {
        minY = (int)point.y;
      }
      
      if(point.y > maxY) {
        maxY = (int)point.y;
      }
      
    }
    
    int w = (maxX - minX) + 1;
    int h = (maxY - minY) + 1;
    
    boundaries.add(new Rectangle(minX, minY, w, h));
    
  }
  
  //combine regions that are within the cutoff distance - some characters (such as i and j) contain multiple subregions
  for(int i = boundaries.size() - 1; i >= 0; i--) {
  
    Rectangle rect1 = boundaries.get(i);
    
    for(int j = i - 1; j >= 0; j--) {
      
      Rectangle rect2 = boundaries.get(j);
    
      if(closestDist(rect1,rect2) <= distanceCutoff) {//within tolerance - merge, baby, merge!
    
        Rectangle union = (Rectangle)rect1.createUnion(rect2); //<>//
        boundaries.set(j, union);//join regions //<>//
        boundaries.remove(i--);//clear redundancy //<>//
      
      }
    
    }
  
  }
  
  return boundaries;
  
}

void extractCharacterFiles(File resource, Path outputDir, ArrayList<Rectangle> bounds) {

  String fileName = resource.getName();
  fileName = fileName.substring(0, fileName.lastIndexOf("."));
  String outputString = outputDir.toString();
  BufferedImage sourceImg;
  
  try {
    sourceImg = ImageIO.read(resource);
  } catch (Exception e) {
    usermsg = "Couldn't read source image: " + e;
    return;
  }
  
  for(int i = 0; i < bounds.size(); i++) {
    
    Rectangle bound = bounds.get(i);
    BufferedImage character = sourceImg.getSubimage(bound.x, bound.y, bound.width, bound.height);
    
    String outputFileName = fileName + "_" + i + ".jpg";
    File outputFile = new File(outputString + "\\" + outputFileName);
    
    try {
      ImageIO.write(character, "jpg", outputFile);
    } catch (Exception e) {
      usermsg = "Couldn't write output file '" + outputFileName + "': " + e;
    }
    
  }
  
}
