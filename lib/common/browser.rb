def browser(url)
     if $ec2_main.settings.get_system('EXTERNAL_BROWSER') != nil and $ec2_main.settings.get_system('EXTERNAL_BROWSER') != ""
        if RUBY_PLATFORM.index("mswin") != nil or RUBY_PLATFORM.index("i386-mingw32") != nil
           c = "cmd.exe /c \@start \"\" /b \""+$ec2_main.settings.get_system('EXTERNAL_BROWSER')+"\"  "+url
           puts c
           system(c)
        else
           c = $ec2_main.settings.get_system('EXTERNAL_BROWSER')+" "+url
           puts c
           system(c)
        end
     else
        error_message("Error","No External Browser in Settings")
     end
end     
