## Purpose
This simple tool is intended for developers who are using Visual Studio and want to have a quick alternative
to create programs without the need to directly use MSBuild tools on the command line.
Since there is no possibility to simply use MSBuild tools without Visual Studio ```CmdLineCMakeMSBuild``` exists.
The idea is to basically have a C/C++ project built using MSBuild tools without the need of Visual Studio.

## How does it work?
The tool uses standard installation paths of MSBuild Tools (which come with Visual Studio) to get all the binaries, sources
and includes. As a build system it uses ```Ninja``` which is also located as a standalone binary in the repository.

## How to use it?
1. Clone the repo
2. Create a folder in the repo representing a CMake project (it has to contain at least a CMakeLists.txt)
   - The created folder has to have the same name as the cmake project
   - e.g the created folder is called myproject then in the according CMakeLists.txt there needs to be a call ```project(myproject)```
3. Use cmake.exe -P build.cmake <project_name> to generate the build system
4. cd into the ```build_<project_name>``` directory and run ```ninja.exe``` to build your binaryo
