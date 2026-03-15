KRZOS Ansible Deployment
========================
This repository contains Ansible playbooks and supporting files for automating
the setup of a Raspberry Pi running the KRZOS robot software.

It handles:

- Deploying system packages and Python libraries
- Copying custom home directory dotfiles
- Configuring the system hostname and logging
- Cloning the KRZOS GitHub repository
- Configuring SSH keys for GitHub access

Repository Structure
====================

::

    krzos-ansible/
    ├── inventory.yml              # Defines the Pi host and connection settings
    ├── site.yml                   # Master playbook: runs all playbooks in order
    ├── setup-pi.yml               # Base system setup
    ├── enable-rsyslog.yml         # Replaces journald with classic text logging
    ├── install-krzos.yml          # Clones the KRZOS repository
    ├── install-ansible.sh         # Run on desktop: installs Ansible into a venv
    ├── ansible-bootstrap.sh       # Run on Pi: installs Python prerequisites
    └── files/
        ├── .aliases               # CLI aliases
        ├── .cshrc                 # tcsh shell configuration
        ├── .dir_colors            # Directory colour configuration
        ├── .LSCOLORS              # ls colour configuration
        ├── .prompt                # Shell prompt configuration
        ├── .vimrc                 # Vim configuration
        └── motd                   # Message of the day

---

Desktop Setup
=============
Ansible runs on your desktop (the control node) and connects to the Pi over SSH.
The Pi itself does not need Ansible installed.

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

3. Configure the Inventory
--------------------------
Edit ``inventory.yml`` to match your Pi's IP address:

.. code-block:: yaml

    all:
      hosts:
        krzos-pi:
          ansible_host: 192.168.1.xx    # replace with your Pi's IP address
          ansible_user: pi
          ansible_ssh_private_key_file: ~/.ssh/id_rsa
          ansible_python_interpreter: /usr/bin/python3

4. Add GitHub Deploy Key
------------------------
The ``install-krzos.yml`` playbook clones a private GitHub repository using
SSH. You need to register your desktop SSH public key as a deploy key on the
KRZOS GitHub repository.

- Go to the KRZOS repository on GitHub
- Navigate to **Settings → Deploy keys → Add deploy key**
- Paste the contents of ``~/.ssh/id_rsa.pub``
- Leave **Allow write access** unchecked
- Click **Add key**

---

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
  - **Enable SSH** → enable; select *Allow public-key authentication only*
  - **Username and password** → set username to ``pi`` and a secure password
  - **WiFi** → enter your SSID, password, and country code (e.g. ``NZ``)
  - **Locale** → set your timezone and keyboard layout

- Click **Save** then **Write** to flash the SD card

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

---

First Boot Manual Configuration
================================
After first boot and successful SSH access, configure hardware interfaces
required for KRZOS using ``raspi-config``:

.. code-block:: bash

    sudo raspi-config

Interface Options
-----------------
Enable the interfaces required by your robot:

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

---

Bootstrap the Pi
================
After reboot, copy and run the bootstrap script on the Pi to install the
Python prerequisites required by Ansible:

.. code-block:: bash

    scp ansible-bootstrap.sh pi@krzos-pi.local:~
    ssh pi@krzos-pi.local "sudo bash ansible-bootstrap.sh"

---

Running the Playbooks
=====================
From your desktop, verify connectivity to the Pi first:

.. code-block:: bash

    ansible -i inventory.yml all -m ping

You should see a green ``pong`` response. Then run the full setup:

.. code-block:: bash

    ansible-playbook -i inventory.yml site.yml

Or run individual playbooks as needed:

.. code-block:: bash

    ansible-playbook -i inventory.yml setup-pi.yml
    ansible-playbook -i inventory.yml enable-rsyslog.yml
    ansible-playbook -i inventory.yml install-krzos.yml

If you want to set up a Raspberry Pi but not clone the krzos github repository,
you can either comment out or delete that last line. Or modify that playbook to
clone a different repo.

To do a dry run without making any changes:

.. code-block:: bash

    ansible-playbook -i inventory.yml site.yml --check

---

Playbook Summary
================

- **setup-pi.yml** — updates apt, installs system packages, copies dotfiles,
  sets hostname, sets tcsh as default shell, copies SSH key, installs rshell,
  adds pi user to dialout group.
- **enable-rsyslog.yml** — installs rsyslog, configures journald for minimal
  volatile operation, restores classic text-based logging to ``/var/log/``.
- **install-krzos.yml** — creates the workspace directory and clones the KRZOS
  repository from GitHub.
- **site.yml** — runs all three playbooks in order.

#EOF
