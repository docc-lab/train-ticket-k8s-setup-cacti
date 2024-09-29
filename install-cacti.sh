#!/bin/bash

set -x

cd $HOME

source .bashrc
source .profile

cd /local

cargo update --manifest-path /local/pythia/Cargo.toml -p lexical-core
cargo update --manifest-path /local/pythia/pythia_server/Cargo.toml -p lexical-core
cargo install --locked --path /local/pythia
cargo install --locked --path /local/pythia/pythia_server