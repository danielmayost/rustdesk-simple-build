# Rustdesk Simple Build
**Rustdesk** compilation (especially for windows) is a complex process and requires a lot of dependencies and configurations.

In this repository I tried to simplify the process as much as possible so that it is possible to make changes in the code or in the configurations and compile without messing with all the dependencies and things around.

## How it works?
**The process is divided into two stages:**

First, a Windows docker image is built with all the configuration dependencies needed for compilation, this is a one-time process, unless the source code dependencies change.

In the second step, we run the docker image with Rustdesk compilation instructions. 

### Local compilation
Unfortunately, the compilation cannot be done when the source code is connected to the container by Bind mounts, `cargo` encounters many errors in this situation, therefore the source code is copied into the container and there the compilation takes place, after which the files are transferred back to the source folder.

## Usage
**Note**: Please use Powershell, Otherwise, the commands will not execute properly.

Go to the folder you want to clone Rustdesk and use Powershell to run the following commands:
```
git clone https://github.com/danielmayost/rustdesk-simple-build.git
cd rustdesk-simple-build
git clone https://github.com/rustdesk/rustdesk.git
cd Windows-x64
./build
```

Then make changes to the code and run the following command:
```
./compile
```

The output will be in the output folder.

### Troubleshooting

