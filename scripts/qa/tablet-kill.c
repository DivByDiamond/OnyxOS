#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <signal.h>
#include <sys/syscalls.h>
int main(void) {
    char *args[65];
    int i;
    for (i = 0; i < 65; i++) args[i] = 0;
    args[0] = "otablet"; args[1] = "--device"; args[2] = 0;
    int child = (int)_onyx_spawn("/bin/otablet", args, 1), status = 0, fd;
    if (child < 0) return 1;
    fd = open("/dev/fb0", O_RDWR);
    if (fd < 0) return 2;
    for (i = 0; i < 1000; i++) {
        if (_onyx_ioctl(fd, 0x46f0, 0) < 0) break;
        _onyx_ioctl(fd, 0x46f1, 0);
        usleep(20000);
    }
    if (i == 1000) return 2;
    if (kill(child, SIGKILL) != 0) return 3;
    _onyx_waitpid(child, &status, 0);
    if (_onyx_ioctl(fd, 0x46f0, 0) < 0) return 4;
    _onyx_ioctl(fd, 0x46f1, 0); close(fd);
    puts("OTABLET_KILL_RECLAIM_OK");
    return 0;
}
