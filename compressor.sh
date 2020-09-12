#!/bin/sh

# path:       /home/klassiker/.local/share/repos/compressor/compressor.sh
# author:     klassiker [mrdotx]
# github:     https://github.com/mrdotx/compressor
# date:       2020-09-12T14:01:07+0200

script=$(basename "$0")
help="$script [-h/--help] -- script to compress/extract files and folders
  Usage:
    $script [--check]

    $script [--add] <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, tar.bz2, tar.gz, tar.xz, tbz2, tgz, txz, zip

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
    $script file1.tar.gz file2.tar.bz2 file3.7z"

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -eq 0 ]; then
    printf "%s\n" "$help"
    exit 1
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
    shift
    archive="$1"
    shift
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
        *.zip)
            zip -r "$archive" "$@"
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
                *.7z | *.7Z \
                    | *.apk | *.APK \
                    | *.arj | *.ARJ \
                    | *.cab | *.CAB \
                    | *.cb7 | *.CB7 \
                    | *.chm | *.CHM \
                    | *.deb | *.DEB \
                    | *.dmg | *.DMG \
                    | *.iso | *.ISO \
                    | *.lzh | *.LZH \
                    | *.msi | *.MSI \
                    | *.pkg | *.PKG \
                    | *.rpm | *.RPM \
                    | *.udf | *.UDF \
                    | *.wim | *.WIM \
                    | *.xar | *.XAR)
                        mkdir -p "$name"
                        7z x ./"$archive" -o"$name"
                        ;;
                *.tar | *.TAR \
                    | *.tar.gz | *.TAR.GZ | *.tgz | *.TGZ \
                    | *.tar.bz2 | *.TAR.BZ2 | *.tbz2 | *.TBZ2 \
                    | *.tar.xz | *.TAR.XZ | *.txz | *.TXZ \
                    | *.cbt | *.CBT)
                        mkdir -p "$name"
                        tar xvf "$archive" -C "$name"
                        ;;
                *.zip | *.ZIP \
                    | *.epub | *.EPUB \
                    | *.cbz | *.CBZ)
                        mkdir -p "$name"
                        unzip ./"$archive" -d ./"$name"
                        ;;
                *.bz2 | *.BZ2)
                        bunzip2 ./"$archive"
                        ;;
                *.gz | *.GZ)
                        gunzip ./"$archive"
                        ;;
                *.lzma | *.LZMA)
                        unlzma ./"$archive"
                        ;;
                *.rar | *.RAR \
                    | *.cbr | *.CBR)
                        unrar x -ad ./"$archive"
                        ;;
                *.xz | *.XZ)
                        unxz ./"$archive"
                        ;;
                *.z | *.Z)
                        uncompress ./"$archive"
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
