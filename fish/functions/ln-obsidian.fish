function ln-obsidian --description 'Link file to Zettelkasten References'
    if test -z "$argv[1]"
        echo "Usage: ln-obsidian <file>"
        return 1
    end

    set source_file (realpath $argv[1])
    set filename (basename $source_file)
    set extension (string match -r '\.[^.]+$' $filename)
    set basename_no_ext (string replace -r '\.[^.]+$' '' $filename)

    set dest_filename "$basename_no_ext-linked$extension"
    set dest_path /home/ncasatti/Documents/Zettelkasten/References/docs/$dest_filename

    ln $source_file $dest_path
    echo "Linked $filename -> Zettelkasten/References/docs/$dest_filename"
end
