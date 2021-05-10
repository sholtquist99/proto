import java.awt.Rectangle;

final float pixelCutoff = 0.95f;//cutoff for pixels being considered part of a character - otherwise, consider as background
final int background = 0;//default value assigned to pixels in the background of an image

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
            
            int[][] cclResult = splitFileCCL(resource, config);
            ArrayList<Rectangle> bounds = extractBounds(cclResult, distanceCutoff, areaCutoff);
            println("Successfully extracted " + bounds.size() + " bounding boxes from source image");
            
            Path outputDir = Paths.get(path.toString() + "\\characters\\" + dirName);
            extractImgRegions(resource,  bounds, outputDir);
            println("Character data extracted and saved to individual files!");
            
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
          
            usermsg = "Distance and/or area cutoffs not found - defaulting to 0 for missing value(s): " + e;
            
          }
          
          int[][] cclResult = splitFileCCL(resource, config);
          ArrayList<Rectangle> bounds = extractBounds(cclResult, distanceCutoff, areaCutoff);
          println("Successfully extracted " + bounds.size() + " bounding boxes from source image");
          
          Path outputDir = Paths.get(path.toString() + "\\characters");
          extractImgRegions(resource,  bounds, outputDir);
          println("Character data extracted and saved to individual files!");
          
        }
        
    }
    
  } catch (Exception e) {
    println("Oh no! " + e);
  }

}

//Connected-Component Labeling, slightly adapted to fit the needs of the project
int[][] splitFileCCL(File resource, File config) {

  String fileName = resource.getName();
  
  try {
    
    int[][] imgArr = imgToArr(ImageIO.read(resource));
    BufferedReader configReader = new BufferedReader(new FileReader(config));
    
    String line = "";
    
    while(configReader.ready() && !line.equals(fileName)) {//read until we reach the file at hand
    
      line = configReader.readLine();
    
    }
    
    if(line.equals(fileName)) {//config file contains info for the resource
      
      //get exclusion region info from config file
      int numRegions = Integer.parseInt(configReader.readLine().split(" ")[0]);//parse the first number in the line
      Rectangle[] exclusionRegions = new Rectangle[numRegions];
      
      for(int i = 0; i < numRegions; i++) {
      
        line = configReader.readLine();
        String[] explode = line.split(" ");
        
        if(explode.length < 4) {
        
          usermsg = "Oh no! Config file entry for " + fileName + " doesn't have enough data";
          return null;//dummy return data for fail state
        
        }
        
        int[] parsed = new int[4];//parse data
        for(int j = 0; j < 4; j++) parsed[j] = Integer.parseInt(explode[j]);
        
        exclusionRegions[i] = new Rectangle(parsed[0], parsed[1], (parsed[2]-parsed[0]) + 1, (parsed[3]-parsed[1]) + 1);
        
      }
      
      //one-component-at-a-time CCR process begins
      //see https://en.wikipedia.org/wiki/Connected-component_labeling
      int h = imgArr.length;
      int w = imgArr[0].length;
      
      int[][] labels = new int[h][w];//rows x cols
      int nextLabel = 1;
      LinkedList<PVector> pixelQueue = new LinkedList();
      
      for(int i = 0; i < h; i++) {
        for(int j = 0; j < w; j++) {
          labels[i][j] = background;//initialize all labels to background - not strictly required in Java due to 0-initizliation with numeric arrays
        }
      }
      
      for(int i = 0; i < h; i++) {
        
        widthwise:
        for(int j = 0; j < w; j++) {
          
          for(Rectangle exclusion : exclusionRegions) {//don't process points within exclusion zones
            if(exclusion.contains(j, i)) {
              continue widthwise;
            }
          }
          
          int pixelVal = imgArr[i][j];
          boolean foreground = pixelVal / 255.0f <= pixelCutoff;
          
          if(foreground && labels[i][j] == background) {//pixel in foreground and not yet accounted for
          
            pixelQueue.add(new PVector(i, j));//enqueue pixel coordinates (don't worry about the order...)
            
            while(pixelQueue.size() > 0) {//label all connected pixels
          
              PVector connectedPixel = pixelQueue.remove();//dequeue
              int row = (int)connectedPixel.x;//this is why I said not to worry about the order. Gross, but whatever
              int col = (int)connectedPixel.y;
              
              //check 8-connected neighborhood
              //ensure that each potential neighbor is in bounds, a foreground pixel, and not already labeled
              //I know it's pretty verbose and ugly...sorry :/
              boolean top         = row > 0                    && (float)imgArr[row - 1][col] / 255.0f <= pixelCutoff     && labels[row - 1][col] == background;
              boolean topright    = row > 0 && col + 1 < w     && (float)imgArr[row - 1][col + 1] / 255.0f <= pixelCutoff && labels[row - 1][col + 1] == background;
              boolean right       = col + 1 < w                && (float)imgArr[row][col + 1] / 255.0f <= pixelCutoff     && labels[row][col + 1] == background;
              boolean bottomright = row + 1 < h && col + 1 < w && (float)imgArr[row + 1][col + 1] / 255.0f <= pixelCutoff && labels[row + 1][col + 1] == background;
              boolean bottom      = row + 1 < h                && (float)imgArr[row + 1][col] / 255.0f <= pixelCutoff     && labels[row + 1][col] == background;
              boolean bottomleft  = row + 1 < h && col > 0     && (float)imgArr[row + 1][col - 1] / 255.0f <= pixelCutoff && labels[row + 1][col - 1] == background;
              boolean left        = col > 0                    && (float)imgArr[row][col - 1] / 255.0f <= pixelCutoff     && labels[row][col - 1] == background;
              boolean topleft     = row > 0 && col > 0         && (float)imgArr[row - 1][col - 1] / 255.0f <= pixelCutoff && labels[row - 1][col - 1] == background;
              
              
              if(top) {
                labels[row - 1][col] = nextLabel;//connect that sucker!
                pixelQueue.add(new PVector(row - 1, col));//enqueue neighbor for further processing
              }
              
              if(topright) {
                labels[row - 1][col + 1] = nextLabel;
                pixelQueue.add(new PVector(row - 1, col + 1));
              }
              
              if(right) {
                labels[row][col + 1] = nextLabel;
                pixelQueue.add(new PVector(row, col + 1));
              }
              
              if(bottomright) {
                labels[row + 1][col + 1] = nextLabel;
                pixelQueue.add(new PVector(row + 1, col + 1));
              }
              
              if(bottom) {
                labels[row + 1][col] = nextLabel;
                pixelQueue.add(new PVector(row + 1, col));
              }
              
              if(bottomleft) {
                labels[row + 1][col - 1] = nextLabel;
                pixelQueue.add(new PVector(row + 1, col - 1));
              }
              
              if(left) {
                labels[row][col - 1] = nextLabel;
                pixelQueue.add(new PVector(row, col - 1));
              }
              
              if(topleft) {
                labels[row - 1][col - 1] = nextLabel;
                pixelQueue.add(new PVector(row - 1, col - 1));
              }
          
            }
          
            nextLabel++;//increment label and move on
          
          }
          
        }
        
      }
      
      return labels;//victory! return the label matrix for further processing
    
    } else {//missing entry
    
      usermsg = "Oh no! No match in config for " + fileName;
      
    }
    
    configReader.close();//free resource
    
  } catch (Exception e) {
    usermsg = "Oh no! " + e;
  }
  
  return null;//dummy return data for fail state

}

//find the distinct values present in the array, except for background values
HashSet<Integer> distinctNonBG(int[][] arr) {

  HashSet<Integer> vals = new HashSet();
  
  for(int i = 0; i < arr.length; i++) {
  
    for(int j = 0; j < arr[0].length; j++) { 
    
      if(arr[i][j] != background) {
        vals.add(arr[i][j]);
      }
    
    }
    
  }
  
  return vals;

}
//find all the points (x,y) in a 2D array that have a particular value
ArrayList<PVector> findMatchingVals(int[][] arr, int target) {

  ArrayList<PVector> matches = new ArrayList();
  
  for(int i = 0; i < arr.length; i++) {//rows by cols
  
    for(int j = 0; j < arr[0].length; j++) {
    
      if(arr[i][j] == target) {//match!
      
        //swap i-j order to convert from row-col to (x, y)
        matches.add(new PVector(j, i));
        
      }
      
    }
    
  }
  
  return matches;

}
//find the closest distance between two rectangles
float closestDist(Rectangle r1, Rectangle r2) {
  
  //check distances between edges (if in the right positions)
  if((r1.x <= r2.x && r2.x <= r1.x + r1.width) || (r2.x <= r1.x && r1.x <= r2.x + r2.width)) {//aligned horizontally (at least partially)
    //get the vertical distances between the horizontal lines of the rectangles
    float line1 = Math.abs(r1.y - r2.y);//upper 1 - upper 2
    float line2 = Math.abs((r1.y + r1.height) - r2.y);//lower 1 - upper 2
    float line3 = Math.abs(r1.y - (r2.y + r2.height));//upper 1 - lower 2
    float line4 = Math.abs((r1.y + r1.height) - (r2.y + r2.height));//lower 1 - lower 2
    
    return Math.min(Math.min(line1, line2), Math.min(line3, line4));//return shortest direct line distance
  
  }
  
  if((r1.y <= r2.y && r2.y <= r1.y + r1.height) || (r2.y <= r1.y && r1.y <= r2.y + r2.height)) {//vertical allignment
    //get the horizontal distances between the vertical lines of the rectangles
    float line1 = Math.abs(r1.x - r2.x);//left 1 - left 2
    float line2 = Math.abs((r1.x + r1.width) - r2.x);//right 1 - left 2
    float line3 = Math.abs(r1.x - (r2.x + r2.width));//left 1 - right 2
    float line4 = Math.abs((r1.x + r1.width) - (r2.x + r2.width));//right 1 - right 2
    
    return Math.min(Math.min(line1, line2), Math.min(line3, line4));//return shortest direct line distance
  
  }
  
  //check distances between corners
  PVector[] r1points = new PVector[4];
  PVector[] r2points = new PVector[4];
  
  //get all points from both rectangles
  r1points[0] = new PVector(r1.x, r1.y);//top left
  r1points[1] = new PVector(r1.x + r1.width, r1.y);//top right
  r1points[2] = new PVector(r1.x, r1.y + r1.height);//bottom left
  r1points[3] = new PVector(r1.x + r1.width, r1.y + r1.height);//bottom right
  
  r2points[0] = new PVector(r2.x, r2.y);
  r2points[1] = new PVector(r2.x + r2.width, r2.y);
  r2points[2] = new PVector(r2.x, r2.y + r2.height);
  r2points[3] = new PVector(r2.x + r2.width, r2.y + r2.height);
  
  float dist = Float.MAX_VALUE;
  //compare all corner pairs and return the shortest distance
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
//extract the set of minimum bounding boxes for every unique, non-background label value in a 2D array (group matching numbers)
ArrayList<Rectangle> extractBounds(int[][] arr, float distanceCutoff, int areaCutoff) {

  HashSet<Integer> regions = distinctNonBG(arr);//distinct, non-background labels
  ArrayList<Rectangle> boundaries = new ArrayList();//result set
  
  for(Integer region : regions) {//iterate over set of viable foreground labels
  
    ArrayList<PVector> matches = findMatchingVals(arr, region);//find all points with this label
    //find the bounding box
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
    //add the box to the result set
    boundaries.add(new Rectangle(minX, minY, w, h));
    
  }
  
  //combine regions that are within tolerance - some characters (such as i and j) contain multiple subregions
  DisjointSet regionMerges = new DisjointSet(boundaries.size());
  
  for(int i = 0; i < boundaries.size(); i++) {//find groups of subregions that meet merge criteria
  
    Rectangle r1 = boundaries.get(i);
    
    for(int j = 0; j < boundaries.size(); j++) {
    
      if(i == j) continue;
      
      Rectangle r2 = boundaries.get(j);
      
      float dist = closestDist(r1, r2);//closest distance between the regions
      int area1 = r1.width * r1.height;
      int area2 = r2.width * r2.height;
      int minArea = Math.min(area1, area2);//area of the smallest region
    
      if(dist <= distanceCutoff && minArea <= areaCutoff) {//within tolerance - merge, baby, merge!
    
        regionMerges.unite(i, j);
      
      }
    
    }
    
  }
  
  HashMap<Integer, ArrayList<Integer>> disjointRegions = regionMerges.disjointRegions();//map of regions to join //<>//
  ArrayList<Rectangle> finalBoundaries = new ArrayList();
  
  for(Integer root : disjointRegions.keySet()) {
  
    ArrayList<Integer> region = disjointRegions.get(root);//region connected to this root
    
    Rectangle join = boundaries.get(region.get(0));//this is where it breaks - index 70 OoB //<>//
    
    for(int i = 1; i < region.size(); i++) {
    
      join = join.union(boundaries.get(region.get(i)));
      
    }
    
    finalBoundaries.add(join); //<>//
    
  }
  
  return finalBoundaries;
  
}
//extracts non-background subimages from the source image and saves them to the output directory
void extractImgRegions(File resource, ArrayList<Rectangle> bounds, Path outputDir) {

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
  
  for(int i = 0; i < bounds.size(); i++) {//iterate over regions
    
    Rectangle bound = bounds.get(i);
    BufferedImage character = sourceImg.getSubimage(bound.x, bound.y, bound.width, bound.height);//extract subimage
    
    String outputFileName = fileName + "_" + i + ".jpg";
    File outputFile = new File(outputString + "\\" + outputFileName);
    //try to save file
    try {
      ImageIO.write(character, "jpg", outputFile);
    } catch (Exception e) {
      usermsg = "Couldn't write output file '" + outputFileName + "': " + e;
    }
    
  }
  
}
