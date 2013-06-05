Raspberry Pi Temperature Monitor
================================

Installation
------------

1. Add the following lines to your Pi's /etc/modules

    > w1-gpio

    > w1-therm

2. Reboot, or run:

    > sudo modprobe w1-gpio

    > sudo modprobe w1-therm

3. Set the correct settings in the config.yml file

Running
-------

The software runs like an initscript. Once started, it daemonises and returns you to a terminal.

> ruby temp.rb start

> ruby temp.rb restart

> ruby temp.rb stop
