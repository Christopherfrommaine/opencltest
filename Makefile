CC = gcc
CFLAGS = -O0 -Wall -Wextra -std=c11 -g

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