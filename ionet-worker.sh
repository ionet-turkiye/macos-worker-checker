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
    
    if [ "$use_existing_command" == "yes" ]; then
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
        return 1
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

    # Proceed to schedule if no existing job is found
    local script_path="$(pwd)/ionet-worker-autopilot.sh"
    if [ ! -f "$script_path" ]; then
        # Create the autopilot script if it doesn't exist
        echo -e "${GREEN}Creating AutoPilot script at $script_path${NC}"
        echo "#!/bin/bash" > "$script_path"
        echo "cd $(pwd)" >> "$script_path"
        echo "bash $(pwd)/your_health_check_and_redeploy_script.sh" >> "$script_path"
        chmod +x "$script_path"
    fi

    (crontab -l 2>/dev/null; echo "*/$minutes * * * * $script_path") | crontab -
    echo -e "${GREEN}AutoPilot scheduled every $minutes minutes.${NC}"
}


function listAutopilot {
    echo -e "${GREEN}Listing AutoPilot Schedule...${NC}"
    crontab -l | grep 'ionet-worker-autopilot.sh'
}

function deleteAutopilot {
    crontab -l | grep -v 'ionet-worker-autopilot.sh' | crontab -
    echo -e "${GREEN}AutoPilot schedule deleted.${NC}"
}

# Main Loop

while true; do
    echo "1 - Health Check"
    echo "2 - ReInstall IONet Binary"
    echo "3 - ReInstall IONet Worker"
    echo "4 - Remove ALL Deployment"
    echo "5 - Disable Energy Saver / Screen Saver"
    echo "6 - Rosetta Installation"
    echo "7 - AutoPilot Setup"
    echo "8 - Quit"
    echo -e "${GREEN}Select an option:${NC}"
    read option

    case $option in
        1) healthCheck ;;
        2) reinstallIONetBinary ;;
        3) reinstallIONetWorker ;;
        4) removeAllDeployment ;;
        5) disableEnergySaver ;;
        6) installRosetta ;;
        7) autopilotSetup ;;
        8) echo -e "${GREEN}Exiting...${NC}"; exit 0 ;;
        *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
    esac
done
