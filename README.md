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

If you're interested, check out coolelectronics's [blog post on this](https://coolelectronics.me/breaking-cros-3)

## Why should I use this?

We're going to assume that if you're reading this, there's a 99% chance you're either a student, (or hey maybe even a sysadmin for a school), and you've probably recently used sh1mmer on your chromebook.

Now, we're also going to go out on a limb here and say that if you're a student, there's a good chance your local sysadmin does not want you to be unenrolling, and if you have a more nosy one, they're gonna try and find people unenrolling.
There's also a good chance you didn't properly cover your tracks, and certain logs in the google admin console can reveal you.
Your school might also require the use of kiosk apps for tests, and you might not know how to spoof them.
You also might not know your school's wifi password, but still want to be free of restrictions and spying at home

The list goes on.

## How do I use this??

First, you want to already have an unenrolled chromebook in devmode. You also might want to prepare a USB with the linux distro of your choice (or maybe chromeos flex). [link to catakangs video](here)

Next, head over to chrome-untrusted://crosh, type `shell` and then run the bash script as root.

Do everything it tells you to, and after the final powerwash, you will automatically re-enroll.
Thats it!

## How it works

All crossystem libraries in CrOS depend on `crossystem.sh`, so we simply replace it with our own version that says all the firmware values are normal, when in reality they're set to fucky devmode shit behind the scenes. This allows "verified" boot with developer mode, in a limbo state where the firmware thinks we're in developer mode but our copy of `crossystem.sh` lies to CrOS and it thinks we're in verified mode, allowing for normal enrollment.

This limbo state, however, comes with strings attached. As the OS thinks we're in verified mode, typing `shell` into crosh, and escalating to root with `sudo` does not work. Luckily, since the firmware is in developer mode, we can disable verity and drop a backdoored sshd config, as well as replace crosh with our own file. This is where mush comes into play.

mush is a drop-in replacement for crosh, offering various utilites such as a shell and more. mush is what really ties fakemurk together, making it more than just developer mode on verified boot. With mush, you have full OS control without leaving CrOS. This effectively means you are in a pseudo developer mode, where as far as the OS is concerned everything is normal, but you have full behind-the-scenes shell access.
