# Sibyl

Docker image that includes API server to use linter and formatter with keeping the environment.

[Docker Hub Repository](https://hub.docker.com/repository/docker/mdev672/sibyl)

This project may have unknown security risks. Please do not expose to Internet.

## How to use

```
git clone https://github.com/m-dev672/sibyl.git
cd sibyl
docker compose up -d

curl --silent --insecure https://localhost:3000/linter/clang-tidy -F file=@./test/linter/test.c
```