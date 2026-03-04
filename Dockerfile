FROM --platform=linux/i386 i386/debian as builder

RUN apt update && apt install -fy gcc make python3 git python3-pip sudo strace

RUN mkdir -p /workdir

WORKDIR /workdir

# Clone repos
RUN git clone https://github.com/HewlettPackard/wireless-tools && \
    cd wireless-tools && \
    git checkout v26 && \
    sed -i '1s/^/#define _GNU_SOURCE\n#include <assert.h>\n#include <unistd.h>\n/' wireless_tools/iwconfig.c && \
    sed -i 's/int skfd;/setresuid(0, 0, 0); int skfd;/g' wireless_tools/iwconfig.c

# Build iwconfig
RUN cd wireless-tools/wireless_tools && \
    make CFLAGS="-m32 -zexecstack -no-pie -fno-stack-protector" ARCH=i386

FROM --platform=linux/i386 i386/debian as production

RUN apt update && apt install -fy gcc make gdb python3 less file vim gosu checksec strace

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig /sbin/iwconfig

RUN chown root:root /sbin/iwconfig && chmod u+rws,g+rs,o+rx /sbin/iwconfig

RUN useradd -m -s /bin/bash user

RUN mkdir -p /workdir && chown user:user /workdir

WORKDIR /workdir

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig.c /workdir/

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "iwconfig" ]
