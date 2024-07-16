@echo OFF

if %1 == -netfree (
    docker build --build-arg "NETFREE=true" -t rustdesk-windows-x64 -m 4GB .
) else (
    docker build -t rustdesk-windows-x64 -m 4GB .
)