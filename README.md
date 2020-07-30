# proto
Create a higher dimensional object that casts all known writing systems

# config files
Config files for 2D glyph source images tell the program which regions of the image to ignore and parameters for joining subregions of glyphs when they have multiple components (e.g. latin characters i and j.) The format is as follows:

[fileName]
[# of exclusion regions (integer)] [distanceCutoff (float)] [areaCutoff (integer)]
[top-left-x (integer)] [top-left-y (integer)] [bottom-right-x (integer)] [bottom-right-y (integer)]

The 3rd line in the above format is repeated for each exclusion region used for a particular input file. The 4 integers represent the bounds of a rectangle (in pixels) to be ignored.

EXAMPLE (Latin):

latin_accents.jpg
6 8.0 32
40 0 94 173
140 0 185 173
236 0 310 173
353 0 406 173
450 0 500 173
543 0 600 173

latin_archaic.jpg
3 5.0 32
0 39 548 110
0 157 548 227
0 275 548 332

latin_extra.jpg
1 5.0 32
0 30 500 58

latin_ligs.jpg
2 5.0 32
0 35 515 70
0 110 515 142