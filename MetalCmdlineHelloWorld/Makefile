default: main shaders.metallib

main: main.mm structure.h
	clang++ -std=c++11 -framework Cocoa -framework Metal -framework MetalKit -fobjc-arc $< -o $@

%.air: %.metal structure.h
	metal -O2 -std=osx-metal1.1 -o $@ $<

%.metal-ar: %.air
	metal-ar r $@ $<

%.metallib: %.metal-ar
	metallib -o $@ $<

clean:
	rm -f main *.metallib *.metal-ar *.air
