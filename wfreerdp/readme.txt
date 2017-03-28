FreeRDP - A Free Remote Desktop Protocol Implementation

See www.freerdp.com for more information

Usage: xfreerdp [file] [options] [/v:<server>[:port]]
Syntax:

/flag (enables flag)
/option:<value> (specifies option with value)
+toggle -toggle (enables or disables toggle, where '/' is a synonym of '+')

/v:<server>[:port]    Server hostname
/port:<number>        Server port
/w:<width>            Width
/h:<height>           Height
/size:<width>x<height>  Screen size
/f                    Fullscreen mode
/bpp:<depth>          Session bpp (color depth)
/kbd:0x<layout id> or <layout name> Keyboard layout
/kbd-list             List keyboard layouts
/kbd-type:<type id>   Keyboard type
/kbd-subtype:<subtype id> Keyboard subtype
/kbd-fn-key:<function key count>  Keyboard function key count
/admin                Admin (or console) session
/multimon             Multi-monitor
/workarea             Work area
/t:<title>            Window title
+decorations (default:off)  Window decorations
/a                    Addin
/vc                   Static virtual channel
/dvc                  Dynamic virtual channel
/u:[<domain>\\]<user> or <user>[@<domain>]  Username
/p:<password>         Password
/d:<domain>           Domain
/g:<gateway>[:port]   Gateway Hostname
/gu:[<domain>\\]<user> or <user>[@<domain>] Gateway username
/gp:<password>        Gateway password
/gd:<domain>          Gateway domain
/app:||<alias> or <executable path> Remote application program
/app-name:<app name>  Remote application name for user interface
/app-icon:<icon path> Remote application icon for user interface
/app-cmd:<parameters> Remote application command-line parameters
/app-file:<file name> File to open with remote application
/app-guid:<app guid>  Remote application GUID
+compression (default:off)  Compression
/shell                Alternate shell
/shell-dir            Shell working directory
/audio-mode           Audio output mode
/mic                  Audio input (microphone)
/network              Network connection type
+clipboard (default:off)  Redirect clipboard
+fonts (default:off)  Smooth fonts (cleartype)
+aero (default:off)   Desktop composition
+window-drag (default:off)  Full window drag
+menu-anims (default:off) Menu animations
-themes (default:on)  Themes
-wallpaper (default:on) Wallpaper
/gdi:<sw|hw>          GDI rendering
/rfx                  RemoteFX
/rfx-mode:<image|video> RemoteFX mode
/frame-ack:<number>   Frame acknowledgement
/nsc                  NSCodec
/jpeg                 JPEG codec
/jpeg-quality:<percentage>  JPEG quality
-nego (default:on)    protocol security negotiation
/sec:<rdp|tls|nla|ext>  force specific protocol security
-sec-rdp (default:on) rdp protocol security
-sec-tls (default:on) tls protocol security
-sec-nla (default:on) nla protocol security
+sec-ext (default:off)  nla extended protocol security
/cert-name:<name>     certificate name
/cert-ignore          ignore certificate
/pcb:<blob>           Preconnection Blob
/pcid:<id>            Preconnection Id
/vmconnect:<vmid>     Hyper-V console (use port 2179, disable negotiation)
-authentication (default:on)  authentication (hack!)
-encryption (default:on)  encryption (hack!)
-grab-keyboard (default:on) grab keyboard
-mouse-motion (default:on)  mouse-motion
/parent-window:<window id>  Parent window id
-bitmap-cache (default:on)  bitmap cache
-offscreen-cache (default:on) offscreen bitmap cache
-glyph-cache (default:on) glyph cache
/codec-cache:<rfx|nsc|jpeg> bitmap codec cache
-fast-path (default:on) fast-path input/output
+async-input (default:off)  asynchronous input
+async-update (default:off) asynchronous update
/version              print version
/help                 print help
Examples:

xfreerdp connection.rdp /p:Pwd123! /f
xfreerdp /u:CONTOSO\\JohnDoe /p:Pwd123! /v:rdp.contoso.com
xfreerdp /u:JohnDoe /p:Pwd123! /w:1366 /h:768 /v:192.168.1.100:4489
xfreerdp /u:JohnDoe /p:Pwd123! /vmconnect:C824F53E-95D2-46C6-9A18-23A5BB403532 /v:192.168.1.100

Clipboard Redirection: +clipboard

Drive Redirection: /a:drive,home,/home
Smartcard Redirection: /a:smartcard,<device>
Printer Redirection: /a:printer,<device>,<driver>
Serial Port Redirection: /a:serial,<device>
Parallel Port Redirection: /a:parallel,<device>
Printer Redirection: /a:printer,<device>,<driver>

Audio Input Redirection: /dvc:audin,sys:alsa
Audio Output Redirection: /vc:rdpsnd,sys:alsa

Multimedia Redirection: /dvc:tsmf,sys:alsa
USB Device Redirection: /dvc:urbdrc,id,dev:054c:0268