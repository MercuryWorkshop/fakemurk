#!/bin/bash
# crossystem.sh v2.0.0
# made by r58Playz and stackoverflow
# emulates crossystem but with static values to trick brunch into thinking it is a valid chromebook with a valid everything
# version history:
# v2.0.0 - implemented all functionality
# v1.1.1 - hotfix for stupid crossystem
# v1.1.0 - implemented <var>?<value> functionality (searches for value in var)
# v1.0.0 - basic functionality implemented


# IF YOU WANT TO CHANGE VALUES PLEASE CHANGE THEM IN BOTH COPIES OF CROSSYSTEM VALUES!

################################################
# PASTE (FORMATTED) OUTPUT OF crossystem HERE! #
################################################
# Remove comments, put any text & hex in quotes, remove spaces
arch="x86"
backup_nvram_request=1
battery_cutoff_request=0
block_devmode=0
clear_tpm_owner_done=1
clear_tpm_owner_request=0
cros_debug=0
dbg_reset=0
debug_build=0
dev_boot_legacy=0
dev_boot_signed_only=0
dev_boot_usb=0
dev_default_boot="disk"
dev_enable_udc=0
devsw_boot=0
devsw_cur=0
disable_alt_os_request=0
disable_dev_request=0
ecfw_act="RO"
enable_alt_os_request=0
post_ec_sync_delay=0
alt_os_enabled=0
fmap_base="0xff285000"
fw_prev_result="unknown"
fw_prev_tried="A"
fw_result="unknown"
fw_tried="A"
fw_try_count=0
fw_try_next="A"
fw_vboot2=1
fwb_tries=0
fwid="Google_Fleex.11297.204.0"
fwupdate_tries=0
hwid="GRABBITER G7B-B4E-N5A-K44-E6S-A94-A7T"
inside_vm=0
kern_nv="0x0000"
kernel_max_rollforward="0xfffffffe"
kernkey_vfy="sig"
loc_idx=0
mainfw_act="A"
mainfw_type="normal"
nvram_cleared=0
oprom_needed=0
phase_enforcement="(error)"
recovery_reason=0
recovery_request=0
recovery_subcode=0
recoverysw_boot=0
recoverysw_cur="(error)"
recoverysw_ec_boot=0
recoverysw_is_virtual=1
ro_fwid="Google_Fleex.11297.204.0"
tpm_attack=0
tpm_fwver="0x00010001"
tpm_kernver="0x00010001"
tpm_rebooted=0
tried_fwb=0
try_ro_sync=0
vdat_flags="0x0003cc76"
vdat_timers="LFS=0,0 LF=0,0 LK=0,414548"
wipeout_request=0
wpsw_boot=1
wpsw_cur=1

#########################################
# PASTE OUTPUT OF crossystem HERE! TOO! #
#########################################
read -r -d '' cwossystem << EOM
arch                    = x86                            # [RO/str] Platform architecture
backup_nvram_request    = 1                              # [RW/int] Backup the nvram somewhere at the next boot. Cleared on success.
battery_cutoff_request  = 0                              # [RW/int] Cut off battery and shutdown on next boot
block_devmode           = 0                              # [RW/int] Block all use of developer mode
clear_tpm_owner_done    = 1                              # [RW/int] Clear TPM owner done
clear_tpm_owner_request = 0                              # [RW/int] Clear TPM owner on next boot
cros_debug              = 0                              # [RO/int] OS should allow debug features
dbg_reset               = 0                              # [RW/int] Debug reset mode request
debug_build             = 0                              # [RO/int] OS image built for debug features
dev_boot_legacy         = 0                              # [RW/int] Enable developer mode boot Legacy OSes
dev_boot_signed_only    = 0                              # [RW/int] Enable developer mode boot only from official kernels
dev_boot_usb            = 0                              # [RW/int] Enable developer mode boot from USB/SD
dev_default_boot        = disk                           # [RW/str] Default boot from disk, legacy or usb
dev_enable_udc          = 0                              # [RW/int] Enable USB Device Controller
devsw_boot              = 0                              # [RO/int] Developer switch position at boot
devsw_cur               = 0                              # [RO/int] Developer switch current position
disable_alt_os_request  = 0                              # [RW/int] Disable Alt OS mode on next boot (writable)
disable_dev_request     = 0                              # [RW/int] Disable virtual dev-mode on next boot
ecfw_act                = RO                             # [RO/str] Active EC firmware
enable_alt_os_request   = 0                              # [RW/int] Enable Alt OS mode on next boot (writable)
post_ec_sync_delay      = 0                              # [RW/int] Short delay after EC software sync (persistent, writable, eve only)
alt_os_enabled          = 0                              # [RO/int] Alt OS state (1 if enabled, 0 if disabled)
fmap_base               = 0xff285000                     # [RO/int] Main firmware flashmap physical address
fw_prev_result          = unknown                        # [RO/str] Firmware result of previous boot (vboot2)
fw_prev_tried           = A                              # [RO/str] Firmware tried on previous boot (vboot2)
fw_result               = unknown                        # [RW/str] Firmware result this boot (vboot2)
fw_tried                = A                              # [RO/str] Firmware tried this boot (vboot2)
fw_try_count            = 0                              # [RW/int] Number of times to try fw_try_next
fw_try_next             = A                              # [RW/str] Firmware to try next (vboot2)
fw_vboot2               = 1                              # [RO/int] 1 if firmware was selected by vboot2 or 0 otherwise
fwb_tries               = 0                              # [RW/int] Try firmware B count
fwid                    = Google_Fleex.11297.204.0       # [RO/str] Active firmware ID
fwupdate_tries          = 0                              # [RW/int] Times to try OS firmware update (inside kern_nv)
hwid                    = GRABBITER G7B-B4E-N5A-K44-E6S-A94-A7T # [RO/str] Hardware ID
inside_vm               = 0                              # [RO/int] Running in a VM?
kern_nv                 = 0x0000                         # [RO/int] Non-volatile field for kernel use
kernel_max_rollforward  = 0xfffffffe                     # [RW/int] Max kernel version to store into TPM
kernkey_vfy             = sig                            # [RO/str] Type of verification done on kernel key block
loc_idx                 = 0                              # [RW/int] Localization index for firmware screens
mainfw_act              = A                              # [RO/str] Active main firmware
mainfw_type             = normal                         # [RO/str] Active main firmware type
nvram_cleared           = 0                              # [RW/int] Have NV settings been lost?  Write 0 to clear
oprom_needed            = 0                              # [RW/int] Should we load the VGA Option ROM at boot?
phase_enforcement       = (error)                        # [RO/int] Board should have full security settings applied
recovery_reason         = 0                              # [RO/int] Recovery mode reason for current boot
recovery_request        = 0                              # [RW/int] Recovery mode request
recovery_subcode        = 0                              # [RW/int] Recovery reason subcode
recoverysw_boot         = 0                              # [RO/int] Recovery switch position at boot
recoverysw_cur          = (error)                        # [RO/int] Recovery switch current position
recoverysw_ec_boot      = 0                              # [RO/int] Recovery switch position at EC boot
recoverysw_is_virtual   = 1                              # [RO/int] Recovery switch is virtual
ro_fwid                 = Google_Fleex.11297.204.0       # [RO/str] Read-only firmware ID
tpm_attack              = 0                              # [RW/int] TPM was interrupted since this flag was cleared
tpm_fwver               = 0x00010001                     # [RO/int] Firmware version stored in TPM
tpm_kernver             = 0x00010001                     # [RO/int] Kernel version stored in TPM
tpm_rebooted            = 0                              # [RO/int] TPM requesting repeated reboot (vboot2)
tried_fwb               = 0                              # [RO/int] Tried firmware B before A this boot
try_ro_sync             = 0                              # [RO/int] try read only software sync
vdat_flags              = 0x0003cc76                     # [RO/int] Flags from VbSharedData
vdat_timers             = LFS=0,0 LF=0,0 LK=0,414548     # [RO/str] Timer values from VbSharedData
wipeout_request         = 0                              # [RW/int] Firmware requested factory reset (wipeout)
wpsw_boot               = 1                              # [RO/int] Firmware write protect hardware switch position at boot
wpsw_cur                = 1                              # [RO/int] Firmware write protect hardware switch current position
EOM


parse1arg() {
    is_comparison= $2
    if [[ "${is_comparison}x" = "x" ]]; then
        is_comparison=2
    fi
    if [[ $1 == *"?"* ]]; then
        if [[ $is_comparison -eq 0 ]]; then
            return 0
        fi
        aft="${1#*\?}" # after
        bef="${1%\?*}" # before
        if [[ "${!bef}" == *"$aft"* ]]; then
            return 0
        fi
        return 1
    else
        if [[ $is_comparison -eq 1 ]]; then
            return 0
        fi
        echo -n "${!1//$'\n'}"
    fi
}

logicor() {
    if [[ $1 -eq 1 ]]; then
        return 1
    elif [[ $2 -eq 1 ]]; then
        return 1
    else
        return 0
    fi
}

if [[ $# -eq 0 ]]; then
    echo -e "$cwossystem"
elif [[ $# -eq 1 ]]; then
    parse1arg $1
    exit $?
else
    is_comparison=0
    current_excode=0
    is_first=1
    if [[ $1 == *"?"* ]]; then
        is_comparison=1
        aft="${1#*\?}" # after
        bef="${1%\?*}" # before
        if [[ "${!bef}" == *"$aft"* ]]; then
            logicor $current_excode 0
            current_excode=$?
        else
          logicor $current_excode 1
          current_excode=$?
        fi
    else
        echo -n "${!1//$'\n'}"
    fi
    echo -n " "
    for arg in "$@"; do
        if [[ is_first -eq 1 ]]; then
            is_first=0
            continue
        fi
        parse1arg $arg
        excode="$?"
        logicor $current_excode $excode
        current_excode=$?
        echo -n " "
    done
    exit $current_excode
fi
