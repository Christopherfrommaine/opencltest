CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c11
LDFLAGS = -lOpenCL

TARGET = main
SRC = src/main.c

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC) $(LDFLAGS)

clean:
	rm -f $(TARGET)