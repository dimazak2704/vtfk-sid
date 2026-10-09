FROM rust:1.79 AS builder

WORKDIR /app

RUN rustup target add x86_64-unknown-linux-musl && \
    apt-get update && \
    apt-get install -y --no-install-recommends musl-tools && \
    rm -rf /var/lib/apt/lists/*

# Dependencies are built separately from application code
COPY Cargo.toml Cargo.lock ./

RUN mkdir -p src && \
    printf 'fn main() {}\n' > src/main.rs && \
    cargo build --release --locked \
      --target x86_64-unknown-linux-musl && \
    rm -rf src

# Changes in source code do not invalidate dependency compilation
COPY src/ ./src/

RUN cargo clean -p sid_capsule \
      --release \
      --target x86_64-unknown-linux-musl && \
    cargo build --release --locked \
      --target x86_64-unknown-linux-musl

FROM scratch

COPY --from=builder \
    /app/target/x86_64-unknown-linux-musl/release/sid_capsule \
    /sid_capsule

ENTRYPOINT ["/sid_capsule"]