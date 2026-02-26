FROM --platform=linux/i386 i386/debian as builder

RUN apt update && apt install -fy gcc make python3 git

RUN mkdir -p /workdir

WORKDIR /workdir

# Clone repos
RUN git clone https://github.com/HewlettPackard/wireless-tools && \
    cd wireless-tools && \
    git checkout v26 && \
    cd .. && \
    git clone https://github.com/threadexio/evilcc

# Build evilcc
RUN cd evilcc && \
    make CFLAGS="-m32" ARCH=i386

# Build iwconfig
RUN cd wireless-tools/wireless_tools && \
    make CFLAGS="-m32" ARCH=i386 && \
    /workdir/evilcc/evilcc \
    --personality-add ADDR_NO_RANDOMIZE \
    --drop-sugid chmod --is-setgid --is-setuid \
    -O2 -W -Wall -Wstrict-prototypes -m32 \
    -o iwconfig iwconfig.c libiw.a --verbose \
    -zexecstack -no-pie -fno-stack-protector +-lm

FROM --platform=linux/i386 i386/debian as production

RUN apt update && apt install -fy gcc make gdb python3 less file vim

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig /sbin/iwconfig

RUN chown root:root /sbin/iwconfig && chmod u+rws,g+rs,o+rx /sbin/iwconfig

RUN useradd -m -s /bin/bash user

RUN mkdir -p /workdir && chown user:user /workdir

WORKDIR /workdir

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig.c /workdir/

USER user