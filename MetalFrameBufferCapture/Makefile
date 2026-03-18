default: main shaders.metallib 1.jpg

main: main.mm common.h
	clang++ -std=c++11 -framework Cocoa -framework Metal -framework MetalKit -fobjc-arc $< -o $@

shaders.metallib: shaders.metal common.h
	xcrun -sdk macosx metal -Wall -Wextra shaders.metal -o shaders.metallib

# NSBundle resourcePath for a plain binary resolves to the binary's directory,
# so the image must live alongside the executable.
1.jpg: textures/photos/1.jpg
	cp $< $@

clean:
	rm -f main shaders.metallib 1.jpg
