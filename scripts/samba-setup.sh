#!/bin/bash
OUTPUT_FILE="/home/subash/user_password.txt"
SAMBA_SHARE_DIR="/saakha-share"
GROUP_ARRAY=()

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

# ------------------ Configuration -------------------

function usage {
    print_header "User Setup"

    echo "Usage: $0 -g <group1,group2,...>"
    echo
    echo "Options:"
    echo "  -g, --group   Comma-separated list of group names (e.g., hr,finance,it)"
    echo
    print_intermediate "Example:"
    print_init "  ./samba-setup.sh -g hr,finance,command-center"
    print_fail "For more information, contact us:"
    print_success "  Email: pingjiwan@gmail.com,  Phone: +977 9866358671"
    print_success "  Email: subaschy729@gmail.com, Phone: +977 9823827047"
    exit 1
}

taking_input() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--group)
                IFS=',' read -ra GROUP_ARRAY <<< "$2"
                shift 2
                ;;
            *)
                usage
                ;;
        esac
    done

    if [[ ${#GROUP_ARRAY[@]} -eq 0 ]]; then
        print_fail "Error: At least one group name is required."
        usage
    fi
}

# ------------------ Core Logic -------------------

initialize_output_file() {
    sudo mkdir -p "$(dirname "$OUTPUT_FILE")"
    if [ ! -f "$OUTPUT_FILE" ]; then
        sudo touch "$OUTPUT_FILE"
    fi
}

generate_password() {
    openssl rand -base64 12
}

create_group() {
    if sudo getent group "${GROUP}" > /dev/null; then
        print_fail "Group '${GROUP}' already exists."
    else
        if sudo groupadd "${GROUP}"; then
            print_success "Group '${GROUP}' created successfully."
        else
            print_fail "Failed to create group '${GROUP}'."
            exit 1
        fi
    fi
}

create_user_and_set_samba() {
    if id "${USERNAME}" &>/dev/null; then
        print_fail "User '${USERNAME}' already exists. Skipping creation and Samba password setup."
    else
        if sudo useradd -m -G "${GROUP}" "${USERNAME}"; then
            print_success "User '${USERNAME}' created and added to group '${GROUP}'."
            set_samba_password_for_user
        else
            print_fail "Failed to create user '${USERNAME}'."
        fi
    fi
}

set_samba_password_for_user() {
    local password
    password=$(generate_password)

    printf "$password\n$password\n" | sudo smbpasswd -a "${USERNAME}" > /dev/null
    if [ $? -eq 0 ]; then
        print_success "Samba password set for '${USERNAME}'."
        {
            echo "-----------------------------------------------------------"
            echo "Run Time  : $(date '+%Y-%m-%d %H:%M:%S')"
            echo "group_name: ${GROUP}"
            echo "username  : ${USERNAME}"
            echo "password  : $password"
        } | sudo tee -a "$OUTPUT_FILE" > /dev/null
    else
        print_fail "Failed to set Samba password for '${USERNAME}'."
    fi
}

set_directory_permissions() {
    local dir="${SAMBA_SHARE_DIR}/${GROUP}"
    print_init "Setting permissions for shared directory '$dir'..."

    if [ ! -d "$dir" ]; then
        sudo mkdir -p "$dir"
        print_intermediate "Directory '$dir' created."
    fi

    if sudo chown :"${GROUP}" "$dir" && sudo chmod 750 "$dir"; then
        print_success "Permissions set for '$dir'."
    else
        print_fail "Failed to set permissions for '$dir'."
    fi
}

# ------------------ Main Execution -------------------

main() {
    print_header "User Setup"
    taking_input "$@"
    initialize_output_file

    RUN_TIME=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "\n============> Script run at $RUN_TIME ============\n" | sudo tee -a "$OUTPUT_FILE" > /dev/null

    for GROUP in "${GROUP_ARRAY[@]}"; do
        USERNAME="${GROUP}_user"
        print_separator
        print_init "🚀 Processing group: ${GROUP} (user: ${USERNAME})"
        create_group
        create_user_and_set_samba
        set_directory_permissions
    done

    print_success "✅ All tasks completed. User details saved to $OUTPUT_FILE"
}

main "$@"

