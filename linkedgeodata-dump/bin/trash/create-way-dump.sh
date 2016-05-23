#!/bin/bash

#service="$1"

#if [ -z "$service" ]; then
#    echo "Please specify the service from which to dump, e.g. http://localhost:7531/sparql"
#    exit 1
#fi

echoerr() { echo "$@" 1>&2; }

date=`date +%F`
targetDir="../target/dump/$date"
mkdir -p "$targetDir"



sed -r '/(^#)|($\s*^)/ d' | while read line; do

    typ="http://linkedgeodata.org/ontology/$line"
    file="$date-$line.ways.sorted.nt.bz2"

    ./dump-ways.sh "$typ" | sort -u -S 1024M | pbzip2 -c > "$targetDir/$file"

    echoerr "$line"
done

