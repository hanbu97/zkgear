#!/bin/bash
set -e

circuit_name=../circuit/main

circom ${circuit_name}.circom --r1cs --wasm --sym --c --output ../build/circuit_c/
