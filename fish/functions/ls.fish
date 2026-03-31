function ls --description 'List files (eza long)'
    eza -lah --icons --color=always --group-directories-first $argv
end
