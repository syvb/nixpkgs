{ buildPythonPackage
, cmake
, fetchPypi
, glfw
, lib
, mujoco
, numpy
, perl
, pkgs
, pybind11
, python
, setuptools
}:

buildPythonPackage rec {
  pname = "mujoco";
  version = "3.0.1";

  pyproject = true;

  # We do not fetch from the repository because the PyPi tarball is
  # impurely build via
  # <https://github.com/google-deepmind/mujoco/blob/main/python/make_sdist.sh>
  # in the project's CI.
  src = fetchPypi {
    inherit pname version;
    hash = "sha256-pftecOk4q19qKBHs9hBBVenI+SgJg9VT7vc6NKuiY0s=";
  };

  nativeBuildInputs = [ cmake setuptools ];
  dontUseCmakeConfigure = true;
  buildInputs = [ mujoco pybind11 ];
  propagatedBuildInputs = [ glfw numpy ];

  pythonImportsCheck = [ "${pname}" ];

  env.MUJOCO_PATH = "${mujoco}";
  env.MUJOCO_PLUGIN_PATH = "${mujoco}/lib";
  env.MUJOCO_CMAKE_ARGS = "-DMUJOCO_SIMULATE_USE_SYSTEM_GLFW=ON";

  preConfigure =
    # Use system packages for pybind
    ''
      ${perl}/bin/perl -0777 -i -pe "s/(findorfetch\(.{3}USE_SYSTEM_PACKAGE.{3})(OFF)(.{3}PACKAGE_NAME.{3}pybind11.*\))/\1ON\3/gms" mujoco/CMakeLists.txt
    '' +
    # Use non-system eigen3, lodepng, abseil: Remove mirror info and prefill
    # dependency directory. $build from setuptools.
    (let
      # E.g. 3.11.2 -> "311"
      pythonVersionMajorMinor = with lib.versions;
        "${major python.pythonVersion}${minor python.pythonVersion}";
    in ''
      ${perl}/bin/perl -0777 -i -pe "s/GIT_REPO\n.*\n.*GIT_TAG\n.*\n//gm" mujoco/CMakeLists.txt
      ${perl}/bin/perl -0777 -i -pe "s/(FetchContent_Declare\(\n.*lodepng\n.*)(GIT_REPO.*\n.*GIT_TAG.*\n)(.*\))/\1\3/gm" mujoco/simulate/CMakeLists.txt

      build="/build/${pname}-${version}/build/temp.linux-x86_64-cpython-${pythonVersionMajorMinor}/"
      mkdir -p $build/_deps
      ln -s ${mujoco.pin.lodepng} $build/_deps/lodepng-src
      ln -s ${mujoco.pin.eigen3} $build/_deps/eigen-src
      ln -s ${mujoco.pin.abseil-cpp} $build/_deps/abseil-cpp-src
    '');

  meta = with lib; {
    description =
      "Python bindings for MuJoCo: a general purpose physics simulator.";
    homepage = "https://mujoco.org/";
    license = licenses.asl20;
    maintainers = with maintainers; [ tmplt ];
  };
}
