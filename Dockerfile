FROM ghcr.io/tonmoyislam250/megarestbase AS builder

ARG CPU_ARCH="amd64"
ENV HOST_CPU_ARCH=$CPU_ARCH

# MegaSDK
RUN git clone https://github.com/meganz/sdk.git sdk && cd sdk && \
    git checkout v4.2.0 && \
    sh autogen.sh && \
    ./configure --disable-silent-rules --disable-shared --enable-static --without-freeimage && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install

#MegaSDKgo
RUN mkdir -p /usr/local/go/src/ && cd /usr/local/go/src/ && \
    git clone https://github.com/viswanathbalusu/megasdkgo && \
    cd megasdkgo && rm -rf .git && \
    mkdir include && cp -r /go/sdk/include/* include && \
    mkdir .libs && \
    cp /usr/lib/lib*.a .libs/ && \
    cp /usr/lib/lib*.la .libs/ && \
    go tool cgo megasdkgo.go

RUN git clone https://github.com/viswanathbalusu/megasdkrest && cd megasdkrest && \
    go get github.com/urfave/cli/v2 && \
    go build -ldflags "-linkmode external -extldflags '-static' -s -w" . && \
    mkdir -p /go/build/ && mv megasdkrpc ../build/megasdkrest-${HOST_CPU_ARCH}

FROM scratch AS megasdkrest

COPY --from=builder /go/build/ /
