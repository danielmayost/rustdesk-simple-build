$ErrorActionPreference = 'Stop';
$ProgressPreference = 'SilentlyContinue';

# build rustdesk
Invoke-WebRequest -Uri https://github.com/rustdesk-org/rdev/releases/download/usbmmidd_v2/usbmmidd_v2.zip -OutFile usbmmidd_v2.zip;
Expand-Archive usbmmidd_v2.zip -DestinationPath .;
python .\build.py --portable --hwcodec --flutter --vram --skip-portable-pack;
Remove-Item -Path usbmmidd_v2\Win32 -Recurse;
Remove-Item -Path "usbmmidd_v2\deviceinstaller64.exe", "usbmmidd_v2\deviceinstaller.exe", "usbmmidd_v2\usbmmidd.bat";
mv ./flutter/build/windows/x64/runner/Release ./rustdesk;
mv -Force .\usbmmidd_v2 ./rustdesk;

# pack self-extracted executable
Set-Alias -Name sed -Value C:\"Program Files"\Git\usr\bin\sed.exe;
Copy-Item "C:\WindowInjection.dll" -Destination "./rustdesk" -Force;
sed -i '/dpiAware/d' res/manifest.xml;
pushd ./libs/portable;
pip install -r requirements.txt;
python ./generate.py -f ../../rustdesk/ -o . -e ../../rustdesk/rustdesk.exe;
popd;
mv ./target/release/rustdesk-portable-packer.exe ../output/rustdesk.exe -Force;