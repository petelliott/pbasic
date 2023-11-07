AS=as
ASFLAGS=
LD=ld
LDFLAGS=-nostdlib --nmagic
STRIP=strip
STRIPFLAGS=-s

PLATFORM=linux
EXECUTABLE=pbasic

OBJS=src/platform/$(PLATFORM)/entry.o

$(EXECUTABLE): $(OBJS)
	$(LD) $(LDFLAGS) $< -o $@
	$(STRIP) $(STRIPFLAGS) $@

%.o: %.s
	$(AS) $(ASFLAGS) -c $< -o $@
	objcopy --remove-section .note.gnu.property $@

.PHONY: clean

clean:
	find . -name '*.o' | xargs rm -rf
	rm -rf $(EXECUTABLE)
