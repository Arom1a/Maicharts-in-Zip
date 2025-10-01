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

            # handling 13+ and 14+
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
        utage=$(rg --pcre2 -o "(?<=^&lv_7=).+" "$maidata_file" 2>/dev/null || true)
        if [ -n "$utage" ]; then
            mkdir -p "$OUTPUT_DIR/utage"
            cp -r "$song_dir" "$OUTPUT_DIR/utage/"
        fi
    done
done

echo "Sorting complete. Check $OUTPUT_DIR/"
