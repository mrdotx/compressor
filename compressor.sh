#!/bin/sh

# path:   /home/klassiker/.local/share/repos/compressor/compressor.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/compressor
# date:   2021-01-15T13:30:50+0100

check() {
    used_tools="
        tar
        7z
        zip
        unzip
        unrar
        gzip
        bzip2
        xz"

    printf "required tools for full functionality. tools marked with an X are installed\n"

    printf "%s\n" "$used_tools" | {
        while IFS= read -r line; do
            [ -n "$line" ] \
                && line=$(printf "%s" "$line" \
                    | sed 's/ //g') \
                &&  if command -v "$line" > /dev/null 2>&1; then
                        printf "      [X] %s\n" "$line"
                    else
                        printf "      [ ] %s\n" "$line"
                    fi
        done
    }
}

script=$(basename "$0")
help="$script [-h/--help] -- script to compress/extract files and folders
  Usage:
    $script [--add] <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, tar.bz2, tar.gz, tar.xz, tar.zst, tbz2, tgz, txz, zip

    $script <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, apk, arj, bz2, cab, cb7, cbr, cbt, cbz, chm, deb, dmg, epub,
             gz, iso, lzh, lzma, msi, pkg, rar, rpm, tar, tar.bz2, tar.gz,
             tar.xz, tar.zst, tbz2, tgz, txz, udf, wim, xar, xz, z, zip

  Settings:
    [--add] = compress files to archive

  Examples:
    $script --add archive.tar.gz file1.ext file2.ext file3.ext
    $script file1.tar.gz file2.tar.bz2 file3.7z

  Programs:
    $(check)"

compress() {
    case "$archive" in
        *.7z)
            7z a "$archive" "$@"
            ;;
        *.tar.bz2 | *.tbz2)
            tar cfvj "$archive" "$@"
            ;;
        *.tar.gz | *.tgz)
            tar cfvz "$archive" "$@"
            ;;
        *.tar.xz | *.txz)
            tar cfvJ "$archive" "$@"
            ;;
        *.tar.zst)
            tar cfv "$archive" "$@" --zstd
            ;;
        *.zip)
            zip -r "$archive" "$@"
            ;;
        *)
            printf "compress: unknown extension\n"
            exit 1
            ;;
    esac
}

extract() {
    for archive in "$@"
    do
        if [ -f "$archive" ]; then
            base="$(printf "%s" "${archive##*/}" \
                    | tr '[:upper:]' '[:lower:]')"
            name="${base%%.*}"
            case "$base" in
                *.7z | *.apk | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg \
                    | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf | *.wim \
                    | *.xar)
                        mkdir -p "$name"
                        7z x "$archive" -o"$name"
                        ;;
                *.tar | *.tar.gz | *.tgz | *.tar.bz2 | *.tbz2 | *.tar.xz \
                    | *.txz | *.tar.zst | *.cbt)
                        mkdir -p "$name"
                        tar xvf "$archive" -C "$name"
                        ;;
                *.zip | *.epub | *.cbz)
                    mkdir -p "$name"
                    unzip "$archive" -d "$name"
                    ;;
                *.bz2)
                    bunzip2 "$archive"
                    ;;
                *.gz)
                    gunzip "$archive"
                    ;;
                *.lzma)
                    unlzma "$archive"
                    ;;
                *.rar | *.cbr)
                    unrar x -ad "$archive"
                    ;;
                *.xz)
                    unxz "$archive"
                    ;;
                *.z)
                    uncompress "$archive"
                    ;;
                *)
                    printf "extract: '%s' - unknown archive method\n" "$archive"
                    exit 1
                    ;;
            esac
        else
            printf "extract: '%s' - file does not exist" "$archive"
            exit 1
        fi
    done
}


case "$1" in
    -h | --help)
        printf "%s\n" "$help"
        ;;
    --add)
        shift
        archive="$1"
        shift
        compress "$@"
        ;;
    *)
        if [ $# -eq 0 ]; then
            printf "%s\n" "$help"
            exit 1
        else
            extract "$@"
        fi
        ;;
esac
