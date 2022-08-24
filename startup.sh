#!/usr/bin/env bash
[ -d ~/.sibyl/certs ] || mkdir ~/.sibyl/certs
[ -e ~/.sibyl/certs/key.pem ] || openssl genrsa -out ~/.sibyl/certs/key.pem 2048
[ -e ~/.sibyl/certs/cert.pem ] || openssl req -new -x509 -nodes -sha256\
    -days 3650 -subj /CN=localhost -key ~/.sibyl/certs/key.pem -out ~/.sibyl/certs/cert.pem

~/.sibyl/bin/sibyl