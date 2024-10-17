## Purpose
This simple tool is intended for developers who are using Visual Studio and want to have a quick alternative
to create programs without the need to directly use msbuild on the command line.
Since there is no possibility to simply use msbuild without Visual Studio ```CmdLineCMakeMSBuild``` exists.
The idea is to basically have a C/C++ project built using MSBuild without the need of Visual Studio.

## How does it work?
The tool uses standard installation paths of MSBuild/Visual Studio Tools to get all the binaries, sources
and includes. As a build system it uses ```Ninja``` which is also located in the repository.

## How to use it?
1. Clone the repo
2. Create a folder in the repo representing a CMake project (it has to contain a CMakeLists.txt)
3. Use cmake.exe -P build.cmake <project_name> to generate the build system
4. cd into the ```build_<project_name>``` directory and run ```ninja.exe``` to build your binaryo
