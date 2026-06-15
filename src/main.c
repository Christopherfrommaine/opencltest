#include <CL/cl.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

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

int main(void) {
    cl_int err;

    const uint64_t min = 0;
    const uint64_t max = 1000 * 1000 * 1000;

    // Maximum number to be retured
    const uint64_t max_matches = 0.01 * (max - min);

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
    printf("Using device: %s\n", device_name);

    cl_context context = clCreateContext(NULL, 1, &device, NULL, NULL, &err);
    CHECK_CL(err, "clCreateContext");

    cl_command_queue queue = clCreateCommandQueue(context, device, 0, &err);
    CHECK_CL(err, "clCreateCommandQueue");

    size_t source_size;
    char *source = read_file("kernels/search_matches.cl", &source_size);
    if (!source) {
        fprintf(stderr, "Could not read kernel file\n");
        return 1;
    }

    cl_program program = clCreateProgramWithSource(context, 1,
                                                   (const char **)&source,
                                                   &source_size, &err);
    CHECK_CL(err, "clCreateProgramWithSource");

    err = clBuildProgram(program, 1, &device, NULL, NULL, NULL);
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

    uint32_t zero = 0;
    cl_mem count_buf = clCreateBuffer(context,
                                    CL_MEM_READ_WRITE | CL_MEM_COPY_HOST_PTR,
                                    sizeof(uint32_t),
                                    &zero, &err);
    CHECK_CL(err, "clCreateBuffer count");

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

    size_t global_work_size = max - min;
    err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL,
                                 &global_work_size, NULL,
                                 0, NULL, NULL);
    CHECK_CL(err, "clEnqueueNDRangeKernel");

    err = clFinish(queue);
    CHECK_CL(err, "clFinish");

    unsigned int match_count = 0;
    err = clEnqueueReadBuffer(queue, count_buf, CL_TRUE, 0,
                              sizeof(unsigned int), &match_count,
                              0, NULL, NULL);
    CHECK_CL(err, "read count");

    printf("Raw match count reported: %u / %lu\n", match_count, max_matches);

    uint64_t to_read = match_count;
    if (to_read > max_matches) {
        to_read = max_matches;
        printf("WARNING: output buffer overflowed; truncated to %lu matches\n", max_matches);
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
    }

    uint64_t num_deduped = 0;
    uint64_t *matches_deduped = calloc(to_read, sizeof(uint64_t));

    for (uint64_t i = 0; i < to_read; ++i) {
        uint64_t elem = matches[i];
        int seen = 0;

        for (uint64_t j = 0; j < num_deduped; ++j) {
            if (elem == matches_deduped[j]) {
                seen = 1;
                break;
            }
        }

        if (!seen) {
            matches_deduped[num_deduped++] = elem;
        }
    }

    for (uint64_t i = 0; i < num_deduped; ++i) {
        printf("%lu, \n", matches_deduped[i]);
    }

    printf("Raw match count reported: %u / %lu (%f) (%f)\n", match_count, max_matches, ((float)(match_count))/((float)(max_matches)), ((float)(match_count))/((float)(max - min)));

    free(matches);
    free(source);

    clReleaseMemObject(matches_buf);
    clReleaseMemObject(count_buf);
    clReleaseKernel(kernel);
    clReleaseProgram(program);
    clReleaseCommandQueue(queue);
    clReleaseContext(context);

    return 0;
}