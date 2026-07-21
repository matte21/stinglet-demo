# ---- build stage ----
FROM gcc:14 AS build
WORKDIR /src
COPY memhog.c .
RUN gcc -O2 -static -o memhog memhog.c

# ---- final stage ----
FROM scratch
COPY --from=build /src/memhog /memhog
ENTRYPOINT ["/memhog"]
