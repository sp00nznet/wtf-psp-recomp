# One executable per game-sharing microgame. Each module is its own program
# (all linked at address 0, all with their own psp_func_* symbols), so each
# gets its own exe built from the same host.

set(WTF_DEC_DIR "${PROJECT_SOURCE_DIR}/work/dec" CACHE PATH
    "Decrypted modules, <id>.elf (see the README)")
set(WTF_GEN_DIR "${PROJECT_BINARY_DIR}/gen" CACHE PATH
    "Where scripts/build.ps1 writes the generated C")

# id;title pairs. The id is the module's file name in WTF_DEC_DIR.
set(WTF_GAMES
    "b00_baseball\;Baseball Superstar"
    "b02_lumberjack\;Lumberjack"
    "b04_pendemonium\;Pendemonium"
    "b80_lumberjack_challenge\;Lumberjack Challenge"
    "b81_seance\;Seance")

foreach(entry ${WTF_GAMES})
    list(GET entry 0 id)
    list(GET entry 1 title)
    # CONFIGURE_DEPENDS: generating the C later makes the next build pick it up.
    file(GLOB srcs CONFIGURE_DEPENDS "${WTF_GEN_DIR}/${id}/${id}_*.c")
    if(NOT srcs)
        continue()
    endif()
    add_executable(wtf_${id} host.c ${srcs})
    target_compile_definitions(wtf_${id} PRIVATE
        WTF_TITLE="${title}"
        WTF_ELF="${WTF_DEC_DIR}/${id}.elf")
    target_link_libraries(wtf_${id} PRIVATE psprecomp)
    if(MSVC)
        target_compile_options(wtf_${id} PRIVATE /MP /W1)
    endif()
endforeach()
