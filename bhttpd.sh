#!/usr/bin/env bash
IFS=$'\n\r'
PORT=8001
BASEDIR=$(pwd)/contents

if [[ -z $FLAG ]]
then
    export FLAG=0
    socat tcp-listen:${PORT},fork system:$(pwd)/"$0" &
else
    method=
    uri=
    headers=
    while read -ra line
    do
        if [[ $(echo "$line" | grep -E "HTTP/1.0$") != "" ]]
        then
            method=$(echo "$line" | cut -d" " -f1)
            uri=$(echo "$line" | cut -d" " -f2)
        elif [[ "$line" = "" ]]
        then
            if [[ "$method" = "GET" ]]
            then
                if [[ -e ${BASEDIR}/${uri} ]]
                then
                    echo "HTTP/1.0 200 OK"
                    echo "Date: $(date)"
                    echo "Server: bttpd-1.0"
                    echo ""
                    cat ${BASEDIR}/${uri}
                else 
                    echo "HTTP/1.0 404 Not Found"
                fi
                method=
                uri=
            else
                echo "ERROR"
            fi
        fi
    done
fi
