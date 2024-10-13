import serial
import subprocess

# Set up serial connection (adjust serial port to match your configuration)
ser = serial.Serial('/dev/ttyUSB0', 230400)

# Function to send command to XBee
def send_command(command):
    ser.write((command + '\r\n').encode())

# Function to ping from the Raspberry Pi
def ping_address(address):
    response = subprocess.run(['ping', '-c', '5', address], capture_output=True)
    return response.stdout.decode()

# Example usage
send_command('Hello XBee')  # Sending data to XBee
print(ping_address('8.8.8.8'))  # Pinging Google DNS from Pi