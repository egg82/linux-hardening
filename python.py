from pynput.keyboard import Key, Controller
import time

keyboard = Controller()

# Files to input/output
files = (
    "all.sh",
    "cloudflare.sh",
    "competition.sh",
    "firewall.sh",
    "root_check.sh",
    "services.sh",
    "settings.sh",
    "tools.sh",
    "users.sh",
    "utils.sh"
)

def main():
    print("Sleeping for 5 seconds..")
    time.sleep(5)
    print("Outputting files..")

    # Iterate files, create/insert/close
    for file in files:
        vi_open(file)
        vi_input(file)
        vi_quit()
        chmod(file)
    
    # Run all.sh
    parse_string("./all.sh")
    press_key(Key.enter)

def vi_open(file_name):
    # Open in vi because it's more common
    parse_string("vi " + file_name)
    press_key(Key.enter)
    time.sleep(1)
    press_key(Key.esc)
    parse_string(":setl noai nocin nosi inde=") # Something something auto-indenting
    press_key(Key.enter)
    time.sleep(0.1)
    # Insert mode
    press_key('i')
    time.sleep(0.1)

def vi_quit():
    # Quit vi
    # https://www.commitstrip.com/en/2017/05/29/trapped/
    press_key(Key.esc)
    parse_string(":wq")
    press_key(Key.enter)
    time.sleep(1)

def chmod(file_name):
    # Make files executable
    parse_string("chmod +x " + file_name)
    press_key(Key.enter)
    time.sleep(1)

def parse_string(line):
    # Print chars in string
    for char in line:
        time.sleep(0.001)
        press_key(char)

def vi_input(file_name):
    # Print chars in file
    with open(file_name, 'r') as file:
        while True:
            char = file.read(1)
            if not char:
                break
            time.sleep(0.001)
            press_key(char)

def press_key(char):
    # shorthand keypress
    keyboard.press(char)
    keyboard.release(char)

if __name__ == "__main__":
    main()