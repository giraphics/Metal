default: main shaders.metallib

main: main.mm structure.h
	clang++ -std=c++11 -framework Cocoa -framework Metal -framework MetalKit -fobjc-arc $< -o $@

%.metallib: %.metal structure.h
	xcrun -sdk macosx metal -Wall -Wextra $< -o $@

clean:
	rm -f main *.metallib *.metal-ar *.air
