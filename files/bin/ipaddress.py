#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import socket
from colorama import init, Fore, Style
init()

def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip

if __name__ == "__main__":
    print(Fore.CYAN + '\n\n\n\n\n\nIP address: ' + Fore.YELLOW + "{}\n".format(get_ip_address()) + Style.RESET_ALL)

print(Fore.CYAN + "complete." + Style.RESET_ALL)
