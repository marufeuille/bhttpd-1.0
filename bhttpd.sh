#!/usr/bin/env bash
IFS=$'\n\r'

source config/bhttpd.conf

function get_content_type() {
    extension=${1##*.}
    if [[ "$extension" = "txt" ]]
    then
        echo "text/plain"
    elif [[ "$extension" = "html" ]]
    then
        echo "text/html"
    else
        echo "application/octet-stream"
    fi
}

function create_response_header() {
    uri=$1
    type=$(get_content_type "$uri")
    echo "HTTP/${version} 200 OK"
    echo "Date: $(date)"
    echo "Server: bhttpd-1.0"
    echo "Content-Length: $(wc -c "${BASEDIR}/${uri}" | awk '{print $1}')"
    echo "Content-Type: ${type}"
    echo ""
}

if [[ -z $FLAG ]]
then
    export FLAG=0
    socat tcp-listen:${PORT},fork system:$(pwd)/"$0" &
else
    method=
    uri=
    declare -A headers
    version=
    phase="request_line"
    while [ "$phase" != "finished" ]
    do
        read -ra line
        case "$phase" in
        "request_line")
            if [[ $(echo "$line" | grep -E "HTTP/1.0$") != "" ]]
            then
                method=$(echo "$line" | cut -d" " -f1)
                uri=$(echo "$line" | cut -d" " -f2 | nkf -w --url-input)
                version="1.0"
            fi
            phase="headers"
            ;;
        "headers")
            if [[ "$line" = "" ]]
            then
                if [[ "$method" = "GET" || "$method" = "HEAD" ]]
                then
                    if [[ -e ${BASEDIR}/${uri} ]]
                    then
                        create_response_header $uri
                        if [[ "$method" = "GET" ]]
                        then
                            cat ${BASEDIR}/${uri}
                        fi
                    else 
                        echo "HTTP/1.0 404 Not Found"
                    fi
                else
                    echo "HTTP/${version} 501 Not Implemented"
                fi
                phase="finished"
            else
                headers[$(echo "$line" | cut -d ":" -f1)]=$(echo "$line" | cut -d ":" -f2)
            fi
            ;;
        esac
    done
fi
