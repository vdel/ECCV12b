#include <string.h>
#include "mex.h"

#define min(a,b)  ((a)<(b)?(a):(b))
#define max(a,b)  ((a)>(b)?(a):(b))

typedef struct seg_t {
	int id;
	double w;
} seg_t;

int compareBB(const int **bb1, const int **bb2) {
    const int d = (*bb1)[5] - (*bb2)[5];
	return d == 0 ?  (*bb1)[4] - (*bb2)[4] : d;	       
};

int addEntries(mxArray *sparse, int nEntries, int j, seg_t *seg, int nseg)
{	
	int newNentries = nEntries + nseg;
	
	if (newNentries > mxGetNzmax(sparse)) {
		int newsize = min(2 * newNentries, mxGetNumberOfElements(sparse));
		mxSetNzmax(sparse, newsize);
		mxSetIr(sparse, mxRealloc(mxGetIr(sparse), newsize * sizeof(mwIndex)));
		mxSetPr(sparse, mxRealloc(mxGetPr(sparse), newsize * sizeof(double)));		
	}
	
	double *pr = mxGetPr(sparse);
	mwIndex *ir = mxGetIr(sparse);	
	mwIndex *jc = mxGetJc(sparse);	
	int s;

    jc[j] = nEntries;
    
	for (s = 0; s < nseg; s++) {
		ir[nEntries + s] = seg[s].id;
		pr[nEntries + s] = seg[s].w;	
	}
	
	return newNentries;	
}

/*
#include "mat.h"

int main(int argc, char **argv)
{
	if(argc < 2)
	{
		printf("Need path to the *.mat file with parameters");
		return 1;
	}
	
	MATFile *fid = matOpen(argv[1], "r");
	const mxArray *prhs[5];
	mxArray *plhs[1];
	
	if(!fid)
	{
		printf("File not found \n");
		return 1;
	}	

	prhs[0] = matGetVariable(fid, "segment");
	prhs[1] = matGetVariable(fid, "nseg");
	prhs[2] = matGetVariable(fid, "bbs");
	prhs[3] = matGetVariable(fid, "nFeat");
	prhs[4] = matGetVariable(fid, "nOffset");				
	
	if (prhs[0] == NULL || prhs[0] == NULL || prhs[0] == NULL || prhs[0] == NULL || prhs[0] == NULL)
	{
		printf("A variable is missing.");
		return 1;		
	}
	else {
		mexFunction(1, plhs, 5, prhs);
	}		
		
	matClose(fid);
		
	return 0;	
}*/

void* checkAlloc(void *ptr) {
    if(ptr == NULL)
        mexErrMsgTxt("Could not allocate memory.");  
    return ptr;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 	
	if (nrhs != 3)
        mexErrMsgTxt("Expecting 3 inputs: pixelsMap, nPixels, BBs");  
    if (nlhs > 1)
        mexErrMsgTxt("Expecting 1 output.");  
	if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS || mxGetNumberOfDimensions(prhs[0]) != 2)
        mexErrMsgTxt("First input should be a 2-dimensional matrix of type DOUBLE containing superpixels IDs.");      
    if (mxGetClassID(prhs[1]) != mxDOUBLE_CLASS || mxGetNumberOfElements(prhs[1]) != 1)
        mexErrMsgTxt("Second input should be a scalar: number of segments");       
    if (mxGetClassID(prhs[2]) != mxINT32_CLASS)
        mexErrMsgTxt("Third input should be a 3D array of type INT32 for BBs, one per column for each feature (xmin ymin xmax ymax), multiple boxes are accumulated over third dimension.");           

	const mwSize *dimmap = mxGetDimensions(prhs[0]);
	const mwSize *dimbox = mxGetDimensions(prhs[2]);
    
    if (mxGetNumberOfDimensions(prhs[2]) > 3 || dimbox[0] != 4)
        mexErrMsgTxt("Third input should be a 3D array of type INT32 for BBs, one per column for each feature (xmin ymin xmax ymax), multiple boxes are accumulated over third dimension.");           
    
    const int nFeat      = dimbox[1]; 
    const int nBpF       = mxGetNumberOfDimensions(prhs[2]) < 3 ? 1 : dimbox[2];
	const int nBBs       = nFeat * nBpF;    

    const double *pixelMap = mxGetPr(prhs[0]);  
    const int nPixels      = mxGetScalar(prhs[1]);  
    mxArray *cell;    
    
    int i, j, k, f, o, s; 
    int nseg, segID;
    int *BBs = (int*)mxGetPr(prhs[2]);
    int *BB;
    int nEntries;
    seg_t *segs = checkAlloc(malloc(sizeof(seg_t) * nPixels));
    
    plhs[0] = mxCreateCellMatrix(nBpF, 1); 
    
    for (o = 0; o < nBpF; o++, BBs += 4 * nFeat) {  
        cell = mxCreateSparse(nPixels, nFeat, min(nPixels, 4) * nFeat, mxREAL);
        mxSetCell(plhs[0], o, cell);
        
        nEntries = 0;
        for (f = 0; f < nFeat; f++) {  
        	nseg = 0;                
            BB = BBs + 4 * f;
            const int surf = ((BB[2] - BB[0] + 1.) * (BB[3] - BB[1] + 1.));
            const double weight = 1. / (double)surf;

            for (i = max(BB[0]-1, 0); i < min(BB[2], (int)dimmap[1]); i++) {
                for (j = max(BB[1]-1, 0); j < min(BB[3], (int)dimmap[0]); j++) {
                    segID = pixelMap[i * dimmap[0] + j] - 1;
                    if(segID < 0) 
                        mexErrMsgTxt("First segment should have ID of 1.");  

                    for (s = nseg - 1; s >= 0; s--) {
                        if (segID == segs[s].id) {
                            segs[s].w += weight;
                            break;
                        }
                    }

                    if (s < 0) {
                        segs[nseg].id = segID;
                        segs[nseg].w = weight;
                        nseg++;
                    }
                }  
            }
            nEntries = addEntries(cell, nEntries, f, segs, nseg);                                
        }
        mwIndex *jc = mxGetJc(cell);
        jc[nFeat] = nEntries;
    }

    free(segs);	    
}
