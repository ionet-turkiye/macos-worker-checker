#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function Definitions
if [ -f ionet-worker-connect.txt ]; then
    echo "An existing deployment command is found."
    echo "Do you want to use the existing command? (yes/no)"
    read use_existing_command
    
    if [[ "$use_existing_command" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        deployment_command=$(cat ionet-worker-connect.txt)
    else
        echo "Please enter the deployment command:"
        read deployment_command
        echo $deployment_command > ionet-worker-connect.txt
    fi
else
    echo "Please enter the deployment command:"
    read deployment_command
    echo $deployment_command > ionet-worker-connect.txt
fi



function healthCheck {
    local image_count=$(docker image ls | grep -c ionet)
    local container_count=$(docker ps | grep -c ionet)

    if [ $image_count -eq 3 ] && [ $container_count -eq 2 ]; then
        echo -e "${GREEN}All systems operational.${NC}"
        return 0
    else
        echo -e "${RED}Health check failed. System not operational.${NC}"
        echo "Do you want to fix the problem and install worker node ? (yes/no)"
        read response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            reinstallIONetWorker
        else
            echo -e "${GREEN}Skipping reinstallIONetWorker.${NC}"
        fi
        return 1
    fi
}

function reinstallIONet {
    echo "Downloading and setting up IONet Binary..."
    curl -s -L https://github.com/ionet-official/io_launch_binaries/raw/main/launch_binary_mac -o launch_binary_mac && chmod +x launch_binary_mac && echo -e "${GREEN}IONet Binary reinstallation completed.${NC}" || echo -e "${RED}Failed to download IONet Binary.${NC}"

    echo "Cleaning up existing Docker components before reinstalling IONet Worker..."
    removeAllDeployment
    
    echo "Reinstalling IONet Worker using command from ionet-worker-connect.txt..."
    deployment_command=$(cat ionet-worker-connect.txt)
    if bash -c "$deployment_command"; then
        echo -e "${GREEN}IONet Worker reinstallation completed using the provided command.${NC}"
    else
        echo -e "${RED}Failed to reinstall IONet Worker using the provided command.${NC}"
    fi
}


function reinstallIONetBinary {
    echo "Downloading and setting up IONet Binary..."
    curl -s -L https://github.com/ionet-official/io_launch_binaries/raw/main/launch_binary_mac -o launch_binary_mac
    if [ $? -eq 0 ]; then
        chmod +x launch_binary_mac
        echo -e "${GREEN}IONet Binary reinstallation completed.${NC}"
    else
        echo -e "${RED}Failed to download IONet Binary.${NC}"
    fi
}


function reinstallIONetWorker {
    echo "Cleaning up existing Docker components before reinstalling IONet Worker..."
    removeAllDeployment
    
    echo "Reinstalling IONet Worker using command from ionet-worker-connect.txt..."
    deployment_command=$(cat ionet-worker-connect.txt)
    if bash -c "$deployment_command"; then
        echo -e "${GREEN}IONet Worker reinstallation completed using the provided command.${NC}"
    else
        echo -e "${RED}Failed to reinstall IONet Worker using the provided command.${NC}"
    fi
}



function removeAllDeployment {
    echo "Stopping all running Docker containers..."
    docker stop $(docker ps -a -q)
    echo "Removing all Docker containers..."
    docker rm $(docker ps -a -q)
    echo "Removing all Docker images..."
    docker rmi $(docker images -q)
    echo "Removing Docker storage volumes..."
    docker volume rm $(docker volume ls -q)
    echo -e "${GREEN}All Docker components removed.${NC}"
}

function disableEnergySaver {
    # MacOS specific commands to disable energy saver and screen saver
    defaults -currentHost write com.apple.screensaver idleTime 0
    sudo pmset -b sleep 0; sudo pmset -b disablesleep 1
    echo -e "${GREEN}Energy Saver and Screen Saver disabled.${NC}"
}

function installRosetta {
    echo "Installing Rosetta 2..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license && echo -e "${GREEN}Rosetta 2 installation completed.${NC}" || echo -e "${RED}Rosetta 2 installation failed.${NC}"
}

function autopilotSetup {
    while true; do
        echo -e "${GREEN}AutoPilot Setup${NC}"
        echo "1 - Schedule AutoPilot"
        echo "2 - List AutoPilot Schedule"
        echo "3 - Delete AutoPilot Schedule"
        echo "4 - Back to Main Menu"
        read -p "Select an option: " autopilot_option

        case $autopilot_option in
            1)
                scheduleAutopilot
                ;;
            2)
                listAutopilot
                ;;
            3)
                deleteAutopilot
                ;;
            4)
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
    done
}

function scheduleAutopilot {
    # Check if a schedule already exists for ionet-worker-autopilot.sh
    if crontab -l | grep -q 'ionet-worker-autopilot.sh'; then
        echo -e "${RED}An AutoPilot schedule already exists. Delete the existing schedule before creating a new one.${NC}"
        return
    fi

    echo -e "${GREEN}Enter the time interval in minutes for the AutoPilot schedule:${NC}"
    read minutes

    # Define the path for the autopilot and worker script
    local script_path="$(pwd)/ionet-worker-autopilot.sh"
    local worker_script_path="$(pwd)/ionet-worker-autopilot2.sh"

    # Create the ionet-worker-autopilot-worker.sh script with necessary functions and checks
    echo "Creating AutoPilot worker script at $worker_script_path"
    cat <<EOF > "$worker_script_path"
#!/bin/bash
# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Health Check Function
function healthCheck {
    local image_count=\$(docker image ls | grep -c ionet)
    local container_count=\$(docker ps | grep -c ionet)

    if [ \$image_count -eq 3 ] && [ \$container_count -eq 2 ]; then
        echo -e "\${GREEN}All systems operational.\${NC}"
        return 0
    else
        echo -e "\${RED}Health check failed. System not operational.\${NC}"
        return 1
    fi
}

# Reinstall IONet Worker Function
function reinstallIONetWorker {
    echo "Cleaning up existing Docker components before reinstalling IONet Worker..."
    docker stop \$(docker ps -a -q)
    docker rm \$(docker ps -a -q)
    docker rmi \$(docker images -q)
    docker volume rm \$(docker volume ls -q)
    echo "Reinstalling IONet Worker using command from ionet-worker-connect.txt..."
    deployment_command=\$(cat ionet-worker-connect.txt)
    if bash -c "\$deployment_command"; then
        echo -e "\${GREEN}IONet Worker reinstallation completed using the provided command.\${NC}"
    else
        echo -e "\${RED}Failed to reinstall IONet Worker using the provided command.\${NC}"
    fi
}

# Run health check, and reinstall if needed
if ! healthCheck; then
    reinstallIONetWorker
fi
exit 0
EOF

    chmod +x "$worker_script_path"

    # Create or update the autopilot script
    echo "Creating AutoPilot script at $script_path"
    echo "#!/bin/bash" > "$script_path"
    echo "bash $worker_script_path" >> "$script_path"
    echo "exit 0" >> "$script_path"
    chmod +x "$script_path"

    # Schedule the job in crontab
    (crontab -l 2>/dev/null; echo "*/$minutes * * * * $script_path") | crontab -
    echo -e "${GREEN}AutoPilot scheduled every $minutes minutes.${NC}"
}



function listAutopilot {
    local autopilot_entries=$(crontab -l | grep 'ionet')
    if [[ -z "$autopilot_entries" ]]; then
        echo -e "${RED}No AutoPilot schedules found or crontab is empty.${NC}"
    else
        echo -e "${GREEN}Listing AutoPilot Schedule...${NC}"
        echo "$autopilot_entries"
    fi
}


function deleteAutopilot {
    rm -f ionet-worker-autopilot*.sh 
    # Check if the autopilot script is scheduled in crontab
    if crontab -l | grep -q 'ionet'; then
        # Job found; proceed with deletion
        crontab -l | grep -v 'ionet' | crontab -
        echo -e "${GREEN}AutoPilot schedule deleted.${NC}"
    else
        # No job found; nothing to delete
        echo -e "${RED}No AutoPilot schedule found to delete.${NC}"
    fi
}


# Main Loop

while true; do
    echo "1 - Health Check"
    echo "2 - Re Install IONet"
    echo "3 - Remove ALL Deployment"
    echo "4 - AutoPilot Setup"
    echo "5 - More Options"
    echo "6 - Quit"

    echo -e "${GREEN}Select an option:${NC}"
    read option

    case $option in
        1) healthCheck ;;
        2) reinstallIONet ;;
        3) removeAllDeployment ;;
        4) autopilotSetup ;;
        6) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        5) 
           # Submenu for More Options
           while true; do
               echo "7 - Disable Energy Saver / Screen Saver"
               echo "8 - Rosetta Installation"
               echo "9 - Return to Main Menu"
               echo -e "${GREEN}Select an option:${NC}"
               read submenu_option

               case $submenu_option in
                   7) disableEnergySaver ;;
                   8) installRosetta ;;
                   9) break ;; # Exit the submenu loop to return to the main menu
                   *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
               esac
           done
           ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
done
