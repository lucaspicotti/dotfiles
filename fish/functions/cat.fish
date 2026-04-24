function cat
    if isatty stdout
        bat --paging=never $argv
    else
        command cat $argv
    end
end
