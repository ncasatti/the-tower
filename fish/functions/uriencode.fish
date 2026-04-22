function uriencode --description 'Percent-encode a string for URIs'
    if test -z "$argv[1]"
        echo "Usage: uriencode <string>"
        return 1
    end

    python3 -c "import urllib.parse; print(urllib.parse.quote('$argv[1]', safe=''))"
end
