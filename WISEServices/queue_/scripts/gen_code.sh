#!/bin/bash

# Change to the parent directory.
cd "$(dirname "$(dirname "$(readlink -fm "$0")")")"

# Generate Thrift code.
cd src
rm -rf $1/gen_queue
mkdir $1/gen_queue
thrift -r --gen $1 -out $1/gen_queue spec.thrift
