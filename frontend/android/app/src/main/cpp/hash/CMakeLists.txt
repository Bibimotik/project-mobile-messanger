cmake_minimum_required(VERSION 3.4.1)

add_library(hash SHARED hash.c)

find_library(log-lib log)

target_link_libraries(hash
        android
        ${log-lib}
)

set_target_properties(hash PROPERTIES
        C_STANDARD 11
        C_STANDARD_REQUIRED ON
)