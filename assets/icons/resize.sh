magick convert -resize 192x192 icon@3x.png icon.png


magick convert -resize 48x48 icon@3x.png icon@0,25x.png

magick convert -resize 96x96 icon@3x.png icon@0,5x.png


magick convert -resize 144x144 icon@3x.png icon@0,75x.png

magick convert -resize 384x384 icon@3x.png icon@2x.png

magick convert -resize 384x384 icon@3x.png icon@2x.png

# titles
magick convert -resize 558x558 icon@3x.png tile-large.png
magick convert -resize 270x270 icon@3x.png tile-medium.png
magick convert -resize 70x70 icon@3x.png tile-small.png