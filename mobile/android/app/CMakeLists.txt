cmake_minimum_required(VERSION 3.22)
project(shiren LANGUAGES CXX)
add_library(shiren SHARED ../../android-core/android_bridge.cpp)
target_compile_features(shiren PRIVATE cxx_std_17)
target_compile_definitions(shiren PRIVATE SHIREN_MAC42=1 SHIREN_MAC_NEXT=1)
target_compile_options(shiren PRIVATE -O3)
target_include_directories(shiren PRIVATE ../../../mac-5.0-redesign/core)
target_link_options(shiren PRIVATE -Wl,-z,max-page-size=16384)

