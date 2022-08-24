#!/usr/bin/env bash
[ -d ~/.remotelint/certs ] || mkdir ~/.remotelint/certs
[ -e ~/.remotelint/certs/key.pem ] || openssl genrsa -out ~/.remotelint/certs/key.pem 2048
[ -e ~/.remotelint/certs/cert.pem ] || openssl req -new -x509 -nodes -sha256\
    -days 3650 -subj /CN=localhost -key ~/.remotelint/certs/key.pem -out ~/.remotelint/certs/cert.pem

~/.remotelint/bin/remotelint