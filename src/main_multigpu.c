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

uint64_t next_power_of_2(uint64_t n) {
    if (n <= 1) return 1UL;

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


typedef struct {
    cl_device_id device;
    cl_context context;
    cl_command_queue queue;
    cl_program program;
    cl_kernel kernel;
    cl_mem matches_buf;
    cl_mem count_buf;
} GPUContext;

int main(void) {
    cl_int err;

    const uint64_t thousand = 1000ULL;
    const uint64_t million = 1000ULL * thousand;
    const uint64_t billion = 1000ULL * million;
    const uint64_t trillion = 1000ULL * billion;

    // const uint64_t min = 5230000000000UL;
    // const uint64_t max = 5240000000000UL;

    const uint64_t min = 0;
    const uint64_t max = 30 * billion;

    // Maximum number to be retured
    const uint64_t max_matches = 100000 + 0.00001 * (max - min);
    fprintf(stderr, "allocating %lu (%lu Mb) for buffer\n", max_matches, max_matches * 8 / million);

    // Get all GPU devices
    cl_uint num_platforms = 0;
    err = clGetPlatformIDs(0, NULL, &num_platforms);
    CHECK_CL(err, "clGetPlatformIDs count");

    cl_platform_id platform;
    err = clGetPlatformIDs(1, &platform, NULL);
    CHECK_CL(err, "clGetPlatformIDs first");

    cl_uint num_devices = 0;
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, 0, NULL, &num_devices);
    
    if (num_devices == 0) {
        err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_CPU, 0, NULL, &num_devices);
        if (num_devices == 0) {
            fprintf(stderr, "No compute devices found\n");
            return 1;
        }
    }

    fprintf(stderr, "Found %u compute devices\n", num_devices);

    cl_device_id *devices = malloc(num_devices * sizeof(cl_device_id));
    err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_GPU, num_devices, devices, NULL);
    if (err != CL_SUCCESS) {
        err = clGetDeviceIDs(platform, CL_DEVICE_TYPE_CPU, num_devices, devices, NULL);
        CHECK_CL(err, "clGetDeviceIDs");
    }

    // Initialize context for each device
    GPUContext *gpu_contexts = malloc(num_devices * sizeof(GPUContext));
    
    size_t source_size;
    char *source = read_file(KERNELFILE, &source_size);
    if (!source) {
        fprintf(stderr, "Could not read kernel file\n");
        return 1;
    }

    for (cl_uint i = 0; i < num_devices; i++) {
        char device_name[256];
        clGetDeviceInfo(devices[i], CL_DEVICE_NAME, sizeof(device_name), device_name, NULL);
        fprintf(stderr, "Initializing device %u: %s\n", i, device_name);

        GPUContext *ctx = &gpu_contexts[i];
        ctx->device = devices[i];
        
        ctx->context = clCreateContext(NULL, 1, &ctx->device, NULL, NULL, &err);
        CHECK_CL(err, "clCreateContext");

        ctx->queue = clCreateCommandQueue(ctx->context, ctx->device, 0, &err);
        CHECK_CL(err, "clCreateCommandQueue");

        cl_program program = clCreateProgramWithSource(ctx->context, 1,
                                                       (const char **)&source,
                                                       &source_size, &err);
        CHECK_CL(err, "clCreateProgramWithSource");

        const char *options = "-cl-mad-enable";
        err = clBuildProgram(program, 1, &ctx->device, options, NULL, NULL);
        if (err != CL_SUCCESS) {
            fprintf(stderr, "Build failed on device %u\n", i);
            print_build_log(program, ctx->device);
            return 1;
        }

        ctx->program = program;
        ctx->kernel = clCreateKernel(program, "search_matches", &err);
        CHECK_CL(err, "clCreateKernel");

        // Per-GPU buffers (each GPU gets its own)
        ctx->matches_buf = clCreateBuffer(ctx->context,
                                         CL_MEM_WRITE_ONLY,
                                         sizeof(uint64_t) * max_matches,
                                         NULL, &err);
        CHECK_CL(err, "clCreateBuffer matches");

        uint32_t zero = 0;
        ctx->count_buf = clCreateBuffer(ctx->context,
                                       CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                       sizeof(uint32_t),
                                       &zero, &err);
        CHECK_CL(err, "clCreateBuffer count");
    }

    free(source);

    // Distribute work across GPUs
    uint64_t batch_size = 1ULL << 31;
    uint64_t range = max - min;
    uint64_t num_batches = (range + batch_size - 1) / batch_size;

    fprintf(stderr, "Dispatching %lu batches across %u devices\n", num_batches, num_devices);

    uint64_t timer_start_run_gpu = get_time_micros();

    for (uint64_t batch = 0; batch < num_batches; ++batch) {
        uint64_t batch_min = min + (batch * batch_size);
        uint64_t batch_max = batch_min + batch_size;
        if (batch_max > max) batch_max = max;
        uint64_t batch_range = batch_max - batch_min;

        fprintf(stderr, "  [%lu/%lu] Processing [%lu, %lu)\n", 
                batch + 1, num_batches, batch_min, batch_max);

        // Launch on ALL devices in parallel
        for (cl_uint dev = 0; dev < num_devices; dev++) {
            GPUContext *ctx = &gpu_contexts[dev];

            err = clSetKernelArg(ctx->kernel, 0, sizeof(uint64_t), &batch_min);
            CHECK_CL(err, "arg 0");
            err = clSetKernelArg(ctx->kernel, 1, sizeof(uint64_t), &batch_max);
            CHECK_CL(err, "arg 1");
            err = clSetKernelArg(ctx->kernel, 2, sizeof(cl_mem), &ctx->matches_buf);
            CHECK_CL(err, "arg 2");
            err = clSetKernelArg(ctx->kernel, 3, sizeof(cl_mem), &ctx->count_buf);
            CHECK_CL(err, "arg 3");
            err = clSetKernelArg(ctx->kernel, 4, sizeof(uint64_t), &max_matches);
            CHECK_CL(err, "arg 4");

            size_t global_work_size = batch_range;
            err = clEnqueueNDRangeKernel(ctx->queue, ctx->kernel, 1, NULL,
                                        &global_work_size, NULL,
                                        0, NULL, NULL);
            CHECK_CL(err, "clEnqueueNDRangeKernel");
        }

        // Wait for ALL devices to finish
        for (cl_uint dev = 0; dev < num_devices; dev++) {
            err = clFinish(gpu_contexts[dev].queue);
            CHECK_CL(err, "clFinish");
        }
    }

    uint64_t timer_end_run_gpu = get_time_micros();

    // Read results from all devices and merge
    uint64_t timer_start_read_buff = get_time_micros();
    
    HashSet all_matches;
    if (!hashset_init(&all_matches, next_power_of_2(1.2 * max_matches * num_devices))) {
        return 1;
    }

    unsigned int total_match_count = 0;

    for (cl_uint dev = 0; dev < num_devices; dev++) {
        GPUContext *ctx = &gpu_contexts[dev];

        unsigned int match_count = 0;
        err = clEnqueueReadBuffer(ctx->queue, ctx->count_buf, CL_TRUE, 0,
                                  sizeof(unsigned int), &match_count,
                                  0, NULL, NULL);
        CHECK_CL(err, "read count");

        fprintf(stderr, "Device %u: %u matches\n", dev, match_count);
        total_match_count += match_count;

        uint64_t to_read = match_count;
        if (to_read > max_matches) {
            to_read = max_matches;
            fprintf(stderr, "WARNING: Device %u buffer overflowed\n", dev);
        }

        if (to_read > 0) {
            uint64_t *matches = malloc(sizeof(uint64_t) * to_read);
            if (!matches) {
                fprintf(stderr, "Host allocation failed\n");
                return 1;
            }

            err = clEnqueueReadBuffer(ctx->queue, ctx->matches_buf, CL_TRUE, 0,
                                      sizeof(uint64_t) * to_read,
                                      matches, 0, NULL, NULL);
            CHECK_CL(err, "read matches");

            // Merge into global set
            for (uint64_t i = 0; i < to_read; i++) {
                if (matches[i] != 0) {
                    hashset_insert(&all_matches, matches[i]);
                }
            }

            free(matches);
        }
    }

    uint64_t timer_end_read_buff = get_time_micros();

    uint64_t timer_start_print = get_time_micros();
    
    printf("{");
    for (size_t i = 0; i < all_matches.capacity; i++) {
        if (all_matches.slots[i] != 0) {
            printf("%lu, \n", all_matches.slots[i]);
        }
    }
    printf("0}");

    uint64_t timer_end_print = get_time_micros();

    fprintf(stderr, "\n-----\n");
    fprintf(stderr, "Devices   | %u GPUs\n", num_devices);
    fprintf(stderr, "Matched   | total matches: %u\n", total_match_count);
    fprintf(stderr, "Deduped   | unique: %lu\n", all_matches.size);
    fprintf(stderr, "Timing    | run_gpu: %luus (%lus), read_buff: %luus, print: %luus\n", 
            timer_end_run_gpu - timer_start_run_gpu,
            (timer_end_run_gpu - timer_start_run_gpu) / million,
            timer_end_read_buff - timer_start_read_buff,
            timer_end_print - timer_start_print);

    // Cleanup
    hashset_free(&all_matches);
    
    for (cl_uint i = 0; i < num_devices; i++) {
        clReleaseMemObject(gpu_contexts[i].matches_buf);
        clReleaseMemObject(gpu_contexts[i].count_buf);
        clReleaseKernel(gpu_contexts[i].kernel);
        clReleaseProgram(gpu_contexts[i].program);
        clReleaseCommandQueue(gpu_contexts[i].queue);
        clReleaseContext(gpu_contexts[i].context);
    }

    free(gpu_contexts);
    free(devices);

    return 0;
}