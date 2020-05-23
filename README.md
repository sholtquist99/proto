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
2
0 0 2 9 25 25 33 39
0 0 1 8 25 25 33 0