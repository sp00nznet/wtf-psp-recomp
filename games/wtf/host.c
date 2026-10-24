/* WTF: Work Time Fun -- host for one game-sharing microgame.
 *
 * Loads the decrypted module, opens a window that shows the game and reads the
 * keyboard and a controller, and runs module_start. The game's own threads do
 * the rest; this thread just keeps the scheduler turning until the window is
 * closed.
 *
 *   wtf_<id>.exe [path\to\<id>.elf]
 *
 * Controls are listed in psprecomp/window.h: arrows, Z = Cross, X = Circle,
 * A = Square, S = Triangle, Q/W = L/R, Enter = Start, Backspace = Select, or
 * an Xbox-style controller. */

#include <psprecomp/cpu.h>
#include <psprecomp/mem.h>
#include <psprecomp/hle.h>
#include <psprecomp/module.h>
#include <psprecomp/window.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void psp_recomp_register(void);   /* in the generated <id>_register.c */

/* .text, .data, .bss, and what a module linked at 0 expects above them. */
#define MODULE_SPAN 0x03000000u

int main(int argc, char **argv) {
    const char *elf = argc > 1 ? argv[1] : WTF_ELF;

    if (psp_mem_init() != 0) { fprintf(stderr, "memory init failed\n"); return 1; }
    psp_module m;
    if (psp_module_load(elf, MODULE_SPAN, &m) != 0) {
        fprintf(stderr, "usage: %s [decrypted module .elf]\n", argv[0]);
        return 1;
    }
    psp_cpu_reset();
    psp_hle_init();

    /* Files the game opens resolve beside its module. */
    static char root[1024];
    snprintf(root, sizeof root, "%s", elf);
    char *slash = strrchr(root, '/'), *bslash = strrchr(root, '\\');
    if (bslash > slash) slash = bslash;
    if (slash) *slash = '\0'; else strcpy(root, ".");
    psp_io_set_root(root);

    psp_recomp_register();

    if (psp_window_start("WTF: " WTF_TITLE, 0) != 0) {
        fprintf(stderr, "could not open a window\n");
        return 1;
    }
    printf("WTF: %s -- module 0x%08X, entry 0x%08X, gp 0x%08X, %d constructors\n",
           WTF_TITLE, m.base, m.entry, m.gp, m.nctors);

    psp_module_start(&m);
    while (!psp_window_closed())
        psp_threadman_yield();
    /* The game's threads are still running; leave without unwinding them. */
    fflush(stdout);
    _Exit(0);
}
