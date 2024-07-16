FROM mcr.microsoft.com/windows/server:ltsc2022

# configure powershell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'Continue';"]; \
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned; \
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Internet Explorer\Main' -Name "DisableFirstRunCustomize" -Value 2;

WORKDIR c:/

# install netfree cert
RUN Invoke-WebRequest 'http://netfree.link/netfree-ca.crt' -OutFile 'netfree-ca.crt'; \
    Import-Certificate -FilePath "c:\netfree-ca.crt" -CertStoreLocation Cert:\LocalMachine\Root

# install git
RUN Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/download/v2.45.2.windows.1/Git-2.45.2-64-bit.exe' -OutFile 'Git-Installer.exe'; \
    Start-Process Git-Installer.exe -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=""icons,ext\reg\shellhere,assoc,assoc_sh""' -Wait; \
    $env:PATH += ';C:\Program Files\Git\bin'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine'); \
    #configure git to trust system certs (for netfree)
    git config --global http.sslBackend schannel; \
    # test, if something fail remove this line
    git config --system core.longpaths true; \
    Remove-Item Git-Installer.exe;

# install msvc
RUN Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile 'vs_buildtools.exe'; \
    Start-Process vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --includeRecommended \ 
    --add Microsoft.Component.MSBuild \
    --add Microsoft.VisualStudio.Workload.VCTools\
    #--add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 \
    --add Microsoft.VisualStudio.Component.VC.140' -Wait; \
    Remove-Item vs_buildtools.exe; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';c:/program files (x86)/Microsoft Visual Studio/2022/BuildTools/msbuild/current/bin', 'Machine');

# install python
RUN Invoke-WebRequest 'https://www.python.org/ftp/python/3.12.4/python-3.12.4-amd64.exe' -OutFile 'python-installer.exe'; \
    Start-Process python-installer.exe -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait; \
    Remove-Item python-installer.exe; \
    $env:PATH += ';c:/users/ContainerAdministrator/appdata/local/programs/python/Python312'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine'); \
    # configure netfree cert for pip
    pip config set global.cert "C:\netfree-ca.crt";

# install LLVM
RUN Invoke-WebRequest 'https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.2/LLVM-15.0.2-win64.exe' -OutFile 'llvm-installer.exe'; \
    Start-Process llvm-installer.exe -ArgumentList '/S' -Wait; \
    Remove-Item llvm-installer.exe; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path + ';c:/program files/llvm/bin', 'Machine'); \
    [Environment]::SetEnvironmentVariable('LIBCLANG_PATH', 'c:/program files/llvm/bin', 'Machine');

# install rust-tools
RUN Invoke-WebRequest 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe' -OutFile 'rustup-init.exe'; \
    Start-Process rustup-init.exe -ArgumentList '-q -y' -Wait; \
    Remove-Item rustup-init.exe; \
    $env:PATH += ';~/.cargo/bin'; \
    rustup component add rustfmt;
    #cargo install flutter_rust_bridge_codegen --version 1.80.1 --features "uuid";

#install flutter
RUN Invoke-WebRequest 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.6-stable.zip' -OutFile 'flutter_windows.zip'; \
    Expand-Archive -Path flutter_windows.zip -Destination .; \
    Remove-Item flutter_windows.zip; \
    $env:PATH += ';C:\flutter\bin'; \
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine');

# clone and compile RustDeskTempTopMostWindow
RUN git clone https://github.com/rustdesk-org/RustDeskTempTopMostWindow RustDeskTempTopMostWindow; \
    cd RustDeskTempTopMostWindow; git checkout 53b548a5398624f7149a382000397993542ad796; \
    msbuild WindowInjection/WindowInjection.vcxproj -p:Configuration=Release -p:Platform=x64 /p:TargetVersion=Windows10; \
    cd ..; cp RustDeskTempTopMostWindow/WindowInjection/x64/Release/WindowInjection.dll .; \
    Remove-Item RustDeskTempTopMostWindow;

#install vcpkg
RUN git clone https://github.com/microsoft/vcpkg; \
    cd vcpkg; git checkout f7423ee180c4b7f40d43402c2feb3859161ef625; cd ..; \
    ./vcpkg/bootstrap-vcpkg.bat; \
    [Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:/vcpkg', 'Machine');

# clone rustdesk for some restore and cache operations
RUN git clone https://github.com/rustdesk/rustdesk.git; \
    # init flutter cache
    cd rustdesk; Push-Location flutter; flutter pub get; Pop-Location; \
    ~/.cargo/bin/flutter_rust_bridge_codegen --rust-input ./src/flutter_ffi.rs --dart-output ./flutter/lib/generated_bridge.dart; \
    cd ..; \
    # init vcpkg packages
    . $env:VCPKG_ROOT/vcpkg.exe install --triplet x64-windows-static --x-install-root=""$env:VCPKG_ROOT/installed"";

CMD ["powershell"]