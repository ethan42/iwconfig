FROM --platform=linux/i386 i386/debian as builder

RUN apt update && apt install -fy gcc make python3 git

RUN mkdir -p /workdir

WORKDIR /workdir

# Clone repos
RUN git clone https://github.com/HewlettPackard/wireless-tools && \
    cd wireless-tools && \
    git checkout v26

# Build iwconfig
RUN cd wireless-tools/wireless_tools && \
    make CFLAGS="-m32" ARCH=i386

FROM --platform=linux/i386 i386/debian as production

RUN apt update && apt install -fy gcc make gdb python3 less file vim

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig /sbin/iwconfig

RUN chown root:root /sbin/iwconfig && chmod u+rws,g+rs,o+rx /sbin/iwconfig

RUN useradd -m -s /bin/bash user

RUN mkdir -p /workdir && chown user:user /workdir

WORKDIR /workdir

COPY --from=builder /workdir/wireless-tools/wireless_tools/iwconfig.c /workdir/

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "iwconfig" ]
