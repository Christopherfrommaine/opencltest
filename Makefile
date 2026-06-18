CC = gcc
CFLAGS = -O0 -Wall -Wextra -std=c11 -g
LDFLAGS = -lOpenCL

TARGET = main
SRC = src/main.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)