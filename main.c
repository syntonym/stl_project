#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <plasma.h>
#include <quark.h>
#include <papi.h>
#include <cblas.h>
#include <lapacke.h>

int is_close(double a, double b){
	return (fabs(a - b) < 0.1E-12);
}

void generateMatrix(double *A, int n) {

	double random_number;
	srand(time(NULL));

	for (int j = 0; j < n; j++) {
		for (int i=j; i<n; i++) {
			random_number = ((double)rand() / ( (double)RAND_MAX ));
			A[i*n+j] = random_number;
			A[j*n+i] = random_number;
		}
	}

	// make positiv definit
	for (int i=0; i<n; i++) {
		A[i*n+i] += n;
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

double residual(double* L, double* A, double* work, int n) {

	//make L lower triangular
	for (int j=1; j<n; j++) {
		for (int i=0; i<j; i++) {
			L[j*n+i]=0;
		}
	}

	// L L^t
	PLASMA_dgemm(PlasmaNoTrans, PlasmaTrans, n, n, n, 1, L, n, L, n, 0, work, n);

	// LL^t - A
    	cblas_daxpy( n*n, -1, A, 1, work, 1 );

	double o_value = PLASMA_dlange(PlasmaOneNorm, n, n, work, n);
	double A_norm = PLASMA_dlange(PlasmaOneNorm, n, n, A, n);

	return o_value/A_norm;

}

int measure_PLASMA_dpotrf(double* A, double* L, double* work, PLASMA_enum uplo, int n, int cores) {

	// papi variables
	float rtime, ptime, mflops;
	long long flpops;

	double res;
	int error;

	error = PLASMA_Init(cores);
	if (error != PLASMA_SUCCESS) {
		printf("{\"type\": \"error\", \"errorcode\": %i, \"msg\": \"Error in PLASMA_Init: %i\"}\n", error, error);
		exit(1);
	}

	PAPI_flops(&rtime, &ptime, &flpops, &mflops);
	error = PLASMA_dpotrf(uplo, n, L, n);
	PAPI_flops(&rtime, &ptime, &flpops, &mflops);


	res = residual(L, A, work, n);

	printf("{ \"type\":\"result\", \"data\":{ \"n\": %i, \"rtime\" : %f, \"ptime\": %f, \"flpops\": %llu , \"mflops\": %f, \"res\": %e, \"cores\": %i}}\n", n, rtime, ptime, flpops, mflops, res, cores);

	if (error != PLASMA_SUCCESS) {
		printf("{\"type\": \"error\", \"errorcode\": %i, \"msg\": \"Error in PLASMA_dpotrf: %i\"}\n", error, error);
		exit(1);
	}
	error = PLASMA_Finalize();
	if (error != PLASMA_SUCCESS) {
		printf("{\"type\": \"error\", \"errorcode\": %i, \"msg\": \"Error in PLASMA_Finalize:%i\"}\n", error, error);
		exit(1);
	}

	return 0;
}

int measure_LAPACK_dpotrf(double* A, double* L, double* work, int n) {
	// papi variables
	float rtime, ptime, mflops;
	long long flpops;

	double res;
	int error;

	char uplo = 'L';
	int info = 0;

	PAPI_flops(&rtime, &ptime, &flpops, &mflops);
	dpotrf_(&uplo, &n, L, &n, &info);
	PAPI_flops(&rtime, &ptime, &flpops, &mflops);


	error = PLASMA_Init(24);
	res = residual(L, A, work, n);

	printf("{ \"type\":\"result\", \"data\":{ \"n\": %i, \"rtime\" : %f, \"ptime\": %f, \"flpops\": %llu , \"mflops\": %f, \"res\": %e, \"cores\": \"lapack\"}}\n", n, rtime, ptime, flpops, mflops, res);

	if (error != PLASMA_SUCCESS) {
		printf("{\"type\": \"error\", \"errorcode\": %i, \"msg\": \"Error in PLASMA_dpotrf: %i\"}\n", error, error);
		exit(1);
	}
	error = PLASMA_Finalize();
	if (error != PLASMA_SUCCESS) {
		printf("{\"type\": \"error\", \"errorcode\": %i, \"msg\": \"Error in PLASMA_Finalize:%i\"}\n", error, error);
		exit(1);
	}

	return 0;
}

/**
 *
 * main N CORES
 *
 * N (int) - dimension of problem
 * CORES (int) - how many cores to use for plasma
 *
 */
int main(int argc, char **argv)
{
	if (argc < 3) {
		printf("Too few arguments\n");
		exit(1);
	}
	int n = atoi(argv[1]);
	double* A = calloc(n*n, sizeof(double));
	double* B = calloc(n*n, sizeof(double));
	double * work = malloc(n*n*sizeof(double));
	PLASMA_enum uplo=PlasmaLower; //here: does not matter, as we store the full matrix
	generateMatrix(A, n);
	cloneMatrix(A, B, n);

	int cores = atoi(argv[2]);

	if (argv[2][0] == 'l') {
		measure_LAPACK_dpotrf(A, B, work, n);
	} else {
		measure_PLASMA_dpotrf(A, B, work, uplo, n, cores);
	}

	free(A);
	free(B);
	free(work);
}
