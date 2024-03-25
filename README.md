# IONet Worker Management Script

This script offers a comprehensive solution for managing IONet Workers on macOS, focusing on ease of use and automation. It includes functionalities such as health checks, binary reinstallation, Docker cleanup, energy saver adjustments, Rosetta 2 installation, and an AutoPilot setup for routine maintenance.

## Features

- **Health Check**: Verifies the operational status of IONet Workers.
- **ReInstall IONet Binary**: Downloads and sets up the latest IONet Binary.
- **ReInstall IONet Worker**: Cleans existing Docker components and reinstalls the IONet Worker.
- **Remove ALL Deployment**: Clears all Docker components, including containers, images, and volumes.
- **Disable Energy Saver / Screen Saver**: Adjusts macOS settings to optimize IONet Worker performance.
- **Rosetta Installation**: Installs Rosetta 2 for compatibility with Intel-based applications on M1 chips.
- **AutoPilot Setup**: Schedules routine operations to ensure IONet Workers remain operational.

## Getting Started

### Prerequisites

- Docker installed on your macOS system.
- `curl` for downloading the script.

### Installation

1. **Download the script** using `curl`:

   ```sh
   curl -o ionet-management.sh https://raw.githubusercontent.com/your-username/repository-name/main/ionet-management.sh


2. **Make the script executable** using :

   ```sh
   chmod +x ionet-management.sh

###  Usage
Simply run the script with the following command:

   ```sh
   ./ionet-management.sh
```

### Contributing
Feel free to contribute to the development of this script. Please adhere to the project's contribution guidelines specified in CONTRIBUTING.md.

### License
This project is licensed under the MIT License - see the LICENSE file for details.

### Acknowledgments
Thanks to the IONet community for their support and feedback.
This script was created to help automate the management and maintenance of IONet Workers on macOS.
