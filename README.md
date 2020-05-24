# proto
Create a higher dimensional object that casts all known writing systems

# config files
Config files in each writing system/subset folder contain the infoformation 
required to extract all the symbols/glyphs/letters on an input document for 
further processing. When mapping out regions, note that characters need not
be perfectly centered within each frame - so long as every character is
completely bounded by its subimage, the program will do the heavy-lifting
of cropping and scaling. Files should be named "config.txt". Comments can be
used as long as there is at least one space between the last data field on a
line and the start of the comment. Comments do not have to start with "//"

FORMAT:

for each file in the directory: 
[file name]
[number of "blocks"/sections of grouped symbols]
for each block within the file: 
[top-left x] [top-left y] [num rows] [num cols] [glyph width] [glyph heigh] [x offset] [y offset]

EXAMPLE (English subset of Latin system with provided input):

latin_english.jpg
14
0 0 1 4 22 22 36 42 //A-D
0 62 1 3 22 22 36 42 //J-L
228 0 3 1 25 25 33 39 //E, N, W
295 0 3 3 25 25 33 39 //F-H, O-Q, X-Z
476 0 2 1 22 22 0 42 //I, R
163 63 1 1 25 25 0 0 //M
0 126 1 4 25 25 33 39 //S-V
20 0 1 4 22 22 36 42 //a-d
18 62 1 3 25 25 33 39 //j-l
252 0 3 1 25 25 33 39 //e, n, w
320 0 3 3 25 25 33 39 //f-h, o-q, x-z
498 0 2 1 13 22 0 42 //i, r
190 63 1 1 25 25 0 0 //m
20 126 1 4 25 25 33 39 //s-v

TEMPLATE:

example1.jpg
1
0 0 0 0 0 0 0 0 //test comment

example2.jpg
3
0 0 0 0 0 0 0 0 //test comment
0 0 0 0 0 0 0 0 //test comment
0 0 0 0 0 0 0 0 //test comment

example3.jpg
2
0 0 0 0 0 0 0 0 //test comment
0 0 0 0 0 0 0 0 //test comment