## Purpose
This simple tool is intended to be used on Windows operating system to be able to build C/C++ projects using ```MSBuild``` without the need of ```Visual Studio```.

## What does CmdLineCMakeMSBuild do?
It uses ```CMake```, ```MSBuild``` and ```Ninja``` to create a C/C++ project without the need of Visual Studio.

## What do you need to use it?
- CMake Version >= 3.30 (https://cmake.org/download/)
- MSBuild Tools (https://aka.ms/vs/17/release/vs_BuildTools.exe)
- Ninja Binary comes directly with the repo

## How does it work?
Using CMake, this program sets MSBuild Tools paths and creates a simple standard project with a ```main.cpp``` and ```CMakeLists.txt``` which represent a project which can be compiled using ```Ninja``` build system.

## How to use it?
1. Clone the repo
2. In the repo run following command ```cmake -create -P build.cmake MyNewMsBuildProject```
   - This command creates 2 folders ```MyNewMSBuildProject``` and ```build_MyNewMSBuildProject```
   - In ```MyNewMSBuildProject``` there is a generated ```main.cpp``` and ```CMakeLists.txt``` ready to use
   - In ```build_MyNewMSBuildProject``` there is ```Ninja``` build system to compile and link the project
      - ```cd``` into ```build_MyNewMSBuildProject``` and run ```.\ninja.exe```
      - Now run ```.\MyNewMSBuildProject.exe``` and enjoy!

## Troubleshooting
If there are any feature wishes or bugs just report them via Issues.
A list of the arguments available of progame can be seen using ```cmake -P build.cmake```.
