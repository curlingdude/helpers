"""
This will generate all the information needed to debug internet connections
"""
import datetime
import subprocess
import sys
import re

_today = datetime.date.today()
_now = datetime.datetime.now()

def readlinesStdin():
    ret = ''
    while True:
        line = sys.stdin.readline()
        ret += line
        if line.endswith('reserved.\n'):
            break
    return ret

def preamble():
    f.write("PREAMBLE:\n")
    f.write("My computer is connected directly to the modem. It is running Windows 10.\n")
    f.write("Time of the test was " + _now.isoformat(' ') + '\n')
    f.write("\n")
    f.write("I have tried a different Coax cable from the modem to the wall\n")
    f.write("I have tried reseating my Ethernet cable\n")
    f.write("I have tried a different Ethernet cable\n")
    f.write("I have tried a different computer\n")
    f.write("I have tried disabling the firewall\n")
    f.write("All end up with the same result\n")
    f.write("\n\n")

def speedTest():
    f.write("SPEED TEST:\n")
    subprocess.Popen('"c:/Program Files/Mozilla Firefox/firefox.exe" "http://speedtest.net/"')
    ping = raw_input("Ping: ")
    download = raw_input("Download Speed: ")
    upload = raw_input("Upload Speed: ")
    f.write(ping + " ms ping; " + download + " Mbps Down; " + upload + " Mbps Up\n")
    f.write("\n\n")

def ipconfig():
    f.write("IPCONFIG:\n")
    capture = False
    ipconfigOutput = subprocess.check_output('ipconfig /all')
    # print ipconfigOutput
    for line in ipconfigOutput.split("\r\n"):
        # print line
        if line.startswith("Ethernet adapter eth0"):
            capture = True
        elif line.startswith("Tunnel adapter Teredo Tunneling Pseudo-Interface"):
            capture = False

        if capture:
            f.write(line + "\n")

            match = re.match(r'^\s+DNS Servers.*:\s(.*)$', line)
            if match:
                dnsServer = match.group(1)

            match = re.match(r'^\s+Default Gateway.*:\s(.*)$', line)
            if match:
                defaultGateway = match.group(1)

    f.write("\n")
    return (defaultGateway, dnsServer)

def modemInformation():
    f.write("MODEM INFORMATION:\n")
    subprocess.Popen('"c:/Program Files/Mozilla Firefox/firefox.exe" "http://192.168.100.1/index.html#status_docsis/m/1/s/2"')
    print "Info: "
    f.write(readlinesStdin())
    f.write("\n\n")

def factoryReset():
    f.write("AFTER FACTORY RESET:\n")
    f.write("DNS is set to obtain automatically\n")
    raw_input("Perform Factory Reset and press Enter to continue")
    f.write("\n\n")

def pingTests(defaultGateway, dnsServer):
    f.write("PING TESTS:\n")
    defaultGatewayResults = doCommand('ping -n 50', defaultGateway)
    dnsServerResults = doCommand('ping -n 50', dnsServer)
    googleResults = doCommand('ping -n 50', 'google.ca')

    printResults(defaultGatewayResults, 'Default Gateway')
    printResults(dnsServerResults, 'DNS Server')
    printResults(googleResults, 'google.ca')

def traceRouteTests(dnsServer):
    f.write("TRACE ROUTE TESTS:\n")
    dnsServerResults = doCommand('tracert', dnsServer)
    googleResults = doCommand('tracert', 'google.ca')

    printResults(dnsServerResults, 'DNS Server')
    printResults(googleResults, 'google.ca')

def printResults(results, title):
    f.write(title + ":")
    pingOutput = results.stdout.readlines()
    for line in pingOutput:
        f.write(line.rstrip('\r\n') + '\n')
    f.write("\n")

def doCommand(cmd, server):
    cmd = cmd + ' ' + server
    print cmd
    return subprocess.Popen(cmd, stdout=subprocess.PIPE)

if __name__ == '__main__':
    with open("documents/" + _today.isoformat() + "_issue.txt", 'w') as f:
        preamble()
        speedTest()
        ipconfig()
        modemInformation()
        f.flush()

        factoryReset()

        speedTest()
        _defaultGateway, _dnsServer = ipconfig()
        modemInformation()
        f.flush()
        pingTests(_defaultGateway, _dnsServer)
        traceRouteTests(_dnsServer)
