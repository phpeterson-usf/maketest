PROGS = lab01
OBJS = replace.o map.o
CC = gcc
CFLAGS = -g -c

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

$(PROGS): $(OBJS)
	$(CC) -o $@ $^
