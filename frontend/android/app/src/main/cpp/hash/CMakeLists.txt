cmake_minimum_required(VERSION 3.22.1)

# Create the shared library
add_library(password_hash SHARED hash.c)

# Include header files privately
target_include_directories(password_hash PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR})

# Set compiler flags
target_compile_options(password_hash PRIVATE
    -Wall
    -Wextra
    -O2
)

# Link against libraries
target_link_libraries(password_hash PRIVATE) 