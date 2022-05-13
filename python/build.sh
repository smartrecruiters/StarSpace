#!/bin/bash

# Configuration

# Boost lib location
BOOST_DIR=/usr/local/Cellar/boost/1.78.0_1

# GoogleTest lib location (optional)
GTEST_DIR=/usr/local/Cellar/googletest/1.11.0

# Name of python virtualenvironment to perform result testing
VENV_NAME=build-starwrap



echo "############################# initial cleanup ############################# "
# cleanup wrapper
rm -r build
rm -r lib
rm -r test/*.so
rm -r test/tmp

echo "#############################  build starspace ############################# "
# build starspace lib
cd ..
make clean
make -f makefile_py BOOST_DIR=$BOOST_DIR GTEST_DIR=$GTEST_DIR
cd -

echo "#############################  build wrapper ############################# "
# build wrapper
mkdir lib
cp ../libstarspace.a ./lib
mkdir build
cd build
conan install ..
cmake .. -DCMAKE_BUILD_TYPE=Release -DBOOST_DIR=$BOOST_DIR -DPYTHON_LIBRARY=$VIRTUAL_ENV/lib/
cmake --build .
cd -

echo "#############################  run test ############################# "
if [ ! -f "./build/starwrap.so" ]; then
  echo "error: '/build/starwrap.so' was not found " >&2
  exit 1
fi

# run test
# this will run all wrapped APIs available at this moment.
# by loading traing data from input.txt, train with train mode 5,
# find nearest neighbor to some random text, save model as binary and tsv,
# try loading both saved models above again and
# generate Document Embedding for some random text.
cp ./build/starwrap.so ./test
cd test

if [ -z "$VIRTUAL_ENV" ]; then
  if [ -z "$VIRTUALENVWRAPPER_SCRIPT" ]; then
    pip install virtualenv

    rm -r build $VENV_NAME
    virtualenv $VENV_NAME
    source $VENV_NAME/bin/activate
  else
    source $VIRTUALENVWRAPPER_SCRIPT
    rmvirtualenv $VENV_NAME
    mkvirtualenv $VENV_NAME
  fi
fi

pip install -r requirements.txt
python test.py
python test_predictTags.py

cd -
