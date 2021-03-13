FROM postgres:latest AS builder
RUN mkdir /build
WORKDIR /build
RUN apt-get update && apt-get install -y build-essential postgresql-server-dev-all git
RUN apt-get install -y libssl-dev zlib1g-dev libreadline-dev
RUN git clone https://github.com/segasai/q3c.git
WORKDIR /build/q3c
RUN make
RUN /usr/lib/llvm-7/bin/llvm-lto -thinlto -thinlto-action=thinlink -o q3c.index.bc dump.bc q3c.bc q3c_poly.bc q3cube.bc

FROM postgres:latest
RUN mkdir -p /usr/share/doc/postgresql-doc-13/extension /usr/lib/postgresql/13/lib/bitcode/q3c
COPY --from=builder /build/q3c/q3c.so /usr/lib/postgresql/13/lib/q3c.so
COPY --from=builder /build/q3c/q3c.control /usr/share/postgresql/13/extension/
COPY --from=builder /build/q3c/scripts/*.sql /usr/share/postgresql/13/extension/
COPY --from=builder /build/q3c/README.md /usr/share/doc/postgresql-doc-13/extension/
COPY --from=builder /build/q3c/dump.bc /build/q3c/q3c.bc /build/q3c/q3c_poly.bc /build/q3c/q3cube.bc /usr/lib/postgresql/13/lib/bitcode/q3c/
COPY --from=builder /build/q3c/q3c.index.bc /usr/lib/postgresql/13/lib/bitcode/
COPY create_q3c_extension.sql /docker-entrypoint-initdb.d/
