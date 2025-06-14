#!/bin/bash

GROUP_ARRAY=("hr" "finance" "it" "support")
OUTPUT_FILE="/home/subash/user_password_reset.txt"
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
initialize_output_file() {
    sudo mkdir -p "$(dirname "${OUTPUT_FILE}")"
    sudo bash -c "echo '' > '${OUTPUT_FILE}'"
}

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

create_users() {
    print_init "Creating users and assigning to groups..."
    for group in "${GROUP_ARRAY[@]}"; do
        username="${group}_user"
        if sudo useradd -m -G "${group}" "${username}" 2>/dev/null; then
            print_success "User '${username}' added to group '${group}'."
        else
            print_fail "User '${username}' already exists or failed."
        fi
    done
}

set_samba_passwords() {
    print_init "Setting Samba passwords..."
    for group in "${GROUP_ARRAY[@]}"; do
        username="${group}_user"
        password=$(openssl rand -base64 12)
        generated_date=$(date -Iseconds)

        printf "$password\n$password\n" | sudo smbpasswd -a "${username}" > /dev/null
        if [ $? -eq 0 ]; then
            print_success "Samba password set for '${username}'."

            {
                echo "-----------------------------------------------------------"
                echo "generated_date: $generated_date"
                echo "group_name: ${group}"
                echo "username: ${username}"
                echo "password : $password"
            } | sudo tee -a "${OUTPUT_FILE}" > /dev/null

        else
            print_fail "Failed to set Samba password for '${username}'."
        fi
    done
}

set_directory_permissions() {
    print_init "Creating and securing shared directories..."
    for group in "${GROUP_ARRAY[@]}"; do
        dir="/${SAMBA_SHARE_DIR}/${group}"
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

main() {
    print_header "Saakha Setup"
    initialize_output_file
    create_groups
    create_users
    set_samba_passwords
    set_directory_permissions
    print_success "✅ All tasks completed. User details saved to ${OUTPUT_FILE}"
}

main

