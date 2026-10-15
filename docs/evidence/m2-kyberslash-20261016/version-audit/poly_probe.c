#include "poly.h"
#include "polyvec.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#if defined(M2_HAVE_VALGRIND)
#include <valgrind/memcheck.h>
#endif

int main(void)
{
    poly polynomial;
    polyvec polynomial_vector;
    uint8_t message[KYBER_INDCPA_MSGBYTES];
    uint8_t compressed_polynomial[KYBER_POLYCOMPRESSEDBYTES];
    uint8_t compressed_vector[KYBER_POLYVECCOMPRESSEDBYTES];
    volatile uint8_t consumed_output = 0;

    /* 固定公开夹具只用于污点定位，不含真实密钥。 */
    for (size_t coefficient_index = 0; coefficient_index < KYBER_N; coefficient_index++) {
        polynomial.coeffs[coefficient_index] = (int16_t)((coefficient_index * 13U) % KYBER_Q);
        for (size_t vector_index = 0; vector_index < KYBER_K; vector_index++) {
            polynomial_vector.vec[vector_index].coeffs[coefficient_index] =
                polynomial.coeffs[coefficient_index];
        }
    }

#if defined(M2_HAVE_VALGRIND)
    VALGRIND_MAKE_MEM_UNDEFINED(&polynomial, sizeof(polynomial));
    VALGRIND_MAKE_MEM_UNDEFINED(&polynomial_vector, sizeof(polynomial_vector));
#endif

    poly_tomsg(message, &polynomial);
    poly_compress(compressed_polynomial, &polynomial);
    polyvec_compress(compressed_vector, &polynomial_vector);

#if defined(M2_HAVE_VALGRIND)
    VALGRIND_MAKE_MEM_DEFINED(&polynomial, sizeof(polynomial));
    VALGRIND_MAKE_MEM_DEFINED(&polynomial_vector, sizeof(polynomial_vector));
    VALGRIND_MAKE_MEM_DEFINED(message, sizeof(message));
    VALGRIND_MAKE_MEM_DEFINED(compressed_polynomial, sizeof(compressed_polynomial));
    VALGRIND_MAKE_MEM_DEFINED(compressed_vector, sizeof(compressed_vector));
#endif

    for (size_t output_index = 0; output_index < sizeof(message); output_index++) {
        consumed_output ^= message[output_index];
    }
    for (size_t output_index = 0; output_index < sizeof(compressed_polynomial); output_index++) {
        consumed_output ^= compressed_polynomial[output_index];
    }
    for (size_t output_index = 0; output_index < sizeof(compressed_vector); output_index++) {
        consumed_output ^= compressed_vector[output_index];
    }
    (void)consumed_output;
    puts("kyberslash polynomial probe complete");
    return 0;
}
