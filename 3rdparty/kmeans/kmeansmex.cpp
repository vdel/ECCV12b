#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#ifdef MEXFILE
#include <mex.h>
#endif

using namespace std;

typedef float __float_vec __attribute__ ((vector_size(16))); // vector of 4 single floats
typedef union float_vec
{
	__float_vec v;
	float f[4];
} float_vec;

int verbose = 1;

class kmeans
{
	private:
		float* data;
		int dimQ4;
		int dimR;
		int dimension;
		int ndata;

		int ncluster;
		int maxiter;
		int niter;

		float* centers;
		float* assign;

		float* new_centers;
		int* cluster_count;
		int gcd(int,int);
	public:
		// data , dim , ndata , ncluster , maxiter
		kmeans(float*,int,int,int,int);
		void set_out_data(float*,float*);
		int getNiter();

		void initialize();

		float do_kmeans();

		void clear_new_centers();
		float find_new_centers();
		bool hasConverged();

		bool hasEmptyFeatureVector();
		bool hasEmptyClusterCenter();
		
		const float_vec* safe_init(const float*, float_vec*, int*, int*);
		const float_vec* safe_init(const float*, int*, int*, int*);
		float get_sum(const float*);		
		float get_sqdist(const float*, const float*, const float);				
		void add_vect(float *a, const float *b);
		void mult_vect(float *a, const float s);		
};

const float_vec* kmeans::safe_init(const float *f, float_vec *store, int *nQ, int *nR)
{
  int i, offset;
  const float_vec* v = safe_init(f, &offset, nQ, nR);
  
  for(i = 0; i < offset; i++)
    store->f[i] = f[i];
  for(; i < 4; i++)
	  store->f[i] = 0.;	
	  
  return v;
}

const float_vec* kmeans::safe_init(const float *f, int *offset, int *nQ, int *nR)
{
	*offset = 0;
  while(reinterpret_cast<long>(f) % 16) 
  {
    f++;
    (*offset)++;
  }
  *nQ = (dimension - *offset) / 4;
  *nR = (dimension - *offset) % 4;
  
  return reinterpret_cast<const float_vec*>(f);
}

float kmeans::get_sum(const float *a)
{
	float sum;
	int nQ, nR;
	float_vec s;
	const float_vec *v = safe_init(a, &s, &nQ, &nR);
	for(int i = 0; i < nQ; i++, v++)
		s.v += v->v;	
	sum = s.f[0] + s.f[1] + s.f[2] + s.f[3];
	for(int i = 0; i < nR; i++)
		sum += v->f[i];

	return sum;
}
		
float kmeans::get_sqdist(const float *a, const float *b, const float max_dist = INFINITY)
{
  float_vec s, t;
  int nQ, nRa, nRb;
  const float_vec *u = safe_init(a, &s, &nQ, &nRa);
  const float_vec *v = safe_init(b, &t, &nQ, &nRb);
	
	float dist, diff;
	if(nRa == nRb)
	{
		s.v = s.v - t.v;
		s.v = s.v * s.v;
		dist = s.f[0] + s.f[1] + s.f[2] + s.f[3];
		for(int i = 0; i < nQ; i++, u++, v++)
		{
			s.v = u->v - v->v;
			s.v = s.v * s.v;
  		dist += s.f[0] + s.f[1] + s.f[2] + s.f[3];
  		if(dist > max_dist)
				return max_dist;
		}
		for(int i = 0; i < nRa; i++)
		{
			diff = u->f[i] - v->f[i];
			dist += diff * diff;
		}
	}
	else
	{
		dist = 0.;
		for(int i = 0; i < dimension; i++)
		{
			diff = a[i] - b[i];
			dist += diff * diff;
			if(dist > max_dist)
				return max_dist;
		}
	}
	
	return dist;	
}

void kmeans::add_vect(float *a, const float *b)
{
  int nQ, nR, oa, ob;
  float_vec *u = const_cast<float_vec *>(safe_init(a, &oa, &nQ, &nR));
	const float_vec *v = safe_init(b, &ob, &nQ, &nR);
		
	if(oa == ob)
	{
		for(int i = 0; i < oa; i++)
			a[i] += b[i];
		for(int i = 0; i < nQ; i++, u++, v++)
			u->v += v->v;
		for(int i = 0; i < nR; i++)
			u->f[i] += v->f[i];
	}
	else
	{
		for(int i = 0; i < dimension; i++)
			a[i] += b[i];
	}
}

void kmeans::mult_vect(float *a, float s)
{
	int nQ, nR, offset;
	float_vec vs = {s, s, s, s};
	float_vec *v = const_cast<float_vec *>(safe_init(a, &offset, &nQ, &nR));
	
	for(int i = 0; i < offset; i++)
		a[i] *= s;
		
	for(int i = 0; i < nQ; i++, v++)
	  v->v *= vs.v;
	  
	for(int i = 0; i < nR; i++) 
	  v->f[i] *= s;
}

int kmeans::gcd(int num1,int num2)
{
	if(num2 == 0)
		return num1;
	else
	{
		int q = num1/num2;
		return gcd(num2,num1 - q*num2);
	}
}

kmeans::kmeans(float* ptr,int value1,int value2,int value3,int value4)
{
	data = ptr;
	dimension = value1;
	dimQ4 = dimension / 4;
	dimR  = dimension % 4;
	ndata = value2;
	ncluster = value3;
	maxiter = value4;
	new_centers = new float[dimension * ncluster];
	cluster_count = new int[ncluster];

}

void kmeans::set_out_data(float* ptr1,float* ptr2)
{
	centers = ptr1;
	assign = ptr2;
	for(int i=0;i<ndata;i++)
		assign[i] = -1;
}

void kmeans::initialize()
{
  if(hasEmptyFeatureVector() && verbose)
		printf("Empty feature vector detected!\n");		
		
	srand(time(NULL));
	int index1 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
	int index2;
	do{
		index2 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
	}while(gcd(index1,index2) != 1);
	
	for(int i=0;i<ncluster;i++)
	{
		memcpy(centers + i * dimension, data + index1 * dimension, sizeof(float) * dimension);		
		index1 = index2 + index1;
		if(index1 >= ndata)
			index1 -= ndata;
	}
	
	if(hasEmptyClusterCenter() && verbose)
		printf("Empty initial cluster center detected!\n");
}

bool kmeans::hasEmptyFeatureVector()
{
	for(int i = 0; i < ndata; i++)
		if(get_sum(data + i * dimension) == 0)
			return true;
	return false;
}

bool kmeans::hasEmptyClusterCenter()
{
	for(int i = 0; i < ncluster; i++)
		if(get_sum(centers + i * dimension) == 0)
			return true;
	return false;
}

float kmeans::do_kmeans()
{
	initialize();
	float obj;
	niter = 0;
  do{
    if (verbose)    {
        printf("Iteration #%d\n", niter + 1);
        fflush(stdout);
    }
    clear_new_centers();
	obj = find_new_centers();
	niter++;
	}while(!hasConverged() && niter < maxiter);
	return obj;
}

void kmeans::clear_new_centers()
{
	memset(new_centers, 0, sizeof(float) * dimension * ncluster);
	memset(cluster_count, 0, sizeof(int) * ncluster);
}

float kmeans::find_new_centers()
{
  float sumdist = 0.0;
	for(int i=0;i<ndata;i++)
	{
		float min_distance;
		int min_index;
		int temp_min_index;
		if(assign[i] == -1)
		{
			min_distance = 10e10;
			min_index = -1;
			temp_min_index = -1;
		}
		else
		{
			min_index = static_cast<int>(assign[i]);
			
			if(verbose && (min_index < 0 || min_index >= ncluster))
				printf("Error : %d\n", min_index);
				
			temp_min_index = min_index;
			
			min_distance = get_sqdist(centers + min_index * dimension, data + i * dimension);
		}
		for(int j = 0; j < ncluster; j++)
		{
			if( j != temp_min_index )
			{
				float c_distance = get_sqdist(centers + j * dimension, data + i * dimension, min_distance);
				if(c_distance < min_distance)
				{
					min_distance = c_distance;
					min_index = j;
				}
			}
		}
		
		assign[i] = static_cast<float>(min_index);
		sumdist += min_distance;
		cluster_count[min_index] ++;
		add_vect(new_centers + min_index * dimension, data + i * dimension);
	}
	for(int i=0;i<ncluster;i++)
	{
		if(cluster_count[i] != 0)
			mult_vect(new_centers + i * dimension, 1. / static_cast<float>(cluster_count[i]));
    else
    {
            if (verbose)
			    printf("Empty Cluster Detected !\n");
			int assignement = rand()%ncluster;
			cluster_count[i] = 1;
			assign[assignement] = static_cast<float>(i);		
			memcpy(new_centers + i * dimension, data + assignement * dimension, sizeof(float) * dimension);
	  }
	}
	return sumdist;
}

bool kmeans::hasConverged()
{
	float distance = 0.;
	float epsilon = 1e-3;
	bool abort = false;
	for(int i=0;i<ncluster;i++)
	{	
		distance += sqrt(get_sqdist(centers + i * dimension, new_centers + i * dimension, epsilon));
		if(distance > epsilon)
		{
			abort = true;
			break;
		}
  }
  if (verbose) {
      printf("Cluster update: %f\n", distance);
      fflush(stdout);
  }
	if(!abort)
		return true;
	else
	{
		memcpy(centers, new_centers, sizeof(float) * ncluster * dimension);
    memset(new_centers, 0, sizeof(float) * ncluster * dimension);
		return false;
	}

}

int kmeans::getNiter()
{
	return niter;
}

void norm2(float *hist, int n)
{
	float s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i]*hist[i];
	s = sqrt(s);
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}
void norm1_with_cutoff(float *hist, int n, float cut_off_threshold)
{
	float s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;

	//Cut-off
	for(int i = 0; i < n; i++)
		if(hist[i] > cut_off_threshold)
			hist[i] = cut_off_threshold;

	//re-normalization
	s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}

#ifdef MEXFILE
void mexFunction(int nlhs,mxArray* plhs[],int nrhs,const mxArray* prhs[])
{
	 // [centers, assign, obj] = kmeansmex(data, nclusters, maxiter, verbose)
   if(nrhs!=3 && nrhs!=4)
     mexErrMsgTxt("Three or four input arguments required.");
   else if(nlhs!=3)
     mexErrMsgTxt("Three output arguments required.");
   else if(mxGetClassID(prhs[0]) != mxSINGLE_CLASS || mxGetNumberOfDimensions(prhs[0]) != 2)
     mexErrMsgTxt("First input should be a 2-dimensional array of type SINGLE.");  
   
    if (nrhs == 4)
        verbose = mxGetScalar(prhs[3]);
     
	// Reading input arguments
	float* data = (float*)mxGetPr(prhs[0]);

	int dimension = static_cast<int>(mxGetM(prhs[0]));
	int ndata = static_cast<int>(mxGetN(prhs[0]));

	int ncluster = static_cast<int>(mxGetScalar(prhs[1]));
	int maxiter = static_cast<int>(mxGetScalar(prhs[2]));
	
    if (verbose)
	    printf("%d-dimensional data, %d points.\n", dimension, ndata);

	// Seting output arguments

	plhs[0] = mxCreateNumericMatrix(dimension,ncluster,mxSINGLE_CLASS,mxREAL);
    float *centers = (float*)mxGetPr(plhs[0]);
	plhs[1] = mxCreateNumericMatrix(1,ndata,mxSINGLE_CLASS,mxREAL);
	float* assign = (float*)mxGetPr(plhs[1]);
	plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
	double* obj = mxGetPr(plhs[2]);

	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);
	*obj = KMEANS.do_kmeans();
}
#else
int main(int argc, char **argv)
{
	if(argc != 5)
	{
		cerr << "Usage: [kmeans] feature-file ncluster maxiter output-file" << endl;
		return 1;
	}

	int dimension = 0;
	int ndata = 0;
	
  //Load data
	FILE *File = fopen(argv[1], "rb");
	
	fread(&dimension, sizeof(int), 1, File);
	fread(&ndata, sizeof(int), 1, File);
	
	float *data = new float[ndata*dimension];
	fread(data, sizeof(float), dimension*ndata, File);
    fclose(File);	
	
	int ncluster = atoi(argv[2]); 
	int maxiter = atoi(argv[3]);
	ofstream fout(argv[4]);

	// Seting output arguments
	float *centers = new float[ncluster * dimension];
	float *assign = new float[ndata];
	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);

	float obj = KMEANS.do_kmeans();
	
	File = fopen(argv[4], "wb+");
	fwrite(centers, sizeof(float), dimension*ncluster, File);
	fwrite(assign, sizeof(float), ndata, File);
	fwrite(&obj, sizeof(float), 1, File);
  fclose(File);	

	return 0;
}
#endif
