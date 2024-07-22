FROM mcr.microsoft.com/windows/servercore:ltsc2022

ENV GIT_VERSION=2.45.2
ENV PYTHON_VERSION=3.12.4
ENV LLVM_VERSION=15.0.6
ENV FLUTTER_VERSION=3.19.6
ENV VCPKG_COMMIT=f7423ee180c4b7f40d43402c2feb3859161ef625
ENV FLUTTER_RUST_BRIDGE_VERSION=1.80.1

ARG NETFREE=false

# configure powershell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]; \
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned; \
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main' -Name "DisableFirstRunCustomize" -Value 2;

WORKDIR c:/

# install netfree cert
RUN if ( $env:NETFREE -eq 'true' ) \
    { \
        Invoke-WebRequest 'http://netfree.link/netfree-ca.crt' -OutFile 'netfree-ca.crt'; \
        Import-Certificate -FilePath "c:\netfree-ca.crt" -CertStoreLocation Cert:\LocalMachine\Root; \
    }

# install git
RUN Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v$env:GIT_VERSION.windows.1/Git-$env:GIT_VERSION-64-bit.exe" -OutFile 'Git-Installer.exe'; \
    Start-Process Git-Installer.exe -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=""icons,ext\reg\shellhere,assoc,assoc_sh""' -Wait; \
    $env:PATH += ';C:\Program Files\Git\bin'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine'); \
    #configure git to trust system certs (for netfree)
    git config --global http.sslBackend schannel; \
    git config --system core.longpaths true; \
    git config --global --add safe.directory '*'; \
    Remove-Item Git-Installer.exe;

# install python
RUN Invoke-WebRequest "https://www.python.org/ftp/python/$env:PYTHON_VERSION/python-$env:PYTHON_VERSION-amd64.exe" -OutFile 'python-installer.exe'; \
    Start-Process python-installer.exe -ArgumentList '/quiet InstallAllUsers=0 PrependPath=1' -Wait; \
    Remove-Item python-installer.exe; \
    $env:PATH += ';c:/users/ContainerAdministrator/appdata/local/programs/python/Python312;c:/users/ContainerAdministrator/appdata/local/programs/python/Python312/Scripts'; \
    # configure netfree cert for pip
    if ( $env:NETFREE -eq 'true' ) \
    { \
        pip config set global.cert "C:\netfree-ca.crt"; \
    }

# install msvc
RUN Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile 'vs_buildtools.exe'; \
    Start-Process vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --includeRecommended \ 
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Workload.VCTools\
    --add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64' -Wait; \
    Remove-Item vs_buildtools.exe; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';c:/program files (x86)/Microsoft Visual Studio/2022/BuildTools/msbuild/current/bin', 'Machine');

#install LLVM
RUN Invoke-WebRequest "https://github.com/llvm/llvm-project/releases/download/llvmorg-$env:LLVM_VERSION/LLVM-$env:LLVM_VERSION-win64.exe" -OutFile 'llvm-installer.exe'; \
    Start-Process llvm-installer.exe -ArgumentList '/S' -Wait; \
    Remove-Item llvm-installer.exe; \
    [Environment]::SetEnvironmentVariable('LIBCLANG_PATH', 'C:/program files/llvm/bin', 'Machine');

#install flutter
RUN Invoke-WebRequest "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$env:FLUTTER_VERSION-stable.zip" -OutFile 'flutter_windows.zip'; \
    Expand-Archive -Path flutter_windows.zip -Destination .; \
    Remove-Item flutter_windows.zip; \
    $env:PATH += ';C:\flutter\bin'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine');

#install vcpkg
RUN git clone https://github.com/microsoft/vcpkg; \
    cd vcpkg; git checkout $env:VCPKG_COMMIT; cd ..; \
    ./vcpkg/bootstrap-vcpkg.bat; \
    [Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:/vcpkg', 'Machine');

# install rust-tools
RUN Invoke-WebRequest 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile 'rustup-init.exe'; \
    Start-Process rustup-init.exe -ArgumentList '-q -y' -Wait; \
    Remove-Item rustup-init.exe; \
    $env:PATH += ';C:\Users\ContainerAdministrator\.cargo\bin'; \
    cargo install flutter_rust_bridge_codegen --version $env:FLUTTER_RUST_BRIDGE_VERSION --features "uuid";

# clone, compile and extract WindowInjection.dll of RustDeskTempTopMostWindow
RUN git clone https://github.com/rustdesk-org/RustDeskTempTopMostWindow RustDeskTempTopMostWindow; \
    cd RustDeskTempTopMostWindow; git checkout 53b548a5398624f7149a382000397993542ad796; \
    msbuild WindowInjection/WindowInjection.vcxproj -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10; \
    cd ..; cp RustDeskTempTopMostWindow/WindowInjection/x64/Release/WindowInjection.dll .; \
    Remove-Item RustDeskTempTopMostWindow -Recurse -Force;

# clone rustdesk for some restore and cache operations
RUN git clone https://github.com/rustdesk/rustdesk.git; \
    cd rustdesk; \
    Push-Location flutter; flutter pub get; Pop-Location; \
    ~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart; \
    . $env:VCPKG_ROOT/vcpkg.exe install --triplet x64-windows-static --x-install-root=""$env:VCPKG_ROOT/installed""; \
    cd ..; \
    Remove-Item rustdesk -Force -Recurse;

COPY entrypoint.ps1 ./

WORKDIR C:/rustdesk

ENTRYPOINT [ "powershell", "C:/entrypoint.ps1" ]