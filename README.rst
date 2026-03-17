KRZOS Ansible Deployment
========================
This repository contains Ansible playbooks and supporting files for automating
the setup of a Raspberry Pi running the KRZOS robot software.

It handles:

- Deploying system packages and Python libraries
- Copying custom home directory dotfiles
- Configuring the system hostname and logging
- Disabling unnecessary services for headless operation
- Cloning the KRZOS GitHub repository
- Configuring SSH keys for GitHub access

Repository Structure
====================

::

    krzos-ansible/
    ├── bootstrap-inventory.yml         # Password-based connection for first-time setup
    ├── inventory.yml                   # SSH key-based connection for normal use
    ├── site.yml                        # Master playbook: runs all setup playbooks in order
    ├── setup-pi.yml                    # Base system setup, SSH key configuration
    ├── disable-unnecessary-services.yml # Removes audio, desktop, and Bluetooth packages
    ├── enable-rsyslog.yml              # Replaces journald with classic text logging
    ├── install-krzos.yml               # Clones the KRZOS repository
    ├── install-ansible.sh              # Run on desktop: installs Ansible into a venv
    ├── ansible-bootstrap.sh            # Run on Pi: installs Python prerequisites
    └── files/
        ├── .aliases                    # CLI aliases
        ├── .cshrc                      # tcsh shell configuration
        ├── .dir_colors                 # Directory colour configuration
        ├── .LSCOLORS                   # ls colour configuration
        ├── .prompt                     # Shell prompt configuration
        ├── .vimrc                      # Vim configuration
        └── motd                        # Message of the day


Desktop Setup
=============
Ansible runs on your desktop (the control node) and connects to the Pi over SSH.
The Pi itself does not need Ansible installed.


Prerequisites
-------------
Install ``sshpass`` on your desktop (required for password-based authentication
during initial setup):

**Debian/Ubuntu:**

.. code-block:: bash

    sudo apt install sshpass

**macOS:**

.. code-block:: bash

    brew install hudochenkov/sshpass/sshpass


1. Install Ansible
------------------
Run the provided script to install Ansible into a Python virtual environment:

.. code-block:: bash

    chmod +x install-ansible.sh
    ./install-ansible.sh

This creates ``~/ansible-venv/`` and installs current Ansible into it, and
creates ``~/.ansible_env.sh`` and ``~/.ansible_env.csh`` for shell integration.


2. Configure Your Shell
-----------------------
Add the appropriate line to your shell rc file:

**tcsh** (``~/.cshrc``):

.. code-block:: csh

    source ~/.ansible_env.csh

**bash** (``~/.bashrc``):

.. code-block:: bash

    source ~/.ansible_env.sh

Then reload your rc file:

.. code-block:: csh

    source ~/.cshrc    # tcsh
    source ~/.bashrc   # bash


3. Configure the Inventories
----------------------------
Edit both ``bootstrap-inventory.yml`` and ``inventory.yml`` to match your Pi's
IP address.

**bootstrap-inventory.yml** (for first-time setup):

.. code-block:: yaml

    all:
      hosts:
        krzos-pi:
          ansible_host: 192.168.1.xx    # replace with your Pi's IP address
          ansible_user: pi
          ansible_ssh_pass: "{{ lookup('env', 'PI_PASSWORD') }}"
          ansible_become_pass: "{{ lookup('env', 'PI_PASSWORD') }}"
          ansible_python_interpreter: /usr/bin/python3

**inventory.yml** (for normal use after SSH keys are configured):

.. code-block:: yaml

    all:
      hosts:
        krzos-pi:
          ansible_host: 192.168.1.xx    # replace with your Pi's IP address
          ansible_user: pi
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          ansible_python_interpreter: /usr/bin/python3


4. Set Pi Password Environment Variable
---------------------------------------
For the bootstrap setup, set the Pi's password as an environment variable.

**tcsh** (add to ``~/.cshrc``):

.. code-block:: csh

    setenv PI_PASSWORD 'your_raspberry_pi_password'

**bash** (add to ``~/.bashrc``):

.. code-block:: bash

    export PI_PASSWORD='your_raspberry_pi_password'

**Note:** Only needed for initial setup with ``bootstrap-inventory.yml``.
After SSH keys are configured, this is no longer required.


Prior to First Boot
===================
Before flashing the SD card, use **Raspberry Pi Imager** to configure the Pi
for headless operation. This is the supported method on Raspberry Pi OS Bookworm
and later — the old ``wpa_supplicant.conf`` and ``ssh`` file approach no longer
works.


1. Flash Raspberry Pi OS
------------------------
- Download and open `Raspberry Pi Imager <https://www.raspberrypi.com/software/>`_
- Select your device, then choose **Raspberry Pi OS Lite (64-bit)** as the OS
- Select your SD card as the target
- Click the **gear icon** (Advanced Options) before flashing and configure:

  - **Hostname** → e.g. ``krzos-pi``
  - **Enable SSH** → enable; select *Use password authentication*
  - **Username and password** → set username to ``pi`` and a secure password
  - **WiFi** → enter your SSID, password, and country code (e.g. ``NZ``)
  - **Locale** → set your timezone and keyboard layout

- Click **Save** then **Write** to flash the SD card

**Important:** Use *password authentication* in the imager settings, not
public-key authentication. The Ansible playbooks will configure SSH keys
automatically during setup.


2. First Boot
-------------
Insert the SD card into the Pi and power it on. The Pi will connect to WiFi
and enable SSH automatically using the settings baked in by Raspberry Pi Imager.

After a minute or so, SSH into the Pi from your desktop:

.. code-block:: bash

    ssh pi@krzos-pi.local

If ``.local`` hostname resolution doesn't work on your network, find the Pi's
IP address from your router's DHCP client list and connect directly:

.. code-block:: bash

    ssh pi@192.168.1.xx


First Boot Manual Configuration
================================
After first boot and successful SSH access, configure hardware interfaces
required for KRZOS using ``raspi-config``:

.. code-block:: bash

    sudo raspi-config

Interface Options
-----------------
Enable the interfaces required by your robot:

- **SSH** → enable (required for remote access)
- **I2C** → enable (required for I2C sensors and devices)
- **SPI** → enable (required for SPI devices)
- **Serial Port** → enable only if using UART; disable serial console if not needed
- **Camera** → enable only if using a Raspberry Pi camera


Advanced Options
----------------
- **Expand Filesystem** → ensures the Pi uses the full SD card

After finishing, exit ``raspi-config`` and reboot if prompted:

.. code-block:: bash

    sudo reboot


Bootstrap the Pi
================
After reboot, copy and run the bootstrap script on the Pi to install the
Python prerequisites required by Ansible:

.. code-block:: bash

    scp ansible-bootstrap.sh pi@krzos-pi.local:~
    ssh pi@krzos-pi.local "sudo bash ansible-bootstrap.sh"

Alternately, you can just run the two command lines::

    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv python3-six


Running the Playbooks
=====================

Initial Setup Workflow
---------------------
The first time you set up a fresh Pi, you must use ``bootstrap-inventory.yml``
because the Pi doesn't have your SSH key yet.

**1. Test connectivity with password authentication:**

.. code-block:: bash

    # tcsh
    setenv PI_PASSWORD 'your_password'
    ansible -i bootstrap-inventory.yml all -m ping

    # bash
    export PI_PASSWORD='your_password'
    ansible -i bootstrap-inventory.yml all -m ping

You should see a green ``pong`` response.

**2. Run the initial setup:**

.. code-block:: bash

    ansible-playbook -i bootstrap-inventory.yml site.yml

This will:

- Install system packages and Python libraries
- Copy dotfiles and configure the shell
- **Generate a GitHub deploy key on the Pi**
- Copy your desktop SSH public key to the Pi for future connections
- Configure passwordless sudo
- Install rsyslog and disable unnecessary services
- Clone the KRZOS repository
- Reboot the Pi

**3. Add the GitHub deploy key:**

During the ``setup-pi.yml`` playbook run, a public key will be displayed in
the output. Copy this key and add it to GitHub:

- Go to https://github.com/ifurusato/krzos/settings/keys
- Click **Add deploy key**
- Paste the public key
- **Check "Allow write access"** (needed for git push)
- Click **Add key**

**4. Verify SSH key authentication works:**

After the Pi reboots, test that key-based authentication works:

.. code-block:: bash

    ansible -i inventory.yml all -m ping

You should see a green ``pong`` response without needing to set ``PI_PASSWORD``.


Normal Usage
-----------
After initial setup is complete, always use ``inventory.yml`` for all subsequent
playbook runs:

.. code-block:: bash

    ansible -playbook -i inventory.yml site.yml

Or run individual playbooks as needed:

.. code-block:: bash

    ansible-playbook -i inventory.yml setup-pi.yml
    ansible-playbook -i inventory.yml disable-unnecessary-services.yml
    ansible-playbook -i inventory.yml enable-rsyslog.yml
    ansible-playbook -i inventory.yml install-krzos.yml


Troubleshooting
--------------

**SSH Host Key Changed Warning:**

If you see a threatening message about remote host identification when trying
to connect to the Pi:

.. code-block:: text

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

This happens when you reuse an IP address that was previously assigned to a
different Pi. Remove the old key from your known_hosts file:

.. code-block:: bash

    ssh-keygen -R 192.168.1.xx
    # or
    ssh-keygen -R krzos-pi.local

Then reconnect normally.

**Permission Denied (publickey) After Initial Setup:**

If you can't connect with ``inventory.yml`` after running ``setup-pi.yml``,
verify the SSH key was copied correctly:

.. code-block:: bash

    # tcsh
    setenv PI_PASSWORD 'your_password'
    ansible -i bootstrap-inventory.yml all -m shell -a "cat ~/.ssh/authorized_keys"

Your desktop's public key should be listed there.


Dry Run
-------
To see what changes would be made without actually applying them:

.. code-block:: bash

    ansible-playbook -i inventory.yml site.yml --check


Playbook Summary
================

**setup-pi.yml**
  Base system configuration: updates apt, installs system packages (git, vim,
  tcsh, i2c-tools, python3-pip, python3-colorama, rshell), copies dotfiles,
  sets hostname, sets tcsh as default shell, generates GitHub SSH deploy key,
  copies desktop SSH public key to Pi, configures passwordless sudo, adds pi
  user to dialout group, reboots if changes were made.

**disable-unnecessary-services.yml**
  Removes packages and disables services not needed for headless operation:
  audio services (PulseAudio, PipeWire, ALSA), desktop environments (X11, LXDE),
  Bluetooth stack, Avahi daemon, and ModemManager. Significantly reduces resource
  usage and attack surface. Reboots to apply changes.

**enable-rsyslog.yml**
  Installs rsyslog, configures journald for minimal volatile operation (10MB
  runtime limit), restores classic text-based logging to ``/var/log/``. Shows
  rsyslog status and journald disk usage.

**install-krzos.yml**
  Creates the workspace directory (``/home/pi/workspaces/workspace-krzos/``) and
  clones the KRZOS repository from GitHub using the deploy key generated by
  ``setup-pi.yml``.

**site.yml**
  Master playbook that runs all setup playbooks in order: setup-pi.yml,
  disable-unnecessary-services.yml, enable-rsyslog.yml, install-krzos.yml.


License
=======
Copyright 2026 by Ichiro Furusato. All rights reserved. This project is
released under the MIT License. Please see the LICENSE file included as
part of this package.

#EOF
