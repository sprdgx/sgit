#!/bin/bash

set -e  # Stop script on error
set -x  # Print each command before executing it

# SGIT: Custom shell for creating and interacting with GitHub repositories

GITHUB_USER=""     # Replace with your GitHub username
GITHUB_TOKEN=""       # Replace with your GitHub Personal Access Token

# Function to create a local directory, initialize Git, and create a GitHub repository
create_and_push_repo() {
    local folder_name="$1"

    # Create the folder
    mkdir "$folder_name"
    cd "$folder_name"

    # Initialize a local Git repository
    git init

    # Create a README file
    echo "# $folder_name" > README.md
    git add README.md
    git commit -m "Initial commit"

    # Create a repository on GitHub using the GitHub API
    response=$(curl -s -u "$GITHUB_USER:$GITHUB_TOKEN" https://api.github.com/user/repos -d "{\"name\":\"$folder_name\"}")

    # Check if repository creation was successful
    if echo "$response" | grep -q "Bad credentials"; then
        echo "Error: Invalid GitHub credentials."
        exit 1
    elif echo "$response" | grep -q "already exists"; then
        echo "Error: Repository $folder_name already exists on GitHub."
        exit 1
    else
        echo "Repository $folder_name created successfully."
    fi

    # Add remote origin and push to GitHub
    git remote add origin "https://github.com/$GITHUB_USER/$folder_name.git"
    git push -u origin master

    echo "Repository $folder_name created and pushed to GitHub!"
}

# Function to clone an existing GitHub repository
clone_repo() {
    local repo_name="$1"

    # Clone the repository from GitHub
    git clone "https://github.com/$GITHUB_USER/$repo_name.git"

    echo "Repository $repo_name cloned from GitHub!"
}

# Function to add, commit, and push changes to GitHub repository
update_repo() {
    local folder_name="$1"
    local commit_message="$2"

    if [[ -d "$folder_name" ]]; then
        cd "$folder_name"

        # Check if it's a Git repository
        if [ -d ".git" ]; then
            # Check for changes
            if [[ -n $(git status --porcelain) ]]; then
                # Add all changes
                git add .

                # If commit message is provided, use it; otherwise use default message
                if [[ -n "$commit_message" ]]; then
                    git commit -m "$commit_message"
                else
                    git commit -m "Updated files in $folder_name"
                fi

                # Push changes to GitHub
                if git push origin master; then
                    echo "Changes in $folder_name pushed to GitHub!"
                else
                    echo "Error: Failed to push changes to GitHub."
                    exit 1
                fi
            else
                echo "No changes to commit and push."
            fi
        else
            echo "Error: $folder_name is not a git repository."
            exit 1
        fi
    else
        echo "Error: Folder $folder_name does not exist."
        exit 1
    fi
}

# Main logic for SGIT
if [[ "$1" == "dir" ]]; then
    if [[ -n "$2" ]]; then
        create_and_push_repo "$2"
    else
        echo "Usage: SGIT dir <folder_name>"
    fi
elif [[ "$1" == "djib" ]]; then
    if [[ -n "$2" ]]; then
        clone_repo "$2"
    else
        echo "Usage: SGIT djib <repo_name>"
    fi
elif [[ "$1" == "abaat" ]]; then
    if [[ -n "$2" ]]; then
        # Pass the folder name and the commit message (if provided)
        update_repo "$2" "$3"
    else
        echo "Usage: SGIT abaat <folder_name> [<commit_message>]"
    fi
else
    echo "Invalid command. Available commands: dir, djib, abaat"
fi
