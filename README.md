# TaskGrackle - An annoying grackle tells you what to do

![TaskGrackle in operation](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-daytime.jpg "TaskGrackle in operation")

Get your life on track with TaskGrackle, a hackable, self-hosted life management system. Designed for use on a dedicated Raspberry Pi terminal in your living/working space, but can also be run in a macOS terminal or Windows command prompt.

## Features

- Task reminders – see what's most important today
- Easy check-in – log self-care, cleaning, work, pet care and more with simple keystrokes
- Mood checkup – get tailored self-care tips for your day
- Exercise break – a curated list of exercises you can do at home
- Friends & Family – reminders to check in with people and communities closest to you
- Grocery list - don't forget any essentials before going to the store
- Moon status – get moon info late at night
- Vice management – limit counterproductive habits with Gracklecoin rewards
- Grackle vocalizations – ignore TaskGrackle for too long and it'll start grackling at you
- Customizable – edit the data files and code to make it your own. Change the `frequency_hours` of each task to prioritize what's important.

![Checking in tasks](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-checkin.jpg "Checking in tasks")


## Running

### Raspberry Pi

Clone the repo into your home directory: `git clone https://github.com/mirthturtle/taskgrackle.git`

Install Ruby: [Tutorial](https://dev.to/konyu/installing-the-latest-version-of-ruby-on-raspberry-pi-3ofk)

Install dependencies: `gem install colorize httparty`

Add to ~/.bashrc:
```
alias grackle='cd /home/pi/taskgrackle && ruby -Ilib bin/taskgrackle'
alias g='grackle'
```
Reload bashrc: `. ~/.bashrc` and launch TaskGrackle with `grackle` or `g`.

### macOS

Download the repo to your Desktop.

Open Terminal and navigate to the folder with `cd ~/Desktop/taskgrackle`

Ruby should already be installed on macOS. Install dependencies: `gem install colorize httparty`

Run with: `ruby -Ilib bin/taskgrackle`

### Windows

First [install Ruby](https://rubyinstaller.org/).

Download the repo, open a command prompt and navigate to the folder.

Install dependencies: `gem install colorize httparty`

Run with: `ruby -Ilib bin/taskgrackle`

![TaskGrackle Nights](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-nights.jpg "TaskGrackle Nights")


### Grackle noises on Raspberry Pi

Some users might appreciate an occasional grackle noise throughout the day as a reminder to check in with TaskGrackle. To use this feature, obtain [grackle sounds](https://www.audubon.org/field-guide/bird/common-grackle) and place in the `sound` directory.

Install VLC & dependencies: `sudo apt-get install vlc pulseaudio alsa-base`

Add a cronjob `crontab -e`:
```
### A random grackle sound every hour from 9am to 5pm
0 9-17 *   *   *   XDG_RUNTIME_DIR=/run/user/$(id -u) /home/pi/taskgrackle/vocalization.sh
```
To connect a USB speaker: locate device in `aplay -l`. Specify card number of device in `/usr/share/alsa/alsa.conf`:
```
defaults.ctl.card #
defaults.pcm.card #
```
Adjust volume with `alsamixer`.


### Bangle.js Smartwatch integration – coming soon

"Grackle for the haaaaaaand!" That's what your friends will be saying when they see you sporting your new TaskBangle, the TaskGrackle extension for the [Bangle.js 2](https://banglejs.com/). Coming soon.


### License & credits

This program is licensed by GPL-3.0. Grackle ornament by [MaryEllaCreations](https://www.etsy.com/shop/MaryEllaCreations).
