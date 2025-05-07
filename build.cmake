cmake_minimum_required(VERSION 3.30)

function(get_ninja_exe actual_build_dir)
    if(NOT EXISTS ${actual_build_dir}/ninja.exe)
        message("Download Ninja.exe ...")
        set(ninja_zip "${actual_build_dir}/ninja-win.zip")
        set(ninja_exe)
        file(DOWNLOAD "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip" ${ninja_zip})
        execute_process(
          COMMAND ${CMAKE_COMMAND} -E tar xzf "${ninja_zip}"
          WORKING_DIRECTORY "${actual_build_dir}"
        )
        file(REMOVE ${ninja_zip})
    endif()
endfunction()

macro(exit)
    message(STATUS "\nTerminating ...")
    return()
endmacro()

# Deletes all folders which have prefix "build_"
function(clean_all_builds current_dir)
    file(GLOB children RELATIVE ${current_dir} ${current_dir}/*)
    foreach(child ${children})
        if(IS_DIRECTORY ${current_dir}/${child})
            get_filename_component(dir_name ${current_dir}/${child} NAME) # this finds all names of items in the folder
            string(SUBSTRING ${dir_name} 0 6 dir_prefix)
            if(${dir_prefix} STREQUAL "build_")
               message("Deleting ${current_dir}/${child}")
               file(REMOVE_RECURSE ${current_dir}/${child})
            endif()
        endif()
    endforeach()
endfunction()

function(create_project project_name)
    set(work_dir ${CMAKE_CURRENT_LIST_DIR})
    set(to_be_created_project_dir "${CMAKE_CURRENT_LIST_DIR}/${project_name}")
    set(cmake_lists_txt "${CMAKE_CURRENT_LIST_DIR}/${project_name}/CMakeLists.txt")
    set(main_cpp "${CMAKE_CURRENT_LIST_DIR}/${project_name}/main.cpp")

    if(NOT EXISTS ${to_be_created_project_dir})
        message("Trying to create project ...")
        file(MAKE_DIRECTORY ${to_be_created_project_dir})
        file(WRITE ${cmake_lists_txt} "cmake_minimum_required(VERSION 3.30)
project(${project_name})
add_executable(${project_name} main.cpp)")

        file(WRITE ${main_cpp} "#include <iostream>

int main()
\{
    std::cout << \"Hello CMake!\" << std::endl;
    return 0;
\}
")
    else()
        message("Skipping project creation because project already exists.")
    endif()

endfunction()

function(print_projects)
    message(STATUS "\nFound Projects ... ")
    foreach(proj IN LISTS ARGN)
        message(STATUS "${proj}")
    endforeach()
endfunction()

# Recursively traverse actual folder and check for every Root CMakeLists.txt
# if found, add to project list. That way we can give appropriate usage information
function(find_cmake_lists current_dir all_projects)
    file(GLOB children RELATIVE ${current_dir} ${current_dir}/*)
    foreach(child ${children})
        if(IS_DIRECTORY ${current_dir}/${child})
            if(EXISTS "${current_dir}/${child}/CMakeLists.txt")
                #message(STATUS "Found CMakeLists.txt in ${current_dir}/${child}")
                list(APPEND child_list_internal ${child})
            endif()
            find_cmake_lists(${current_dir}/${child} child_list)
        endif()
    endforeach()
    set(all_projects ${child_list_internal} PARENT_SCOPE)
endfunction()

set(all_projects "")

function(parse_args shall_create_project project_name)
    foreach(i RANGE 0 ${CMAKE_ARGC})
        string(TOLOWER "${CMAKE_ARGV${i}}" argument)

        # check projectname
        if(record_projectname)
            set(project_name ${CMAKE_ARGV${i}} PARENT_SCOPE)
            # check argument after project_name, because there should be none!
            #MATH(EXPR j "${i}+1")
            #string(TOLOWER "${CMAKE_ARGV${j}}" arg_too_much)
            #if(DEFINED arg_too_much)
            #    message("argument after project_name!")
            #endif()
            break()
        endif()

        # check if create flag provided
        string(REGEX MATCH "^-create$" found "${argument}")
        if(found)
            set(shall_create_project TRUE PARENT_SCOPE) 
            message("Provided -create flag.")
            continue()
        endif()
        
        string(REGEX MATCH "^-cleanbuilds$" found "${argument}")
        if(found)
            set(clean_builds TRUE PARENT_SCOPE) 
            message("Provided -cleanBuilds flag.")
            continue()
        endif()

        # if we find build.cmake, next iteration we want to check projectname
        string(REGEX MATCH "^build.cmake$" found "${argument}")
        if(found)
            set(record_projectname TRUE)
        endif()
    endforeach()
endfunction()

set(shall_create_project FALSE)
parse_args(shall_create_project project_name)

if(${CMAKE_ARGC} LESS 4)
    message(STATUS "\nUsage: cmake <Optional Arguments> -P build.cmake <projectname>")
    message(STATUS "Optional Arguments:")
    message(STATUS "\t-DMSVC_VERSION=\"<version>\"")
    message(STATUS "\t-DWIN_SDK_VERSION=\"<version>\"")
    message(STATUS "\t-create")
    message(STATUS "\t-cleanbuilds")
    message(STATUS "Projectname: Name of a directory containing a CMakeLists.txt in the directory where build.cmake is contained")
    find_cmake_lists(${CMAKE_SOURCE_DIR} all_projects)
    print_projects(${all_projects})
    exit()
endif()

if(clean_builds)
    clean_all_builds(${CMAKE_SOURCE_DIR})
    message("Cleaning finished.")
    if(NOT DEFINED project_name)
        exit()
    endif()
endif()

if(NOT DEFINED project_name)
    message(FATAL_ERROR "No Project Name provided!")
    print_projects(${all_projects})
    exit()
endif()

if(shall_create_project)
    create_project(${project_name})
endif()

find_cmake_lists(${CMAKE_SOURCE_DIR} all_projects)
message("\nYou are about to generate \"${project_name}\"")

# Find MSVC versions
function(find_msvc_versions result path_to_vcvarsall)

    #case 1: Visual Studio is installed on the target machine
    file(GLOB MSVC_VERSIONS "C:/Program Files (x86)/Microsoft Visual Studio/*/Professional/VC/Tools/MSVC/*")
    set(version_list "")
    foreach(MSVC_VERSION_VERSION_PATH IN LISTS MSVC_VERSIONS)
        string(REGEX REPLACE "(VC/).*" "\\1" vc_dir_path "${MSVC_VERSION_VERSION_PATH}")
        get_filename_component(version_number ${MSVC_VERSION_VERSION_PATH} NAME)
        list(APPEND version_list ${version_number})
    endforeach()

    # Enter case 2
    if(NOT version_list)
        message("No Visual Studio Installation found on machine.")
        #case 2: Only Build Tools are installed e.g C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools
        file(GLOB MSVC_VERSIONS "C:/Program Files (x86)/Microsoft Visual Studio/*/BuildTools/VC/Tools/MSVC/*")
        foreach(MSVC_VERSION_VERSION_PATH IN LISTS MSVC_VERSIONS)
            string(REGEX REPLACE "(VC/).*" "\\1" vc_dir_path "${MSVC_VERSION_VERSION_PATH}")
            get_filename_component(version_number ${MSVC_VERSION_VERSION_PATH} NAME)
            list(APPEND version_list ${version_number})
        endforeach()
        if(NOT version_list OR version_list STREQUAL "NOTFOUND")
            message("No MsBuild Tools installed")
        endif()
    endif()
    set(${result} ${version_list} PARENT_SCOPE)
    set(${path_to_vcvarsall} "${vc_dir_path}" PARENT_SCOPE)
endfunction()

find_msvc_versions(msvc_versions path_to_vcdir)

# No MSVC on machine found
if(NOT msvc_versions)
    message(FATAL_ERROR "No MSVC installed on machine.")
    exit()
endif()

# Check MSVC Version provided via command line
if(NOT DEFINED MSVC_VERSION)
    # No defined MSVC Version means we are about to use the newest one found on the machine
    message(STATUS "\nNo custom MSVC_VERSION was passed via command line. Using newest MSVC_VERSION from machine.\nFollowing MSVC Versions were found.")
        foreach(version IN LISTS msvc_versions)
            message(STATUS "MSVC Version: ${version}")
        endforeach()
    list(LENGTH msvc_versions msvc_version_list_length)
    math(EXPR last_index "${msvc_version_list_length} - 1")
    list(GET msvc_versions ${last_index} newest_version)
    set(MSVC_VERSION ${newest_version})
    message(STATUS "Using MSVC Version: ${MSVC_VERSION}")
else()
    #check if provided MSVC version is actually found on machine
    list(FIND msvc_versions ${MSVC_VERSION} index)
    if(index EQUAL -1)
        foreach(version IN LISTS msvc_versions)
            message(STATUS "MSVC Version: ${version}")
        endforeach()
        message(FATAL_ERROR "Provided MSVC Version not valid.\nProvide exactly one version from above with -DMSVC_VERSION=\"<version>\"")
    else()
        message(STATUS "Using MSVC Version ${MSVC_VERSION}")
    endif()
endif()

# Find all Windows SDK Versions
function(get_windows_sdk_versions result)
    file(GLOB WINDOWS_SDK_VERSIONS "C:/Program Files (x86)/Windows Kits/10/Include/*")
    set(version_list "")
    foreach(SDK_VERSION IN LISTS WINDOWS_SDK_VERSIONS)
        get_filename_component(version_number ${SDK_VERSION} NAME)
        list(APPEND version_list ${version_number})
    endforeach()
    set(${result} ${version_list} PARENT_SCOPE)
endfunction()
get_windows_sdk_versions(sdk_versions)

# No Windows SDK on machine found
if(NOT sdk_versions)
    message(FATAL_ERROR "No Windows SDK installed on machine.")
    exit()
endif()

# Check Windows SDK Version provided via command line
if(NOT DEFINED WIN_SDK_VERSION)
    message(STATUS "\nNo custom WIN_SDK_VERSION was passed via command line. Using newest WIN_SDK_VERSION from machine.\nFollowing Windows SDK Versions were found.")
        foreach(version IN LISTS sdk_versions)
            message(STATUS "Windows SDK version: ${version}")
        endforeach()
    
    list(LENGTH sdk_versions sdk_version_list_length)
    math(EXPR last_index "${sdk_version_list_length} - 1")
    list(GET sdk_versions ${last_index} newest_version)
    set(WIN_SDK_VERSION ${newest_version})
    message(STATUS "Using Windows SDK Version ${WIN_SDK_VERSION}")
else()
    list(FIND sdk_versions ${WIN_SDK_VERSION} index)
    if(index EQUAL -1)
        foreach(version IN LISTS sdk_versions)
            message(STATUS "Windows SDK version: ${version}")
        endforeach()
        message(FATAL_ERROR "Provided SDK Version not valid.\nProvide exactly one version from above with -DWIN_SDK_VERSION=\"<version>\"")
    else()
        message(STATUS "Using Windows SDK Version ${WIN_SDK_VERSION}")
    endif()
endif()

if(NOT ${project_name} IN_LIST all_projects)
    message(STATUS "\nProvided project \"${project_name}\" is not valid. Provide a valid project!")
    print_projects(${all_projects})
    exit()
endif()

# In this file we use a CMAKE_BINARY_DIR which is temporary, we need it to be an absolute path
set(tmp_dir "./.tmp")
set(CMAKE_BINARY_DIR "${tmp_dir}/build")
get_filename_component(CMAKE_BINARY_DIR "${CMAKE_BINARY_DIR}" ABSOLUTE)
get_filename_component(tmp_dir "${tmp_dir}" ABSOLUTE)

# Define a file path used to save the environment variables in
set(ENVIRONMENT_OUTPUT_FILE "${CMAKE_BINARY_DIR}/environment_output.txt")

# Architecture specification
set(ARCH "x64")

# Path to vcvarsall
set(VCVARSALL "${path_to_vcdir}Auxiliary/Build/vcvarsall.bat")
set(MSBUILD_INCLUDES "${path_to_vcdir}Tools/MSVC/${MSVC_VERSION}/include")

# Generate a .bat script which sets up msbuild environment and saves all environment variables afterwards in file
file(WRITE ${CMAKE_BINARY_DIR}/output_environment.bat 
"
call \"${VCVARSALL}\" ${ARCH}
set > ${ENVIRONMENT_OUTPUT_FILE}
")

# Run generated script
execute_process(
    COMMAND cmd /c ${CMAKE_BINARY_DIR}/output_environment.bat
)

# Parse vcvars.txt and create environment variables in this session
file(STRINGS ${ENVIRONMENT_OUTPUT_FILE} VCVARS)
foreach(line ${VCVARS})
    if(line MATCHES "^([a-zA-Z0-9_-]+)=(.*)$")
        string(REPLACE ";" "\\;" value "${CMAKE_MATCH_2}")
        set(ENV{${CMAKE_MATCH_1}} ${value})
    endif()
endforeach()

set(actual_build_dir ${CMAKE_CURRENT_SOURCE_DIR}/build_${project_name})

# Download ninja.exe into the according binary directory
get_ninja_exe(${actual_build_dir})

# Run the specified build
execute_process(
    COMMAND ${CMAKE_COMMAND} 
    "-B ${actual_build_dir}" 
    "-H ${CMAKE_CURRENT_SOURCE_DIR}/${project_name}" 
    "--fresh" 
    "-DCMAKE_MAKE_PROGRAM=${actual_build_dir}/ninja.exe"
    "-DCMAKE_C_FLAGS=/Zi /DWIN32 /D_WINDOWS /EHsc -I\"${MSBUILD_INCLUDES}\" -I\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Include/${WIN_SDK_VERSION}/ucrt\""
    "-DCMAKE_CXX_FLAGS=/Zi /DWIN32 /D_WINDOWS /EHsc -I\"${MSBUILD_INCLUDES}\" -I\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Include/${WIN_SDK_VERSION}/ucrt\""
    "-DCMAKE_CXX_FLAGS_DEBUG=/Zi /Ob0 /Od /RTC1 -I\"${MSBUILD_INCLUDES}\" -I\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Include/${WIN_SDK_VERSION}/ucrt\""
    "-DCMAKE_CXX_FLAGS_RELEASE=/Zi /O2 /Ob2 /DNDEBUG -I\"${MSBUILD_INCLUDES}\" -I\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Include/${WIN_SDK_VERSION}/ucrt\""
    "-DCMAKE_EXE_LINKER_FLAGS=/machine:x64 /LIBPATH:\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Lib/${WIN_SDK_VERSION}/um/x64\" /LIBPATH:\"${path_to_vcdir}Tools/MSVC/${MSVC_VERSION}/lib/x64\" /LIBPATH:\"C:/Program\ Files\ (x86)/Windows\ Kits/10/Lib/${WIN_SDK_VERSION}/ucrt/x64\""
    "-G Ninja"
    RESULT_VARIABLE result
)

if(result)
    message(FATAL_ERROR "Could not generate Ninja build!")
endif()
file(REMOVE_RECURSE ${tmp_dir})