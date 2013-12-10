
all: cpp mex

cpp:
	g++ -O3 -o kmeans kmeans.cpp

mex:
	mex -DMEXFILE=1 kmeans.cpp

clean:
	rm -rf kmeans.mex* kmeans *~ 
