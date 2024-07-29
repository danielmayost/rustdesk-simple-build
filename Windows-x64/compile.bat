mkdir output

docker run --rm -m 10GB ^
-v .\..\rustdesk:C:/src-rustdesk ^
-v .\output:C:\output ^
rustdesk-windows-x64