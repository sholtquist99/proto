//slightly-modified Princeton WQUPC implementation
//see https://www.cs.princeton.edu/~rs/AlgsDS07/01UnionFind.pdf
class DisjointSet {

  private ArrayList<Integer> id = new ArrayList();
  private ArrayList<Integer> sz = new ArrayList();
  
  public DisjointSet(int N) {
    
    N++;
    
    for(int i = 0; i < N; i++) {
      
      id.add(i);
      sz.add(1);
      
    }
  
  }
  
  private int root(int i) {
  
    while(i != id.get(i)) {
      id.set(i, id.get(id.get(i)));
      i = id.get(i);
    }
    return i;
    
  }
  
  public int find(int x) {
  
    return root(x);
    
  }
  
  public boolean find(int p, int q) {
  
    return root(p) == root(q);
    
  }
  
  public void unite(int p, int q) {
  
    int i = root(p);
    int j = root(q);
    
    if(sz.get(i) < sz.get(j)) {
    
      id.set(i, j);
      sz.set(j, sz.get(j) + sz.get(i));
    
    } else {
    
      id.set(j, i);
      sz.set(i, sz.get(i) + sz.get(j));
    
    }
    
  }
  
  public void unite(int b) {
  
    if(b >= id.size()) {//new value!
      
        for(int i = id.size(); i < b; i++) {
        
          id.add(i);
          sz.add(0);
          
        }
      
        id.add(b);
        sz.add(1);
        
      }
    
  }
  
  //merge an arraylist into the disjoint set
  public void unite(ArrayList<Integer> b) {
  
    for(Integer num : b) {
    
      unite(num);
      
    }
  
  }
  
  public HashMap<Integer, ArrayList<Integer>> disjointRegions() {
  
    HashMap<Integer, ArrayList<Integer>> ret = new HashMap();//map root values to all nodes in the connected region (incl. root)
    
    for(int i = 0; i < id.size(); i++) {
    
      int root = root(i);
      ArrayList<Integer> region = ret.getOrDefault(root, new ArrayList());//region connected to root of current node
      region.add(i);
      ret.put(root, region);//add current node to region and update map
      
    }
    
    return ret;
    
  }
  
}
