FROM ekidd/rust-musl-builder as builder

WORKDIR /home/rust

COPY ./src ./src
COPY ./Cargo.toml ./Cargo.toml

RUN cargo build --release

#--------------------------------------------------#

FROM debian:stable-slim

RUN mkdir /root/.sibyl
COPY ./workbench /root/.sibyl/workbench
WORKDIR /root/.sibyl/workbench

# Clang
## Linter / Clang-Tidy
## Formatter / Clang Format
RUN apt-get update
RUN apt-get install -y clang-tidy clang-format

# Elixir
## Linter / credo
## Formatter / Default
RUN apt-get install -y curl gnupg
RUN curl -LO https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
RUN dpkg -i erlang-solutions_2.0_all.deb && rm erlang-solutions_2.0_all.deb
RUN apt-get update
RUN apt-get -y install esl-erlang elixir
RUN mix local.hex --force
RUN mix deps.get

# Go
## Linter / staticcheck
## Formatter / Default (gofmt)
RUN curl -LO https://go.dev/dl/go1.18.4.linux-amd64.tar.gz
RUN tar --no-same-owner -xzf go1.18.4.linux-amd64.tar.gz -C /usr/local && rm go1.18.4.linux-amd64.tar.gz
ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin/
RUN go install honnef.co/go/tools/cmd/staticcheck@latest

#HTML
## Linter / htmlhint
## Formatter / prettier
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs
RUN npm install --location=global htmlhint
RUN npm install --location=global prettier

# CSS
## Linter / Stylelint
## Formatter / prettier
RUN npm install --location=global stylelint stylelint-config-standard

# JSON
## Linter / JSONLint
## Formatter / prettier
RUN npm install --location=global jsonlint

# JavaScript
## Linter / ESLint
## Formatter / ESLint
RUN npm install --location=global eslint

# Markdown
## Linter / Remark
## Formatter / Remark
RUN npm install --location=global remark-cli remark-preset-lint-consistent remark-preset-lint-recommended remark-lint-list-item-indent remark-lint-emphasis-marker remark-lint-strong-marker

# PHP
## Linter / PHP_CodeSniffer
## Formatter / PHP Code Beautifier and Fixer
RUN apt-get install -y php php-xml
RUN curl -Lo /usr/local/bin/phpcs https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar
RUN curl -Lo /usr/local/bin/phpcbf https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar
RUN chmod +x /usr/local/bin/phpcs
RUN chmod +x /usr/local/bin/phpcbf

# Python
## Linter / Flake8
## Formatter / autopep8
RUN apt-get install -y python3 python3-pip
RUN python3 -m pip install flake8 autopep8

# Ruby
## Linter / RuboCop
## Formatter / RuboCop
RUN apt-get install -y git autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev
RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv
RUN git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build
ENV PATH=$PATH:/root/.rbenv/bin:/root/.rbenv/shims
RUN echo "PATH=$PATH" >> /root/.bash_profile
RUN echo 'eval "$(rbenv init - bash)"' >> /root/.bashrc
RUN rbenv install 3.1.2
RUN rbenv global 3.1.2
RUN gem install rubocop

# Rust
## Linter / Clippy
## Formatter / rustfmt
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH=$PATH:/root/.cargo/bin

# SQL
## Linter / SQLFluff
RUN pip install sqlfluff

RUN mkdir /root/.sibyl/bin
COPY --from=builder \
    /home/rust/target/x86_64-unknown-linux-musl/release/sibyl \
    /root/.sibyl/bin/sibyl
RUN chmod +x /root/.sibyl/bin/sibyl
COPY ./tools.json /root/.sibyl/tools.json

COPY ./startup.sh /startup.sh
RUN chmod +x /startup.sh

EXPOSE 3000
CMD ["/startup.sh"]