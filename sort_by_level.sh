#!/usr/bin/env bash

if ! command -v rg >/dev/null 2>&1; then
    echo "Error: \`rg\` (ripgrep) is required but not installed." >&2
    exit 1
fi

ROOT_DIR="."
OUTPUT_DIR="./output"

if [ -d "$OUTPUT_DIR" ]; then
    mv "$OUTPUT_DIR" "${OUTPUT_DIR}_bak$(date +%s)"
fi
mkdir -p "$OUTPUT_DIR"

for version_dir in "$ROOT_DIR"/*; do
    [ -d "$version_dir" ] || continue
    [ "$(basename "$version_dir")" = "output" ] && continue

    for song_dir in "$version_dir"/*; do
        [ -d "$song_dir" ] || continue
        echo "Working on $song_dir"
        maidata_file="$song_dir/maidata.txt"
        [ -f "$maidata_file" ] || continue


        for diff in 2 3 4 5 6; do
            level=$(rg --pcre2 -o "(?<=^&lv_${diff}=)[0-9]+" "$maidata_file" 2>/dev/null || true)
            if [ -z "$level" ]; then
                continue
            fi
            if [ "$level" -lt 12 ]; then
                continue
            fi
            # Skip if level is greater than 12, uncomment to use
            # if [ "$level" -gt 12 ]; then
            #     continue
            # fi

            dest_level="$level"
            if [ "$level" = "13" ] || [ "$level" = "14" ]; then
                decimal=$(rg --pcre2 -o "(?<=^&lv_${diff}=${level}\.)[0-9]+" "$maidata_file" 2>/dev/null || true)
                if [ -n "$decimal" ]; then
                    first_decimal_digit="${decimal:0:1}"
                    if [ "$first_decimal_digit" -ge 6 ] 2>/dev/null; then
                        dest_level="${level}+"
                    fi
                fi
            fi

            mkdir -p "$OUTPUT_DIR/$dest_level"
            cp -r "$song_dir" "$OUTPUT_DIR/$dest_level/"
        done

        # handle Utage charts (`&lv_7`)
        # ignore by default, uncomment to sort
        # utage=$(rg --pcre2 -o "(?<=^&lv_7=).+" "$maidata_file" 2>/dev/null || true)
        # if [ -n "$utage" ]; then
        #     mkdir -p "$OUTPUT_DIR/utage"
        #     cp -r "$song_dir" "$OUTPUT_DIR/utage/"
        # fi
    done
done

echo "Sorting complete. Check $OUTPUT_DIR/"
