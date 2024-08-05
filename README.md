# Mini Shell for ARM 32-bit Architecture

## Description
This is a simple shell program for `ARM 32-bit` architecture, written in `ARM assembly` language. The shell reads user input, parses commands and arguments, forks child processes to execute commands using execve, and waits for the child processes to complete.


## Features

**Command Parsing**
- Parses user input to extract commands and arguments.
 
**Fork and Exec**
- Uses fork to create child processes and execve to execute commands.

**Wait for Completion**
- Parent process waits for child processes to complete before accepting new commands.
  
**Memory Management**
- Clears argument buffers before parsing new commands to prevent data corruption.

## System Calls
The system calls used in this program(arm-32 bit EABI) follow the standards of [Linux 4.14.0 headers](https://chromium.googlesource.com/chromiumos/docs/+/master/constants/syscalls.md#arm-32_bit_EABI).

  
## Uasge

### For Non ARM Native

1. **Install the Required Tools**
   ```bash
   sudo apt install build-essential gcc-arm-linux-gnueabihf qemu-user
   ```
2. **Compile the Program**
   ```bash
   arm-linux-gnueabihf-gcc -o miniShell miniShell.s -static -nonstdlib
   ```
3. **Run the Program**
   ```bash
   qemu-arm ./miniShell.s
   ```

   
### For Non ARM Native

1. **Install the Required Tools**
   ```bash
   sudo apt install build-essential
   ```
2. **Compile the Program**
   ```bash
   gcc -o miniShell miniShell.s -static -nonstdlib
   ```
3. **Run the Program**
   ```bash
   ./miniShell.s
   ```


## Contributing
Contributions to the system are welcome! Please fork the repository and submit a pull request with your enhancements.

## License
This project is licensed under the MIT License - see the [MIT License Documentation](https://opensource.org/licenses/MIT) for details.

## Contact
For support, please feel free to contact me.
