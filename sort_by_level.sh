#!/usr/bin/env bash

set -euo pipefail
rg || [ $? -ne 127 ]
ROOT_DIR="."
OUTPUT_DIR="${ROOT_DIR}/output"

# 1. make output dir available
if [ -e "${OUTPUT_DIR}" ]; then
    mv "${OUTPUT_DIR}" "${OUTPUT_DIR}_bak$(date +%s)"
fi
mkdir -p "${OUTPUT_DIR}"

# 2. get maidata paths
for version_dir in "${ROOT_DIR}"/*; do
    [ -d "${version_dir}" ] && \
    [ "$(basename "${version_dir}")" != "output" ] || continue

    for song_dir in "${version_dir}"/*; do
        [ -d "${song_dir}" ] # || exit 1

        echo -n "$(basename "${song_dir}") "
        maidata_file="${song_dir}/maidata.txt"
        [ -f "${maidata_file}" ] # || exit 1

        # 3. get rounded level
        for diff in 2 3 4 5 6; do
            leveln=$(rg --pcre2 -o "(?<=^&lv_${diff}=)[0-9.]+$" "${maidata_file}")
            [ -n "${leveln}" ] # || exit 1
            echo -n "${leveln} "
            int=${leveln%.*}
            frac=${leveln#*.}
            case ${frac} in
                [0-4]) level="${int}" ;;
                [5-9]) level="${int}+" ;;
                *) exit 1 ;;
            esac

            # 4. copy to destination
            echo -n "${level}"
            mkdir -p "${OUTPUT_DIR}/${level}"
            cp -r "${song_dir}" "${OUTPUT_DIR}/${level}/"
            echo "."
        done
    done
done

echo "Sorting complete. Check ${OUTPUT_DIR}/"
