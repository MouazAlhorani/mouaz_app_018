import subprocess
import re

interface = "ens35"
firewall_ip = "192.168.50.240"
arp_command = ["arp", "-i", interface, "-n", firewall_ip]
process = subprocess.Popen(arp_command, stdout=subprocess.PIPE)
output, _ = process.communicate()
connected_devices = []
for line in output.decode("utf-8").splitlines():
    match = re.match(r"^(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+?)\s+(.+)", line)
    if match:
        ip_address = match.group(2)
        mac_address = match.group(4)
        connected_devices.append((ip_address, mac_address))
for ip_address, mac_address in connected_devices:
    print(f"IP Address: {ip_address}\tMAC Address: {mac_address}")