#ifdef __APPLE__
#include <OpenCL/opencl.h>
#else
#include <CL/cl.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>


#if defined(_WIN32)

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

uint64_t get_time_micros(void) {
    static LARGE_INTEGER freq;
    LARGE_INTEGER counter;

    if (freq.QuadPart == 0) {
        QueryPerformanceFrequency(&freq);
    }

    QueryPerformanceCounter(&counter);

    return (uint64_t)((counter.QuadPart * 1000000ULL) / freq.QuadPart);
}

#elif defined(__unix__) || defined(__APPLE__)

#include <sys/time.h>
#include <time.h>

uint64_t get_time_micros(void) {
#if defined(CLOCK_MONOTONIC)
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000ULL + (uint64_t)ts.tv_nsec / 1000ULL;
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000000ULL + (uint64_t)tv.tv_usec;
#endif
}

#else

#error "Unsupported platform"

#endif

typedef struct {
    uint64_t *slots;
    size_t capacity; // must be a power of 2
    size_t size;
} HashSet;

static uint64_t hash_u64(uint64_t x) {
    x ^= x >> 30;
    x *= UINT64_C(0xbf58476d1ce4e5b9);
    x ^= x >> 27;
    x *= UINT64_C(0x94d049bb133111eb);
    x ^= x >> 31;
    return x;
}

unsigned int next_power_of_2(unsigned int n) {
    if (n <= 1) return 1;

    n--;
    n |= n >> 1;
    n |= n >> 2;
    n |= n >> 4;
    n |= n >> 8;
    n |= n >> 16;
    return n + 1;
}

bool hashset_init(HashSet *set, size_t capacity) {
    // capacity should be a power of 2
    set->slots = calloc(capacity, sizeof(uint64_t));
    if (!set->slots) return false;

    set->capacity = capacity;
    set->size = 0;
    return true;
}

void hashset_free(HashSet *set) {
    free(set->slots);
    set->slots = NULL;
    set->capacity = 0;
    set->size = 0;
}

bool hashset_insert(HashSet *set, uint64_t value) {
    // value must not be 0
    uint64_t h = hash_u64(value);
    size_t mask = set->capacity - 1;
    size_t i = h & mask;

    while (true) {
        if (set->slots[i] == 0) {
            set->slots[i] = value;
            set->size++;
            return true; // newly inserted
        }

        if (set->slots[i] == value) {
            return false; // already present
        }

        i = (i + 1) & mask; // linear probing
    }
}

#define CHECK_CL(err, msg) \
    do { \
        if ((err) != CL_SUCCESS) { \
            fprintf(stderr, "%s failed with OpenCL error %d\n", (msg), (err)); \
            exit(EXIT_FAILURE); \
        } \
    } while (0)

static char *read_file(const char *filename, size_t *size_out) {
    FILE *f = fopen(filename, "rb");
    if (!f) return NULL;

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    rewind(f);

    char *buf = malloc((size_t)size + 1);
    if (!buf) {
        fclose(f);
        return NULL;
    }

    size_t got = fread(buf, 1, (size_t)size, f);
    fclose(f);
    buf[got] = '\0';

    if (size_out) *size_out = got;
    return buf;
}

static void print_build_log(cl_program program, cl_device_id device) {
    size_t log_size = 0;
    clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);

    char *log = malloc(log_size + 1);
    if (!log) return;

    clGetProgramBuildInfo(program, device, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);
    log[log_size] = '\0';
    fprintf(stderr, "%s\n", log);
    free(log);
}

#define KERNELFILE "kernels/v8.cl"
int main(void) {
    cl_int err;

    const uint64_t thousand = 1000ULL;
    const uint64_t million = 1000ULL * thousand;
    const uint64_t billion = 1000ULL * million;
    const uint64_t trillion = 1000ULL * billion;

    const uint64_t min = 0;
    const uint64_t max = 10ULL * billion;

    // Maximum number to be retured
    const uint64_t max_matches = 100000 + 0.0001 * (max - min);

    cl_uint num_platforms = 0;
    err = clGetPlatformIDs(0, NULL, &num_platforms);
    CHECK_CL(err, "clGetPlatformIDs count");

    if (num_platforms == 0) {
        fprintf(stderr, "No OpenCL platforms found\n");
        return 1;
    }

    cl_platform_id platform;
    err = clGetPlatformIDs(1, &platform, NULL);
    CHECK_CL(err, "clGetPlatformIDs first");

    cl_device_id device;
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 1, &device, NULL);
    if (err != CL_SUCCESS) {
        err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_CPU, 1, &device, NULL);
        CHECK_CL(err, "clGetDeviceIDs fallback CPU");
    }

    char device_name[256];
    err = clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(device_name), device_name, NULL);
    CHECK_CL(err, "clGetDeviceInfo");
    fprintf(stderr, "Using device: %s\n", device_name);

    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    CHECK_CL(err, "clCreateContext");

    cl_command_queue queue = clCreateCommandQueue(context, device, 0, &err);
    CHECK_CL(err, "clCreateCommandQueue");

    size_t source_size;
    char *source = read_file(KERNELFILE, &source_size);
    if (!source) {
        fprintf(stderr, "Could not read kernel file\n");
        return 1;
    }

    cl_program program = clCreateProgramWithSource(context, 1,
                                                   (const char **)&source,
                                                   &source_size, &err);
    CHECK_CL(err, "clCreateProgramWithSource");

    const char *options = "-cl-mad-enable";
    err = clBuildProgram(program, 1, &device, options, NULL, NULL);
    if (err != CL_SUCCESS) {
        fprintf(stderr, "Build failed\n");
        print_build_log(program, device);
        return 1;
    }

    cl_kernel kernel = clCreateKernel(program, "search_matches", &err);
    CHECK_CL(err, "clCreateKernel");

    cl_mem matches_buf = clCreateBuffer(context,
                                        CL_MEM_WRITE_ONLY,
                                        sizeof(uint64_t) * max_matches,
                                        NULL, &err);
    CHECK_CL(err, "clCreateBuffer matches");

    uint64_t timer_start_create_buff = get_time_micros();

    uint32_t zero = 0;
    cl_mem count_buf = clCreateBuffer(context,
                                    CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                    sizeof(uint32_t),
                                    &zero, &err);
    CHECK_CL(err, "clCreateBuffer count");

    uint64_t timer_end_create_buff = get_time_micros();

    err = clSetKernelArg(kernel, 0, sizeof(uint64_t), &min);
    CHECK_CL(err, "arg 0");

    err = clSetKernelArg(kernel, 1, sizeof(uint64_t), &max);
    CHECK_CL(err, "arg 1");

    err = clSetKernelArg(kernel, 2, sizeof(cl_mem), &matches_buf);
    CHECK_CL(err, "arg 2");

    err = clSetKernelArg(kernel, 3, sizeof(cl_mem), &count_buf);
    CHECK_CL(err, "arg 3");

    err = clSetKernelArg(kernel, 4, sizeof(uint64_t), &max_matches);
    CHECK_CL(err, "arg 4");

    uint64_t timer_start_run_gpu = get_time_micros();

    size_t global_work_size = max - min;
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL,
                                 &global_work_size, NULL,
                                 0, NULL, NULL);
    CHECK_CL(err, "clEnqueueNDRangeKernel");

    err = clFinish(queue);
    CHECK_CL(err, "clFinish");

    uint64_t timer_end_run_gpu = get_time_micros();
    
    uint64_t timer_start_read_buff = get_time_micros();
    unsigned int match_count = 0;
    err = clEnqueueReadBuffer(queue, count_buf, CL_TRUE, 0,
                              sizeof(unsigned int), &match_count,
                              0, NULL, NULL);
    CHECK_CL(err, "read count");
    fprintf(stderr, "Raw match count reported: %u / %lu\n", match_count, max_matches);

    uint64_t to_read = match_count;
    if (to_read > max_matches) {
        to_read = max_matches;
        fprintf(stderr, "WARNING: output buffer overflowed; truncated to %lu matches\n", max_matches);
    }

    uint64_t *matches = malloc(sizeof(uint64_t) * to_read);
    if (!matches && to_read > 0) {
        fprintf(stderr, "Host allocation failed\n");
        return 1;
    }

    if (to_read > 0) {
        err = clEnqueueReadBuffer(queue, matches_buf, CL_TRUE, 0,
                                  sizeof(uint64_t) * to_read,
                                  matches, 0, NULL, NULL);
        CHECK_CL(err, "read matches");

        // Write raw data to disk immediately, before any processing that could crash
        FILE *raw = fopen("matches_raw.bin", "wb");
        if (raw) {
            fwrite(&to_read,  sizeof(uint64_t), 1,       raw);  // header: count
            fwrite(matches,   sizeof(uint64_t), to_read, raw);
            fclose(raw);
            fprintf(stderr, "Raw matches saved to matches_raw.bin\n");
        }
    }
    uint64_t timer_end_read_buff = get_time_micros();

                // uint64_t oOrig = matches[i];
            // if (oOrig == 222678959859ULL || oOrig == 595703ULL || oOrig == 610999ULL) {
            //     printf("out: %lu\n", oOrig);
            // }

    uint64_t timer_start_dedup_and_print = get_time_micros();
    HashSet seen;
    if (!hashset_init(&seen, next_power_of_2(1.2 * max_matches))) {
        return 1;
    }

    int num_deduped = 0;
    printf("{");
    for (uint64_t i = 0; i < match_count; ++i) {
        if (matches[i] != 0 && hashset_insert(&seen, matches[i])) {
            printf("%lu, \n", matches[i]);
            num_deduped++;
        }
    }
    hashset_free(&seen);
    printf("0}");

    uint64_t timer_end_dedup_and_print = get_time_micros();

    fprintf(stderr, "\n-----\n");

    fprintf(stderr, "Bounds    | min: %lu, max: %lu  | Procecessed %lu initial coniditions in total.\n", min, max, (max - min) >> 1);
    fprintf(stderr, "Matched   | matches: %u, max_matches: %lu (%f%% of Buffer Size)\n", match_count, max_matches, ((float)(100 * match_count))/((float)(max_matches)));
    fprintf(stderr, "Deduped   | deduped: %i | Filtered initial conditions by a factor of %lu thousand.\n", num_deduped, ((max - min) >> 1) / (thousand * num_deduped));
    fprintf(stderr, "Timing    | create_buff: %luus, run_gpu: %luus (%lus), read_buff: %luus, dedup_and_print: %luus (%lus)\n", timer_end_create_buff - timer_start_create_buff, timer_end_run_gpu - timer_start_run_gpu,(timer_end_run_gpu - timer_start_run_gpu) / million, timer_end_read_buff - timer_start_read_buff, timer_end_dedup_and_print - timer_start_dedup_and_print, (timer_end_dedup_and_print - timer_start_dedup_and_print) / million);



    if (match_count >= max_matches) {
        fprintf(stderr, "WARNING! BUFFER EXCEEDED! SOME INITIAL CONDITIONS HAVE BEEN LOST.");
    }

    free(matches);
    free(source);

    clReleaseMemObject(matches_buf);
    clReleaseMemObject(count_buf);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    if (match_count >= max_matches) {
        return 1;
    }

    return 0;
}