#include "inputs.h"
#include <inttypes.h>
#include <stdio.h>
#include <string.h>

int main(int argument_count, char **argument_values)
{
    FILE *reference_file, *vulnerable_file;
    char reference_line[256], vulnerable_line[256];
    size_t category_counts[INPUT_CATEGORY_COUNT] = {0};
    size_t row_count = 0;
    uint64_t samples_per_category;
    if (argument_count != 4 || parse_unsigned_integer(argument_values[3], &samples_per_category) != 0) return 1;
    reference_file = fopen(argument_values[1], "r");
    vulnerable_file = fopen(argument_values[2], "r");
    if (reference_file == NULL || vulnerable_file == NULL) return 1;
    if (fgets(reference_line, sizeof(reference_line), reference_file) == NULL ||
        fgets(vulnerable_line, sizeof(vulnerable_line), vulnerable_file) == NULL ||
        strcmp(reference_line, "run_id,implementation,input_category,sample_index,elapsed_nanoseconds,time_unit\n") != 0 ||
        strcmp(reference_line, vulnerable_line) != 0) return 1;
    while (fgets(reference_line, sizeof(reference_line), reference_file) != NULL) {
        char reference_run_id[65], vulnerable_run_id[65], implementation_name[32];
        char reference_category[32], vulnerable_category[32], time_unit[8];
        size_t sample_index;
        uint64_t elapsed_nanoseconds;
        enum input_category category;
        if (fgets(vulnerable_line, sizeof(vulnerable_line), vulnerable_file) == NULL) return 1;
        if (sscanf(reference_line, "%64[^,],%31[^,],%31[^,],%zu,%" SCNu64 ",%7s", reference_run_id,
            implementation_name, reference_category, &sample_index, &elapsed_nanoseconds, time_unit) != 6 ||
            strcmp(implementation_name, "reference") != 0 || sample_index != row_count ||
            elapsed_nanoseconds == 0 || strcmp(time_unit, "ns") != 0) return 1;
        if (sscanf(vulnerable_line, "%64[^,],%31[^,],%31[^,],%zu,%" SCNu64 ",%7s", vulnerable_run_id,
            implementation_name, vulnerable_category, &sample_index, &elapsed_nanoseconds, time_unit) != 6 ||
            strcmp(implementation_name, "vulnerable") != 0 || sample_index != row_count ||
            elapsed_nanoseconds == 0 || strcmp(time_unit, "ns") != 0) return 1;
        if (strcmp(reference_category, vulnerable_category) != 0 || parse_input_category(reference_category, &category) != 0) return 1;
        ++category_counts[category];
        ++row_count;
    }
    if (fgetc(vulnerable_file) != EOF || ferror(reference_file) || ferror(vulnerable_file)) return 1;
    if (fclose(reference_file) != 0 || fclose(vulnerable_file) != 0) return 1;
    if (row_count != samples_per_category * INPUT_CATEGORY_COUNT) return 1;
    for (unsigned category_index = 0; category_index < INPUT_CATEGORY_COUNT; ++category_index)
        if (category_counts[category_index] != samples_per_category) return 1;
    printf("CSV row counts, units, positive raw values and reproducible category order passed: %zu rows per version\n", row_count);
    return 0;
}
