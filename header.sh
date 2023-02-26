#!/bin/bash
# fakemurk.sh v1
# by coolelectronics with help from r58

# sets up all required scripts for spoofing os verification in devmode
# this script bundles crossystem.sh and vpd.sh

# crossystem.sh v3.0.0
# made by r58Playz and stackoverflow
# emulates crossystem but with static values to trick chromeos and google
# version history:
# v3.0.0 - implemented mutable crossystem values
# v2.0.0 - implemented all functionality
# v1.1.1 - hotfix for stupid crossystem
# v1.1.0 - implemented <var>?<value> functionality (searches for value in var)
# v1.0.0 - basic functionality implemented
ascii_info() {
    cat <<-EOF
 ________ ________  ___  __    _______   _____ ______   ___  ___  ________  ___  __
|\\  _____\\\\   __  \\|\\  \\|\\  \\ |\\  ___ \\ |\\   _ \\  _   \\|\\  \\|\\  \\|\\   __  \\|\\  \\|\\  \\
\\ \\  \\__/\\ \\  \\|\\  \\ \\  \\/  /|\\ \\   __/|\\ \\  \\\\\\__\\ \\  \\ \\  \\\\\\  \\ \\  \\|\\  \\ \\  \\/  /|_
 \\ \\   __\\\\ \\   __  \\ \\   ___  \\ \\  \\_|/_\\ \\  \\\\|__| \\  \\ \\  \\\\\\  \\ \\   _  _\\ \\   ___  \\
  \\ \\  \\_| \\ \\  \\ \\  \\ \\  \\\\ \\  \\ \\  \\_|\\ \\ \\  \\    \\ \\  \\ \\  \\\\\\  \\ \\  \\\\  \\\\ \\  \\\\ \\  \\
   \\ \\__\\   \\ \\__\\ \\__\\ \\__\\\\ \\__\\ \\_______\\ \\__\\    \\ \\__\\ \\_______\\ \\__\\\\ _\\\\ \\__\\\\ \\__\\
    \\|__|    \\|__|\\|__|\\|__| \\|__|\\|_______|\\|__|     \\|__|\\|_______|\\|__|\\|__|\\|__| \\|__|

THIS IS FREE SOFTWARE! if you paid for this, you have been scammed and should demand your money back

fakemurk - a tool made by coolelectronics and r58playz to spoof verified boot while enrolled
you can find this script, its explanation, and documentation here: https://github.com/MercuryWorkshop/fakemurk
EOF

    # spaces get mangled by makefile, so this must be separate
}
nullify_bin() {
    cat <<-EOF >$1
#!/bin/bash
exit
EOF
    chmod 777 $1
    # shebangs crash makefile
}
