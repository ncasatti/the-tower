function record-screen --description 'Record a screen selection to a file'
    if test -z "$argv[1]"
        echo "Usage: record-screen <filename>"
        return 1
    end

    wf-recorder -g "$(slurp)" -f "$argv[1].mp4"
end

function record-gif --description 'Record a screen selection and convert to gif'
    if test -z "$argv[1]"
        echo "Usage: record-screen-gif <filename>"
        return 1
    end

    set output_gif "$argv[1].gif"
    set temp_mp4 "temp_recording.mp4"

    wf-recorder -g "$(slurp)" -f "$temp_mp4"

    ffmpeg -i "$temp_mp4" -vf "fps=15,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$output_gif"

    rm "$temp_mp4"
end
