#!/bin/bash
set -e

circuit_name=$1
CUR_DIR=$(cd $(dirname $0);pwd)
base_dir=${CUR_DIR}/${circuit_name}_js
export NODE_OPTIONS=--max_old_space_size=4096
# snarkjs=${CUR_DIR}/../node_modules/.bin/snarkjs
snarkjs=snarkjs

circom ${circuit_name}.circom --r1cs --wasm --sym

mv ${circuit_name}.r1cs ${circuit_name}.sym  $base_dir
cd $base_dir
node ../../scripts/generate_mixer.js
POWER=15

#Prapare phase 1
node generate_witness.js ${circuit_name}.wasm input.json witness.wtns

if [ ! -f "${CUR_DIR}/circuit_final.zkey" ]; then
    $snarkjs powersoftau new bn128 ${POWER} pot${POWER}_0000.ptau -v
    $snarkjs powersoftau contribute pot${POWER}_0000.ptau pot${POWER}_0001.ptau --name="First contribution" -v

    #Prapare phase 2
    $snarkjs powersoftau prepare phase2 pot${POWER}_0001.ptau $CUR_DIR/powersOfTau28_hez_final_${POWER}.ptau -v
    $snarkjs groth16 setup ${circuit_name}.r1cs $CUR_DIR/powersOfTau28_hez_final_${POWER}.ptau ${CUR_DIR}/circuit_final.zkey
fi

#Start a new zkey and make a contribution (enter some random text)
$snarkjs zkey export verificationkey ${CUR_DIR}/circuit_final.zkey verification_key.json
$snarkjs groth16 prove ${CUR_DIR}/circuit_final.zkey witness.wtns proof.json public.json
$snarkjs groth16 verify verification_key.json public.json proof.json
$snarkjs zkey export soliditycalldata public.json proof.json
cd ..
$snarkjs zkey export solidityverifier ${CUR_DIR}/circuit_final.zkey ../contracts/verifier.sol
