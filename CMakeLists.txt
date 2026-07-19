# wtf-psp-recomp — WTF: Work Time Fun, statically recompiled.
#
# Today this builds the toolkit, which is what scripts/extract.ps1 needs. The
# per-game host (games/wtf/) arrives with the emitter in psprecomp phase 3 —
# there is no point scaffolding a host before there is recompiled C to run in
# it.

cmake_minimum_required(VERSION 3.16)
project(wtf_psp_recomp C)

if(NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/psprecomp/CMakeLists.txt)
    message(FATAL_ERROR
        "psprecomp submodule missing. Run: git submodule update --init --recursive")
endif()

add_subdirectory(psprecomp)
