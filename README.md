# TaskGrackle - Day Manager

![TaskGrackle in operation](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-daytime.jpg "TaskGrackle in operation")

Keep your life on track with TaskGrackle, a self-hosted and hackable task management system. Run it on macOS, Windows, or a dedicated [Raspberry Pi](https://www.raspberrypi.com/) terminal in your living/working space.

## Features

- **Task reminders** – see what's most important today
- **Easy check-in** – log self-care, cleaning, work, pet care & more with simple keystrokes
- **Mood checkup** – get tailored self-care tips for your day
- **Morning/evening routines** – highlight tasks that get your day started and relax before bed
- **Exercise break** – a curated list of exercises you can do at home
- **Friends & Family** – reminders to check in with people and communities
- **Work Hour** – a checklist to prepare for a focused work session
- **Grocery list** – don't forget any essentials before going to the store
- **Moon status** – get moon info late at night
- **Customizable** – edit the data files and code to make it your own. Change the `frequency_hours` of each task in `data/tasks.rb` to prioritize what's important.
- **Vice management** – limit counterproductive habits with Gracklecoin rewards
- **Grackle vocalizations** – ignore TaskGrackle for too long and it'll start grackling at you (extremely optional)

![Checking in tasks](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-checkin.jpg "Checking in tasks")


## Running

### macOS

Download the repo to your Desktop.

Open Terminal and navigate to the folder with `cd ~/Desktop/taskgrackle`

Ruby should already be installed on macOS. Install dependencies: `gem install colorize httparty`

Add a shortcut command: run `nano ~/.zshrc`. In the editor, scroll to the bottom of the file and paste:
```
alias grackle='cd ~/Desktop/taskgrackle && ruby -Ilib bin/taskgrackle'
alias g='grackle'
```
Save and close the file by pressing `ctrl-x`, `y`, then `ENTER`.

Open a new Terminal window and launch TaskGrackle with `grackle` or `g`.

### Windows

First [install Ruby](https://rubyinstaller.org/).

Download the repo, open a command prompt and navigate to the TaskGrackle folder.

Install dependencies: `gem install colorize httparty`

Run with: `ruby -Ilib bin/taskgrackle`

![TaskGrackle Nights](https://github.com/mirthturtle/taskgrackle/blob/main/img/taskgrackle-nights.jpg "TaskGrackle Nights")


### Raspberry Pi

Clone the repo into your home directory: `git clone https://github.com/mirthturtle/taskgrackle.git`

Then [install Ruby](https://www.ruby-lang.org/en/documentation/installation/).

Install dependencies: `gem install colorize httparty`

Add to ~/.bashrc:
```
alias grackle='cd /home/pi/taskgrackle && ruby -Ilib bin/taskgrackle'
alias g='grackle'
```
Reload bashrc: `. ~/.bashrc` and launch TaskGrackle with `grackle` or `g`.

#### Grackle noises on Raspberry Pi

Some users might appreciate a *graaak* from the bird if it's been too long since a check-in. To use this feature:

Set the number of hours after which your grackle becomes vocal in `data/hours_til.grackle`.

Obtain [grackle sounds](https://www.audubon.org/field-guide/bird/common-grackle) and place in the `sound` directory.

Install VLC & dependencies: `sudo apt-get install vlc pulseaudio alsa-base`

Add a cronjob `crontab -e`:
```
### If it's been long enough, play a grackle sound
## every hour from 9am to 5pm
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

This program is licensed by GPL-3.0. Consult with a health professional before doing any exercises suggested by the software. Grackle ornament by [MaryEllaCreations](https://www.etsy.com/shop/MaryEllaCreations).
