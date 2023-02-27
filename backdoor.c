#include <unistd.h>
int main(int argc, char **argv)
{
    setuid(0);

    char* progname = "/bin/bash";
    argv[0] = progname;
    execve(progname, argv, NULL);
}