#!/usr/bin/env bash

source starspace.cfg

EXTRA_MAKE_ARGS="BOOST_DIR=$BOOST_DIR GTEST_DIR=$GTEST_DIR"
EXTRA_CMAKE_ARGS="-DBOOST_DIR=$BOOST_DIR"

if [[ "$USE_CONAN_FOR_BOOST" == [Yy]* ]]; then
  BOOST_DIR="<controlled by Conan>"
  GTEST_DIR="<controlled by Conan>"

  EXTRA_MAKE_ARGS=""
  EXTRA_CMAKE_ARGS=""
fi

echo Building starspace python wrapper with following configuration:
echo BOOST_DIR=$BOOST_DIR
echo GTEST_DIR=$GTEST_DIR
echo VENV_NAME=$VENV_NAME
echo Python: $(python --version)



echo "############################# initial cleanup ############################# "
# cleanup wrapper
rm -r build
rm -r lib
rm -r test/*.so
rm -r test/tmp

cd ..
make -f makefile_py clean
cd -



echo "#############################  install dependencies ######################## "
mkdir build
cd build
if [[ "$USE_CONAN_FOR_BOOST" == [Yy]* ]]; then
  conan install --build=missing ..
else
  conan install --build=missing ../conanfile_no_boost.txt
fi
cd -



echo "#############################  build starspace ############################# "
# build starspace lib
cd ..
# An variant if you use custom Boost location and do not use Canon to install the dependency
# make -f makefile_py BOOST_DIR=$BOOST_DIR GTEST_DIR=$GTEST_DIR
make -f makefile_py $EXTRA_MAKE_ARGS
cd -



echo "#############################  build wrapper ############################# "
# build wrapper
mkdir lib
cp ../libstarspace.a ./lib

cd build
# An variant if you use custom Boost location and do not use Canon to install the dependency
# cmake .. -DCMAKE_BUILD_TYPE=Release -DPYTHON_LIBRARY=$VIRTUAL_ENV/lib/ -DBOOST_DIR=$BOOST_DIR
cmake .. -DCMAKE_BUILD_TYPE=Release -DPYTHON_LIBRARY=$VIRTUAL_ENV/lib/ $EXTRA_CMAKE_ARGS
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
python -m pytest -vv
deactivate
cd -
