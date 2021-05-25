FROM golang:1-alpine as builder
RUN apk add --update go build-base git mercurial ca-certificates git
ENV GO111MODULE=on
WORKDIR /go/src/github.com/gliderlabs/logspout
RUN git clone --depth=1 --single-branch https://github.com/gliderlabs/logspout.git .
RUN go mod edit -require github.com/dsouzajude/logspout-fluentd@latest
RUN cat modules.go | \
    awk '/^\)/ && !modif { printf("        _ \"github.com/dsouzajude/logspout-fluentd/fluentd\"\n"); modif=1 } {print}' \
    > modules.go
COPY src /go/src/github.com/dsouzajude/logspout-fluentd
RUN echo "replace github.com/dsouzajude/logspout-fluentd => /go/src/github.com/dsouzajude/logspout-fluentd" >> go.mod
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-X main.Version=$1" -o /bin/logspout

FROM alpine
WORKDIR /app
ENV FLUENTD_HOST=localhost
ENV FLUENTD_PORT=24224
COPY --from=builder /bin/logspout /app/
CMD /app/logspout fluentd://$FLUENTD_HOST:$FLUENTD_PORT
