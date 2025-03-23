#!/bin/bash

home_path=$HOME
ssh_dir=$home_path"/.ssh"
ssh_config_file=$ssh_dir"/config"

github_url="ssh.github.com"
github_port=443
github_user="git"
github_ssh_key_page="https://github.com/settings/ssh/new"

username_prompt_message="Please enter your name: "

# Ensure the user enters a non-empty name
while [[ -z "$username" ]]; do
    read -p "${username_prompt_message}" username
    if [[ -z "$username" ]]; then
        echo "Name cannot be empty. Please try again."
    fi
done

# Convert name to lowercase and replace spaces with underscores
username_lowercase=$(echo "$username" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
name_lower=$(echo "$username_lowercase" | tr '_' '-')

# Create GitHub configuration string
github_config="# GitHub configuration\n"
github_config+="Host ${name_lower}-github\n"
github_config+="HostName ${github_url}\n"
github_config+="User ${github_user}\n"
github_config+="Port ${github_port}\n"
github_config+="IdentityFile ~/.ssh/id_${username_lowercase}"

# Check if ~/.ssh directory exists, if not create it
if [ ! -d "$ssh_dir" ]; then
    echo "The ${ssh_dir} directory doesn't exist. Creating it..."
    mkdir -p "$ssh_dir"
else
    echo "The ${ssh_dir} directory already exists. Continuing with next step"
fi

# Check if SSH key file exists for the user
ssh_key_file="${ssh_dir}/id_${username_lowercase}"

if [ -f "$ssh_key_file" ]; then
    read -p "SSH key file already exists. Do you want to continue and overwrite? (y/n) [default: n]: " overwrite_choice

    if [[ -z "$overwrite_choice" ]]; then
        overwrite_choice="n"
    fi

    if [[ "$overwrite_choice" != "y" && "$overwrite_choice" != "Y" ]]; then
        echo -e "Exiting...\n"
        exit 1
    fi
    # If the user chooses to overwrite, generate new key, but don't append to config.
    echo "Generating new SSH key, config will not be updated..."
    ssh-keygen -t ed25519 -f "$ssh_key_file" -N ""

else
    # Generate SSH key
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -f "$ssh_key_file" -N ""

    # Check if ~/.ssh/config file exists, if not create it
    if [ ! -f "$ssh_config_file" ]; then
        echo -e "\nCreating ${ssh_config_file} file..."
        touch "$ssh_config_file"
    else
        echo -e "\nThe ${ssh_config_file} already exists. Continuing with next step"
    fi

    # Check if the configuration already exists in ~/.ssh/config
    if grep -q "^Host ${name_lower}-github$" "$ssh_config_file"; then
        echo "GitHub configuration already exists in ${ssh_config_file}. Skipping appending content."
    else
        # Append GitHub configuration content to ~/.ssh/config
        echo -e "Appending content to ${ssh_config_file}... \n"
        echo -e "\n$github_config" >> "$ssh_config_file"
    fi
fi

# Show updated content of ~/.ssh/config
echo -e "Content of ${ssh_config_file} file: \n"
echo -e "####################################################################################################### \n"
cat "$ssh_config_file"
echo -e "####################################################################################################### \n"

echo -e "Copy the content of ${ssh_dir}/id_${username_lowercase}.pub file \n"
cat "${ssh_dir}/id_${username_lowercase}.pub"

echo -e "\nPaste the above content here ${github_ssh_key_page} \n"

echo -e "Now, you can clone the repositories like below: \n"

echo -e "git clone git@${name_lower}-github:<repo_owner_name>/<repo_name>.git \n"
