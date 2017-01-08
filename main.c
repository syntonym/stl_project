#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <plasma.h>
#include <papi.h>

int is_close(double a, double b){
	return (fabs(a - b) < 0.1E-12);
}

void init_matrix(double* A, int n) {
	for (int i=0; i<n+n; i++) {
		A[i] = ((double)rand() / (((double) 10) * (double)RAND_MAX ));
	}

	// make symetric
	for (int i=0; i<n; i++) {
		for (int k=0; k<n; k++) {
			if (k<i) {
				A[k+(i*n)] = A[i+(k*n)];
			}
		}
	}

	// make positiv definit
	for (int i=0; i<n; i+=(n+1)) {
		A[i] = (double)RAND_MAX;
	}
}

int main()
{
	int n = 100;
	double* A = calloc(n*n, sizeof(double));
	PLASMA_enum uplo=PlasmaUpper; //here: does not matter, as we store the full matrix
	init_matrix(A, n);
	int error;

	// papi variables
	float rtime, ptime, mflops;
	long long flpops;
	float o_rtime, o_ptime, o_mflops;
	long long o_flpops;
	double res;

	error = PLASMA_Init(1); //spawn cores for PLASMA
	if (error != PLASMA_SUCCESS) {
		printf("Error in PLASMA_Init: %i\n", error);
		exit (1);
	}

	PAPI_flops(&rtime, &ptime, &flpops, &mflops);
	error = PLASMA_dpotrf(uplo, n, A, n);
	PAPI_flops(&rtime, &ptime, &flpops, &mflops);
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
