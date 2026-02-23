#!/usr/bin/bash

OUTPUT=$(pwd)/_build/default/examples/output/basis/hamlet/basis
TEST_DIR=$(pwd)/../personal

DIR=basis/hamlet dune build --no-buffer @usetest     

SAVE_DIR=$(pwd)
mkdir "$TEST_DIR" || echo "Failed to create directory $TEST_DIR"
cd "$TEST_DIR" || echo "Failed to change directory to $TEST_DIR"
cp -a "$OUTPUT/." "$TEST_DIR"
mv "$TEST_DIR/dune_project" "$TEST_DIR/dune-project" || echo "Failed to rename dune_project to dune-project"
cat << END 
    Build and run succesful

    Now attempting to build the basis
END

timeout 20 dune build
cd "$SAVE_DIR" || echo "Failed to change back to original directory"
