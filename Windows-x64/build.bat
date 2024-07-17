@echo OFF

if "%1" == "-netfree" if "%2" == "-no-cache" (
    echo "building with netfree cert without cache......"
    docker build --build-arg "NETFREE=true" --no-cache -t rustdesk-windows-x64 -m 4GB .
    exit
)

if "%1" == "-netfree" (
    echo "building with netfree cert..."
    docker build --build-arg "NETFREE=true" -t rustdesk-windows-x64 -m 4GB .
    exit
) else (
    echo "building..."
    docker build -t rustdesk-windows-x64 -m 4GB .
    exit
)