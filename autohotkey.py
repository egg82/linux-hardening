import os

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
    # Iterate files, create/insert/close
    with open("fast_type.ahk", 'w+') as script:
        parse_string("#F2::", script)
        parse_string("SetKeyDelay " + str(0.001 * 1000), script)
        parse_string("AutoTrim Off", script)

        for file in files:
            parse_string("", script)
            vi_open(file, script)
            vi_input(file, script)
            vi_quit(script)
            chmod(file, script)

        # Run all.sh
        parse_string("", script)
        parse_string("SendRaw ./all.sh", script)
        parse_string("Send {Enter}", script)
        parse_string("", script)
        parse_string("return", script)

def vi_open(file_name, script_file):
    # Open in vi because it's more common
    parse_string("SendRaw vi " + file_name, script_file)
    parse_string("Send {Enter}", script_file)
    parse_sleep(0.5, script_file)
    parse_string("Send {Escape}", script_file)
    parse_string("SendRaw :setl noai nocin nosi inde=", script_file) # Something something auto-indenting
    parse_string("Send {Enter}", script_file)
    parse_sleep(0.1, script_file)
    # Insert mode
    parse_string('SendRaw i', script_file)
    parse_sleep(0.1, script_file)

def vi_quit(script_file):
    # Quit vi
    # https://www.commitstrip.com/en/2017/05/29/trapped/
    parse_string("Send {Escape}", script_file)
    parse_string("SendRaw :wq", script_file)
    parse_string("Send {Enter}", script_file)
    parse_sleep(0.5, script_file)

def chmod(file_name, script_file):
    # Make files executable
    parse_string("SendRaw chmod +x " + file_name, script_file)
    parse_string("Send {Enter}", script_file)
    parse_sleep(0.5, script_file)

def parse_string(line, script_file):
    script_file.write(line + '\n')

def vi_input(file_name, script_file):
    with open(file_name, 'r') as file:
        for line in file:
            line = line.rstrip().replace('"', '""').replace(';', "`;")
            if len(line) > 0:
                parse_string("SendRaw % \"" + line + "\"", script_file)
            parse_string("Send {Enter}", script_file)

def parse_sleep(time, script_file):
    script_file.write("Sleep " + str(time * 1000.0) + '\n')

if __name__ == "__main__":
    main()