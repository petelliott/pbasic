AS=as
ASFLAGS=-Isrc/
LD=ld
LDFLAGS=-Tsrc/platform/$(PLATFORM)/pbasic.ld

PLATFORM=linux
EXECUTABLE=pbasic

OBJS=src/platform/$(PLATFORM)/entry.o src/platform/$(PLATFORM)/filehdr.o \
	 src/platform/$(PLATFORM)/platform.o src/std.o src/repl.o src/words.o \
	 src/statements.o

$(EXECUTABLE): $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

debug: ASFLAGS=-g
debug: LDFLAGS=
debug: $(EXECUTABLE)

%.o: %.s
	$(AS) $(ASFLAGS) -c $^ -o $@

.PHONY: clean debug

clean:
	find . -name '*.o' | xargs rm -rf
	rm -rf $(EXECUTABLE)
