#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <plasma.h>

int is_close(double a, double b){
	return (fabs(a - b) < 0.1E-12);
}

void init_matrix(double* A, int n) {
	for (int i=0; i<n+n; i++) {
		A[i] = ((double)rand() / (double)RAND_MAX);
	}

	// make symetric
	for (int i=0; i<n; i++) {
		for (int k=0; k<n; k++) {
			if (k<i) {
				A[k+(i*n)] = A[i+(k*n)];
			}
		}
	}
}

int main()
{
int n = 100;
double* A = calloc(n*n, sizeof(double));
PLASMA_enum uplo=PlasmaUpper; //here: does not matter, as we store the full matrix
init_matrix(A, n);
int error;

error = PLASMA_Init(1); //spawn cores for PLASMA
if (error != PLASMA_SUCCESS) exit (1);
error = PLASMA_dpotrf(uplo, n, A, n);
if (error != PLASMA_SUCCESS) exit (1);
error = PLASMA_Finalize();
if (error != PLASMA_SUCCESS) exit (1);
}
