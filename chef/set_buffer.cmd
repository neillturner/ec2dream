:: escape the environment variable in the key name
set mySysRoot=%%SystemRoot%%

:: 655294544 equals 9999 lines in the GUI
reg.exe add "HKCU\Console\%mySysRoot%_system32_cmd.exe" /v ScreenBufferSize /t REG_DWORD /d 655294544 /f

:: We also need to change the Window Height, 3276880 = 50 lines
reg.exe add "HKCU\Console\%mySysRoot%_system32_cmd.exe" /v WindowSize /t REG_DWORD /d 3276880 /f