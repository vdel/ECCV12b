clean-release:
	make -C 3rdparty clean-release
	make -C private clean-release    
	rm -f *~
	rm -f *.mex*