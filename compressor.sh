#!/bin/sh

# path:       /home/klassiker/.local/share/repos/compressor/compressor.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/compressor
# date:       2020-09-11T19:27:40+0200

script=$(basename "$0")
help="$script [-h/--help] -- script to compress/extract files and folders
  Usage:
    $script [--check]

    $script [--add] <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, tar.bz2, tar.gz, zip

    $script <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, apk, arj, bz2, cab, cb7, cbr, cbt, cbz, chm, deb, dmg,
             epub, gz, iso, lzh, lzma, msi, pkg, rar, rpm, tar, tar.bz2,
             tar.gz, tar.xz, tbz2, tgz, txz, udf, wim, xar, xz, z, zip

  Settings:
    [--check] = check if needed tools are installed
    [--add]   = compress files to archive

  Examples:
    $script --check
    $script --add archive.tar.gz file1.ext file2.ext file3.ext
    $script file1.tar.gz file2.tar.bz2 file3.7z file4.zip"

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then
    printf "%s\n" "$help"
elif [ "$1" = "--check" ]; then
    used_tools="
        tar
        7z
        zip
        unzip
        unrar
        gzip
        bzip2
        xz"

    printf "needed tools marked with X are installed"
    printf "\n--\n"

    printf "%s\n" "$used_tools" | {
        while IFS= read -r line
        do
            [ -n "$line" ] \
                && tool=$(printf "%s" "$line" | sed 's/ //g') \
                &&  if command -v "$tool" > /dev/null 2>&1; then
                        printf "  [X] %s\n" "$tool"
                    else
                        printf "  [ ] %s\n" "$tool"
                    fi
        done
    }
elif [ "$1" = "--add" ]; then
    option=$(printf "%s" "$*" \
        | sed 's/\-\-add//g' \
    )
    case "$2" in
        *.tar.gz)
            eval tar cfvz "$option"
            ;;
        *.tar.bz2)
            eval tar cfvj "$option"
            ;;
        *.7z)
            eval 7z a "$option"
            ;;
        *.zip)
            eval zip -r "$option"
            ;;
        *)
            printf "compress: no filename with known extension added\n"
            exit 1
            ;;
    esac
else
    for archive in "$@"
    do
        if [ -f "$archive" ] ; then
            base="${archive##*/}"
            name="${base%%.*}"
            case "$base" in
                *.tar|*.tar.gz|*.tar.bz2|*.tar.xz|*.tgz|*.tbz2|*.txz|*.cbt)
                    mkdir -p "$name"
                    tar xvf "$archive" -C "$name"
                    ;;
                *.7z|*.apk|*.arj|*.cab|*.cb7|*.chm|*.deb|*.dmg|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar)
                    mkdir -p "$name"
                    7z x ./"$archive" -o"$name"
                    ;;
                *.zip|*.cbz|*.epub)
                    mkdir -p "$name"
                    unzip ./"$archive" -d ./"$name"
                    ;;
                *.rar*|.cbr)
                    unrar x -ad ./"$archive"
                    ;;
                *.gz)
                    gunzip ./"$archive"
                    ;;
                *.z)
                    uncompress ./"$archive"
                    ;;
                *.lzma)
                    unlzma ./"$archive"
                    ;;
                *.bz2)
                    bunzip2 ./"$archive"
                    ;;
                *.xz)
                    unxz ./"$archive"
                    ;;
                *)
                    printf "extract: '%s' - unknown archive method\n" "$archive"
                    exit 1
                    ;;
                esac
            else
                printf "'%s' - file does not exist" "$archive"
                exit 1
            fi
    done
fi
