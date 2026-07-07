CC = gcc
CFLAGS = -O3 -Wall -Wextra -std=c11 -g
# CFLAGS += -I$(HOME)/gpu/OpenCL/OpenCLHeaders -L/orcd/software/core/001/pkg/cuda/13.0.1/targets/x86_64-linux/lib/

TARGET = main
SRC = src/main.c

UNAME_S := $(shell uname -s 2>/dev/null)

ifeq ($(UNAME_S),Darwin)
	# macOS uses the OpenCL framework
	CFLAGS += -DCL_SILENCE_DEPRECATION
	LDFLAGS = -framework OpenCL
	EXE =
	RM = rm -f
else ifeq ($(OS),Windows_NT)
	# Windows with MinGW/MSYS2
	LDFLAGS = -lOpenCL
	EXE = .exe
	RM = del /Q
else
	# Linux
	LDFLAGS = -lOpenCL
	EXE =
	RM = rm -f
endif

OUT = $(TARGET)$(EXE)

all: $(OUT)

$(OUT): $(SRC)
	$(CC) $(CFLAGS) -o $(OUT) $(SRC) $(LDFLAGS)

clean:
	-$(RM) $(OUT)