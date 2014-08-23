
all: cpp mex

cpp:
	g++ -O3 -o kmeans kmeansmex.cpp

mex:
	mex -DMEXFILE=1 kmeansmex.cpp

clean:
	rm -rf kmeansmex.mex* kmeans *~ 
