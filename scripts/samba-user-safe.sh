#!/bin/bash

# Global Variables
GROUP_ARRAY=("temp2" "temp3")
OUTPUT_FILE="/home/subash/user_password.txt"
SAMBA_SHARE_DIR="/saakha-share"
# ------------------ Banner and Styling Section -------------------

function print_separator {
    printf "\n%s\n" "--------------------------------------------------------------------------------"
}

function print_header {
    figlet -c -f slant "$1"
    print_separator
}

function print_init {
    local message="$1"
    printf "\e[33m%s\e[0m\n" "$message"
}

function print_intermediate {
    local message="$1"
    printf "\e[34m%s\e[0m\n" "$message"
}

function print_success {
    local message="$1"
    printf "\e[1m\e[32m%s\e[0m\n" "$message"
}

function print_fail {
    local message="$1"
    printf "\e[1m\e[31m%s\e[0m\n" "$message"
}

# ------------------ Core Setup Logic -------------------

# Ensure output file exists without deleting it
initialize_output_file() {
    sudo mkdir -p "$(dirname "${OUTPUT_FILE}")"
    if [ ! -f "${OUTPUT_FILE}" ]; then
        sudo touch "${OUTPUT_FILE}"
    fi
}


# Set directory permissions
set_directory_permissions() {
    print_init "Creating and securing shared directories..."
    for group in "${GROUP_ARRAY[@]}"; do
        dir="${SAMBA_SHARE_DIR}/${group}"
        if [ ! -d "$dir" ]; then
            sudo mkdir -p "$dir"
            print_intermediate "Directory '$dir' created."
        fi

        if sudo chown :"${group}" "$dir" && sudo chmod 750 "$dir"; then
            print_success "Permissions set for '$dir'."
        else
            print_fail "Failed to set permissions for '$dir'."
        fi
    done
}

# Create groups
create_groups() {
    print_init "Creating groups..."
    for group in "${GROUP_ARRAY[@]}"; do
        if sudo groupadd "${group}" 2>/dev/null; then
            print_success "Group '${group}' created."
        else
            print_fail "Group '${group}' already exists or failed."
        fi
    done
}

# Set Samba password and log credentials
set_samba_password_for_user() {
    local group="$1"
    local username="$2"
    local password

    password=$(openssl rand -base64 12)

    printf "$password\n$password\n" | sudo smbpasswd -a "${username}" > /dev/null
    if [ $? -eq 0 ]; then
        print_success "Samba password set for '${username}'."

        {
            echo "-----------------------------------------------------------"
            echo "Run Time  : $(date '+%Y-%m-%d %H:%M:%S')"
            echo "group_name: ${group}"
            echo "username  : ${username}"
            echo "password  : ${password}"
        } | sudo tee -a "${OUTPUT_FILE}" > /dev/null

    else
        print_fail "Failed to set Samba password for '${username}'."
    fi
}

# Create users and call Samba password setup only if user is new
create_users() {
    print_init "Creating users and assigning to groups..."
    for group in "${GROUP_ARRAY[@]}"; do
        username="${group}_user"
        if id "${username}" &>/dev/null; then
            print_fail "User '${username}' already exists. Skipping creation and password setup."
        else
            if sudo useradd -m -G "${group}" "${username}"; then
                print_success "User '${username}' added to group '${group}'."
                set_samba_password_for_user "${group}" "${username}"
            else
                print_fail "Failed to create user '${username}'."
            fi
        fi
    done
}

# ------------------ Main Execution -------------------

main() {
    print_header "Saakha Setup"
    initialize_output_file
    create_groups
    create_users
    set_directory_permissions
    print_success "✅ All tasks completed. User details saved to ${OUTPUT_FILE}"
}

main

