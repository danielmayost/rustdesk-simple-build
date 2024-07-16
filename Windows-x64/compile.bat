docker run --rm -it -m 4GB ^
-e RENDEZVOUS_SERVER=control-dm-server.online ^
-v .\..\rustdesk:C:/src-rustdesk ^
-v .\output:C:\output ^
rustdesk-windows-x64