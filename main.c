#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <plasma.h>
#include <quark.h>
#include <papi.h>
#include <cblas.h>

int is_close(double a, double b){
	return (fabs(a - b) < 0.1E-12);
}

void generateMatrix(double *A, int n) {

	double random_number;
	srand(time(NULL));

	for (int j = 0; j < n; j++) {
		for (int i=j; i<n; i++) {
			random_number = ((double)rand() / (((double) 10) * (double)RAND_MAX ));
			A[i*n+j] = random_number;
			A[j*n+i] = random_number;
		}
	}

	// make positiv definit
	for (int i=0; i<n; i++) {
		A[i*n+i] = (double) INT_MAX;
	}

}

	
void printMatrix(const double * A, int n) {

	printf("\n\n%s\n", "Matrix: ");
	for (int j = 0; j < n; j++) {
		printf("\n");
		for (int i=0; i<n; i++) printf("%f ", A[i*n+j]);
	}
	printf("\n");

}

void generateEye(double *A, int n) {

	for (int i=0; i< n; i++) A[i] = 0;

	for (int j = 0; j < n; j++) {
		A[j*n+j] = 1;
	}

}

void cloneMatrix(double* A, double* B, int n) {
	for (int i=0; i<(n*n); i++) {
		B[i] = A[i];
	}
}

int residual(double* L, double* A, double* work, int n) {
	char norm = '1';
	// L L^t
	cblas_dgemm(CblasColMajor, CblasNoTrans, CblasTrans, n, n, n, 1, L, n, L, n, 0, work, n);

	// LL^t - A
	for (int i=0; i<(n*n); i++) {
		work[i] = work[i] - A[i];
	}

	double o_value = dlange_(&norm, &n, &n, work, &n, NULL);

	return o_value;

}

int main()
{
	int n = 1000;
	double* A = calloc(n*n, sizeof(double));
	double* B = calloc(n*n, sizeof(double));
	PLASMA_enum uplo=PlasmaUpper; //here: does not matter, as we store the full matrix
	generateMatrix(A, n);
	cloneMatrix(A, B, n);
	int error;

	// papi variables
	float rtime, ptime, mflops;
	long long flpops;
	double res;

	error = PLASMA_Init(1); //spawn cores for PLASMA
	if (error != PLASMA_SUCCESS) {
		printf("Error in PLASMA_Init: %i\n", error);
		exit (1);
	}

	//printMatrix(A, n);

	PAPI_flops(&rtime, &ptime, &flpops, &mflops);
	error = PLASMA_dpotrf(uplo, n, A, n);
	PAPI_flops(&rtime, &ptime, &flpops, &mflops);

	double * work = malloc(n*n*sizeof(double));
	res = residual(A, B, work, n);
	printf("{ \"n\": %i, \"rtime\" : %f, \"ptime\": %f, \"flpops\": %llu , \"mflops\": %f, \"res\": %f}\n", n, rtime, ptime, flpops, mflops, res);

	if (error != PLASMA_SUCCESS) {
		printf("Error in PLASMA_dpotrf: %i\n", error);
		exit (1);
	}
	error = PLASMA_Finalize();
	if (error != PLASMA_SUCCESS) {
		printf("Error in PLASMA_Finalize:%i\n", error);
		exit (1);
	}
}
