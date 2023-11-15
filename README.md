<div align="center">

<h1>fakemurk</h1>

</div>

## What is this?

```
murk - "mûrk": noun
	1. To re-enroll a previously shimmered chromebook.

The Skid Dictionary of the English Language, 7th Edition.
```

`fakemurk` is a tool intended for use on an already unenrolled chromebook. It will allow you to re-enroll, making your chromebook appear identical to an enrolled one, except keep developer mode, and even boot off a linux USB, all while **_tricking chromeOS into thinking you're in verified mode_**, so your chromebook will not show up any different from the hundreds of other chromebooks in your enterprise's google admin console.

If you're interested, check out coolelectronics's [writeup/blog](https://coolelectronics.me/blog/breaking-cros-3)

## Why should I use this?

We're going to assume that if you're reading this, there's a 99% chance you're either a student, (or hey maybe even a sysadmin for a school), and you've probably recently used sh1mmer on your chromebook.

Now, we're also going to go out on a limb here and say that if you're a student, there's a good chance your local sysadmin does not want you to be unenrolling, and if you have a more nosy one, they're gonna try and find people unenrolling.
There's also a good chance you didn't properly cover your tracks, and certain logs in the google admin console can reveal you.
Your school might also require the use of kiosk apps for tests, and you might not know how to spoof them.
You also might not know your school's wifi password, but still want to be free of restrictions and spying at home

The list goes on.

## How do I use this??

For best results, we recommend recovering with a 107 recovery image prior to running the script. It makes things more consistent and less likely to randomly fail. Fakemurk will not work on anything above ChromeOS v116. It will give you either, a sshd error, or it will say ChromeOS is missing or damaged. So don't try it.

First, you want to already have an unenrolled chromebook and you want to turn devmode on. You also might want to prepare a USB with the linux distro of your choice (or maybe chromeos flex). Install [MrChromebox's RW_LEGACY bios](https://mrchromebox.tech/#fwscript) if you haven't already.
Next, head over to chrome-untrusted://crosh, type `shell` and then type out the following commands ***one by one***

```
sudo -i
bash <(curl -SLk https://github.com/MercuryWorkshop/fakemurk/releases/latest/download/fakemurk.sh)
```

Do everything it tells you to, and your chromebook will reboot.

#### Tip:
If you get an error about a filesystem being readonly run
`fsck -f $(rootdev)`
then reboot


### READ THIS IT IS IMPORTANT!!!

If you simply press ctrl-d on the devmode screen and proceed as normal, there's a good chance you'll be stuck on the "enrolling device" screen forever, then get an enrollment error complaining about a certificate.

IF THIS HAPPENS, what you want to do is press refresh+power to reboot the chromebook, when it gives you the os verification screen press space to **disable devmode**, and then press refresh+power. This will result in a "Chrome OS is missing or damaged" screen. THIS IS SUPPOSED TO HAPPEN!. Press escape+refresh+power, then ctrl+d and enter to **reenable devmode**. When you get back to the "OS verification screen" press Ctrl-D to boot.

If you get another "Chrome OS is missing" screen, and you're absolutely sure that you didn't press space after the re-enable step, you might have run into a semi-common bug. We haven't pinned down the cause of this yet, but it can usually be fixed by downgrading/recovering to a 107 or 105 image, then restarting all the steps from the beginning, but **make sure to omit the devmode cycle steps above**, and just keep devmode on the entire time.

Also, DO NOT use the sign out button to sign out of ChromeOS, use Power + Refresh or Reboot in crosh. If you use the sign out button there is a 90% chance your Chromebook will freeze then when it reboots, you will need to use Sh1mmer's disable block dev mode to remove the screen, don't worry. This is not the firmware blocking dev mode, just ChromeOS. So you can still use the Sh1mmer disable block dev mode on any CR50 version. 

(note that if you have a "dedede" chromebook, the steps for enabling and disabling devmode are slightly different but you should already know or know how to google)

### VERSION REPORTING NOTE

fakemurk does not fake reporting what version you're on. The longer you stay on the same version with fakemurk could start to raise flags as your version will be much lower. After a few months, consider recovering with a v107 recovery image, then run sh1mmer to unenroll, **then update to 111 or whatever the latest stable version is**, then use fakemurk, and repeat on new releases. You only need to do this every once in a while.

## How it works

ChromeOS interally uses a library called "crossystem" (chrome os system), which reports critical low-level information about the current state of the system, such as the hardware ID, and importantly here whether devmode is enabled or not. Since a lot of low level ChromeOS code is written in bash, it couldn't have crossystem be a c++ library, so it gets compiled to a static binary on the system instead. `crossystem` isn't the only internal library written like this, but it's the most important one. Again, if you want to know more about how this works, look at the [writeup](https://coolelectronics.me/blog/breaking-cros-3)

Since the system trusts this crossystem file to tell if devmode is enabled and snitch about its status to the Google Admin Console, we can make our own version of this file that perpetually reports devmode being off, even though the system still lets us boot unverified versions of ChromeOS.

This limbo state, however, comes with strings attached. As the OS thinks we're in verified mode, typing `shell` into crosh, and escalating to root with `sudo` does not work. Luckily, since the firmware is in developer mode, we can disable rootfs verification and drop a backdoored sshd config, as well as replace any binary in the system with our own custom script. This is where `mush` comes into play.

`mush` is a drop-in replacement for crosh, offering various utilites such as a shell and more. mush is what really ties fakemurk together, making it more than just developer mode on verified boot. With mush, you have full OS control without leaving CrOS. This effectively means you are in a pseudo developer mode, where as far as the OS is concerned everything is normal, but you have full behind-the-scenes shell access.

Mush contains the following features:

1. Extension disabler - allows you to toggle on and off any extension
2. Root shell - gives you a bash shell as root. If you don't know what bash is ignore this
3. Pollen editor - allows you to enable disable certain "policies" that administrators apply to your chromebook. Note that any policies starting with "Device" cannot be modified by Pollen, and will require lilac instead.
4. Emergency revert - will immediately reverse changes made by fakemurk and go back to a normal verified mode enrolled chromebook.

By default, the script will modify policies allowing you to do the following:

1. Install any extension from the chrome web store
2. Log in to google (NOT ON THE CHROMEOS LOGIN SCREEN) with any account, not just ones linked to your managed domain
3. Install any APK on the google play store (the play store might appear blank, in which case you should download the [aurora store apk](https://gitlab.com/AuroraOSS/AuroraStore/uploads/bbc1bd5a77ab2b40bbf288ccbef8d1f0/AuroraStore_4.1.1.apk) and install it with the package installer by right clicking on the file)
4. Attempt to install crostini (usually won't work, do not make an issue if this breaks)

### but crosh is blocked :( :( :( :(

Easy! While fakemurk is installed, go into your downloads folder (NOT GOOGLE DRIVE), make a folder and call it "disable-extensions". As long as that folder exists, no extension will be able to load and you'll be able to visit crosh, where you can then delete the folder and use mush to gain more fine-grain control over the specific extensions you want to enable.

### ohhh but i'm a skid i'm too stupid to install this please help me :((((((

If this doesn't work, there's an 85% chance you did something really dumb while installing and need to read the directions more carefully.
You should NOT ping or dm any of the creators about your failure.

Now, there's also the chance that something is genuinely broken and if you get the text `"THIS IS A BUG, REPORT IT HERE https://github.com/MercuryWorkshop/fakemurk/issues"`, you should do just that, but making sure you don't see any duplicates first. Follow the [issue template](https://github.com/MercuryWorkshop/fakemurk/blob/main/ISSUE_TEMPLATE)

Use the [titanium network discord](discord.gg/unblock) for any further questions, please don't harass anyone in dms.

## Credits

- r58Playz#3467 - created bash emulators for vpd and crossystem, trawled through chromium source to find out what needed to be patched
- CoolElectronics#4683 - initial idea for the project, created the installer
- Rafflesia#8396 - found user policy modification, which is used here
- The rest of the Mercury Workshop team - assistance with testing and miscellaneous files
