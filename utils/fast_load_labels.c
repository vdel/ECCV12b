#include <string.h>
#include "mex.h"

#define min(a,b)  ((a)<(b)?(a):(b))
#define max(a,b)  ((a)>(b)?(a):(b))

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{ 	
  if (nrhs != 2 && nrhs != 3)
    mexErrMsgTxt("Expecting 2 or 3 inputs: pixelsMap, nPixels [, annots]");  
  if (nrhs == 2 && nlhs != 1)
    mexErrMsgTxt("Expecting 1 output.");  
  if (nrhs == 3 && nlhs != 2)
    mexErrMsgTxt("Expecting 2 output.");      
  if (mxGetClassID(prhs[0]) != mxDOUBLE_CLASS || mxGetNumberOfDimensions(prhs[0]) != 2)
    mexErrMsgTxt("First input should be a 2-dimensional matrix of type DOUBLE containing superpixels IDs.");      
  if (mxGetClassID(prhs[1]) != mxDOUBLE_CLASS || mxGetNumberOfElements(prhs[1]) != 1)
    mexErrMsgTxt("Second input should be a scalar: number of segments");       
  if (nrhs == 3 && mxGetClassID(prhs[2]) != mxLOGICAL_CLASS)
    mexErrMsgTxt("Third input should be an array of type LOGICAL for annotations: a binary matrix with same depth as the number of labels.");  

  const mwSize *dimmap = mxGetDimensions(prhs[0]);
  const mwSize *dimannots;
  int nlabels;
  const double *pixelMap = mxGetPr(prhs[0]);  
  const int nPixels      = mxGetScalar(prhs[1]);  
  const char *annotMap;
  
  plhs[0] = mxCreateNumericMatrix(1, nPixels, mxDOUBLE_CLASS, mxREAL);
  double *labels, *areas = mxGetPr(plhs[0]);
  
  if (nrhs == 3) 
  {
  	dimannots = mxGetDimensions(prhs[2]);
  	annotMap = (char*)mxGetPr(prhs[2]);     
  	if (dimannots[0] != dimmap[0] || dimannots[1] != dimmap[1])
      mexErrMsgTxt("Third input should have same size width and height as first input.");  
      
		if (mxGetNumberOfDimensions(prhs[2]) == 2)
			nlabels = 1;
		else
      nlabels = dimannots[2];
    plhs[1] = mxCreateNumericMatrix(nPixels, nlabels, mxDOUBLE_CLASS, mxREAL);
    labels = mxGetPr(plhs[1]);
	}
  
  int i, j, k, segID;
  const int o = dimmap[0] * dimmap[1];
  for (i = 0; i < dimmap[1]; i++) 
  {
  	for (j = 0; j < dimmap[0]; j++) 
  	{
  		const int b = i * dimmap[0] + j;
	    segID = pixelMap[b] - 1;
	    if (segID >= 0) 
	    {
	      areas[segID]++;
	      if (nrhs == 3) 
	      {
			  	for (k = 0; k < nlabels; k++) 
			  		labels[segID + k * nPixels] += annotMap[b + k * o];
	      }
	    }
	  }
	}
	
	for (i = 0; i < nPixels; i++) 
	{
		if (nrhs == 3)
			for (k = 0; k < nlabels; k++) 
				labels[i + k * nPixels] /= areas[i];
		areas[i] /= (double)o;
	}	    
}  
