#!/bin/sh

# path:   /home/klassiker/.local/share/repos/compressor/compressor.sh
# author: klassiker [mrdotx]
# github: https://github.com/mrdotx/compressor
# date:   2023-05-03T19:19:45+0200

check() {
    tools="7z bzip2 ghostscript gzip tar unrar unzip xz zip zstd "

    printf "\n"
    for tool in $tools; do
        if command -v "$tool" > /dev/null 2>&1; then
            printf "      [X] %s\n" "$tool"
        else
            printf "      [ ] %s\n" "$tool"
        fi
    done
}

script=$(basename "$0")
help="$script [-h/--help] -- script to compress/extract files and folders
  Usage:
    $script [--add] <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, tar.bz2, tar.gz, tar.xz, tar.zst, tbz2, tgz, txz, zip

    $script <path/file>.<ext> [path/file1.ext] [path/file2.ext]
      <ext>: 7z, apk, arj, bz2, cab, cb7, cbr, cbt, cbz, chm, deb, dmg, epub,
             exe, gz, iso, lzh, lzma, msi, pkg, rar, rpm, tar, tar.bz2, tar.gz,
             tar.xz, tar.zst, tbz2, tgz, txz, udf, wim, xar, xz, z, zip

    $script [--pdf] <quality> <path/file>.pdf [path/file1.pdf] [path/file2.pdf]
      <quality>: screen, ebook, printer, prepress, default

  Settings:
    [--add] = compress files to archive
    [--pdf] = compress pdf files with the following quality settings:
                screen   = low-resolution
                ebook    = medium-resolution
                printer  = high-resolution
                prepress = very high-resolution
                default  = useful across a wide variety of uses
                           (possible larger file size)
              (if no quality settings are specified, \"default\" is used)

  Examples:
    $script file1.tar.gz file2.tar.bz2 file3.7z
    $script --add archive.tar.gz file1.ext file2.ext file3.ext
    $script --pdf ebook document1.pdf document2.pdf document3.pdf

  Programs:
    required tools for full functionality: $(check)
    tools marked with an X are installed"

compress() {
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
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            base="$(printf "%s" "${archive##*/}" \
                    | tr '[:upper:]' '[:lower:]')"
            folder="${base%.*}"
            case "$base" in
                *.7z | *.apk | *.arj | *.cab | *.cb7 | *.chm | *.deb | *.dmg \
                    | *.exe | *.iso | *.lzh | *.msi | *.pkg | *.rpm | *.udf \
                    | *.wim | *.xar)
                    printf "7z x \"%s\" -o\"%s\"\n" "$archive" "$folder" \
                        && mkdir -p "$folder" \
                        && 7z x "$archive" -o"$folder" >/dev/null 2>&1 &
                    ;;
                *.tar | *.tar.gz | *.tgz | *.tar.bz2 | *.tbz2 | *.tar.xz \
                    | *.txz | *.tar.zst | *.cbt)
                    folder="${folder%%.tar}"
                    printf "tar xvf \"%s\" -C \"%s\"\n" "$archive" "$folder"\
                        && mkdir -p "$folder" \
                        && tar xvf "$archive" -C "$folder" >/dev/null 2>&1 &
                    ;;
                *.zip | *.epub | *.cbz)
                    printf "unzip \"%s\" -d \"%s\"\n" "$archive" "$folder" \
                        && mkdir -p "$folder" \
                        && unzip "$archive" -d "$folder" >/dev/null 2>&1 &
                    ;;
                *.bz2)
                    printf "bunzip2 \"%s\"\n" "$archive" \
                        && bunzip2 "$archive" >/dev/null 2>&1 &
                    ;;
                *.gz)
                    printf "gunzip \"%s\"\n" "$archive" \
                        && gunzip "$archive" >/dev/null 2>&1 &
                    ;;
                *.lzma)
                    printf "unlzma \"%s\"\n" "$archive" \
                        && unlzma "$archive" >/dev/null 2>&1 &
                    ;;
                *.rar | *.cbr)
                    printf "unrar x -ad \"%s\"\n" "$archive" \
                        && unrar x -ad "$archive" >/dev/null 2>&1 &
                    ;;
                *.xz)
                    printf "unxz \"%s\"\n" "$archive" \
                        && unxz "$archive" >/dev/null 2>&1 &
                    ;;
                *.z)
                    printf "uncompress \"%s\"\n" "$archive" \
                        && uncompress "$archive" >/dev/null 2>&1 &
                    ;;
                *)
                    printf "extract \"%s\": unknown archive method\n" "$archive"
                    exit 1
                    ;;
            esac
        else
            printf "extract \"%s\": file does not exist\n" "$archive"
            exit 1
        fi
    done

    # wait for completion of the extraction processes
    processes="bdstar gunzip bunzip2 unxz unzlma uncompress unzip unrar 7z"

    wait_for() {
        for process in $1; do
            pgrep -x "$process" >/dev/null \
                && return 0
        done
    }

    while wait_for "$processes" ; do
        sleep 1
    done

    printf "processes completed\n"
}

compress_pdf() {
    case $1 in
        screen | ebook | printer | prepress | default)
            quality="$1"
            shift
            ;;
        *)
            quality="default"
            ;;
    esac

    for document in "$@"; do
        ghostscript \
            -sDEVICE=pdfwrite \
            -dPDFSETTINGS=/"$quality" \
            -dPrinted=false \
            -dNOPAUSE \
            -dBATCH \
            -sOutputFile="$(basename "$document" .pdf)-$quality.pdf" \
            "$document"
    done
}

case "$1" in
    -h | --help | "")
        printf "%s\n" "$help"
        ;;
    --add)
        shift
        compress "$@"
        ;;
    --pdf)
        shift
        compress_pdf "$@"
        ;;
    *)
        extract "$@"
        ;;
esac
