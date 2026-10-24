# wtf-psp-recomp -- WTF: Work Time Fun, statically recompiled.
#
# Builds the toolkit (allegrexrecomp, which scripts/extract.ps1 needs) and one
# playable executable per game-sharing microgame whose generated C exists.
# The generated C is never committed: scripts/build.ps1 produces it from your
# own decrypted modules into build/gen/.

cmake_minimum_required(VERSION 3.16)
project(wtf_psp_recomp C)

# The submodule by default; point it at a working copy to build against
# toolkit changes that are not released yet.
set(PSPRECOMP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/psprecomp" CACHE PATH "psprecomp source tree")
if(NOT EXISTS ${PSPRECOMP_DIR}/CMakeLists.txt)
    message(FATAL_ERROR
        "psprecomp not found at ${PSPRECOMP_DIR}. Run: git submodule update --init --recursive")
endif()

# WTF waits on semaphores its other threads signal; it needs real threads.
set(PSPRECOMP_REAL_THREADS ON CACHE BOOL "WTF needs real guest threads" FORCE)
add_subdirectory(${PSPRECOMP_DIR} psprecomp)

add_subdirectory(games/wtf)
