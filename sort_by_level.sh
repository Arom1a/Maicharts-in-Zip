#!/usr/bin/env bash

# Root directory containing all version folders
ROOT_DIR="."
OUTPUT_DIR="./output"

# Detect if output dir exists;
# if exists, mv it to output_bak<unix_time_stamp>
if [ -d "$OUTPUT_DIR" ]; then
    mv "$OUTPUT_DIR" "${OUTPUT_DIR}_bak$(date +%s)"
fi
mkdir -p "$OUTPUT_DIR"

for version_dir in "$ROOT_DIR"/*; do
    # Check if is dir
    [ -d "$version_dir" ] || continue
    # Check if is output dir
    [ "$(basename "$version_dir")" = "output" ] && continue

    for song_dir in "$version_dir"/*; do
        # Check if is dir
        [ -d "$song_dir" ] || continue

        echo "Working on $song_dir"
        maidata_file="$song_dir/maidata.txt"
        # Check if is file
        [ -f "$maidata_file" ] || continue

        # Extract difficulty 2-6 (what is `&lv_1`???)
        for diff in 2 3 4 5 6; do
            level=$(rg --pcre2 -o "(?<=^&lv_${diff}=)[0-9]+" "$maidata_file" 2>/dev/null || true)
            if [ -z "$level" ]; then
                continue
            fi
            if [ -n "$level" ]; then
                mkdir -p "$OUTPUT_DIR/$level"
                cp -r "$song_dir" "$OUTPUT_DIR/$level/"
            fi
        done
    done
done

echo "Sorting complete. Check $OUTPUT_DIR/"
