cmake_minimum_required(VERSION 3.22.1)

project(hash)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Add source directory
add_subdirectory(src/main/cpp/hash)

# Create JNI library
add_library(native-lib SHARED
    src/main/cpp/native-lib.cpp)

# Include headers
target_include_directories(native-lib PRIVATE
    src/main/cpp/hash)

# Link with our hash library
target_link_libraries(native-lib
    password_hash)

# Link with Android log library for debug output
target_link_libraries(native-lib
    android
    log) 