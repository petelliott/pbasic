AS=as
ASFLAGS=
LD=ld
LDFLAGS=-Tsrc/platform/$(PLATFORM)/pbasic.ld

PLATFORM=linux
EXECUTABLE=pbasic

OBJS=src/platform/$(PLATFORM)/entry.o

$(EXECUTABLE): $(OBJS)
	$(LD) $(LDFLAGS) $< -o $@

%.o: %.s
	$(AS) $(ASFLAGS) -c $< -o $@

.PHONY: clean

clean:
	find . -name '*.o' | xargs rm -rf
	rm -rf $(EXECUTABLE)
