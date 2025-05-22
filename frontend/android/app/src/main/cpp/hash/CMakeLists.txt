cmake_minimum_required(VERSION 3.4.1)

# Добавляем исходные файлы
add_library(hash SHARED
            hash.c)

# Подключаем заголовочные файлы
target_include_directories(hash PRIVATE
                         ${CMAKE_CURRENT_SOURCE_DIR}) 