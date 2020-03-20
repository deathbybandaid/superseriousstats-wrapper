#!/bin/bash

# Configurables
mountdirectory="/mnt/logshare"
phppath=`which php`
sssdirectory="/var/www/html/superseriousstats"
sssphp="$sssdirectory/sss.php"
configdirectory="$sssdirectory/conf"
databasedirectory="$sssdirectory/databases"
webpagesdirectory="$sssdirectory/www"
sssvarsfile="$webpagesdirectory/vars.php"
indexfiletop="$sssdirectory/indextop"
indexfilemid="$sssdirectory/indexmid"
indexfilebottom="$sssdirectory/indexbottom"
indexfile="$webpagesdirectory/index.html"
indexfilenew="$webpagesdirectory/indexnew.html"
channelprefix="#"
conftemplate="$sssdirectory/stock.conf"
varstemplate="$sssdirectory/vars.conf"
databasetemplate="$sssdirectory/empty_database_v7.sqlite"
databasedirectoryesc="\/var\/www\/html\/superseriousstats\/databases"

while true
do
  # ensure working path
  cd /var/www/html/superseriousstats

  # create list of actual channels to parse
  declare -a channellist=()
  for privmsgname in $mountdirectory/*
  do
    channelname=$(basename "$privmsgname")
    if [[ $channelname = $channelprefix* ]]
    then
      channellist+=( "$channelname" )
    fi
  done

  # Create New index.html - start
  if [[ -f "$indexfilenew" ]]
    then
      rm "$indexfilenew"
  fi
  cat "$indexfiletop" >> "$indexfilenew"

  # Process
  for channelname in "${channellist[@]}"
  do
    # temp vars
    mountpath="$mountdirectory/$channelname"
    conffile="$configdirectory/$channelname.conf"
    dbfile="$databasedirectory/$channelname.db3"
    dbfileesc="$databasedirectoryesc\/$channelname.db3"
    htmlfile="$webpagesdirectory/$channelname.html"
    htmlfileparsed=`echo "$channelname.html" | sed -r 's/\#/%23/g'`

    printf "Processing $channelname ... \n"

    # check for config file
    if [[ -f "$conffile" ]]
    then
      :
    else
      printf "$conffile does not exist, creating now from template\n"
      cat "$conftemplate" | sed "s/REPLACECHANNELNAMEHERE/$channelname/g; s/REPLACEDBPATHHERE/$dbfileesc/g" > "$conffile"
    fi

    # check for database file
    if [[ -f "$dbfile" ]]
    then
      :
    else
      printf "$dbfile does not exist, creating now\n"
      cat "$databasetemplate" | sqlite3 "$dbfile"
    fi

    # fill database file with any new content
    "$phppath" "$sssphp" -i "$mountpath" -o "$htmlfile"  -c "$conffile" > /dev/null

    # check vars file
    if grep \'"$channelname"\' "$sssvarsfile" > /dev/null
    then
      :
    else
      printf "setting up vars file for $channelname"
      cat "$varstemplate" | sed "s/REPLACECHANNELNAMEHERE/$channelname/g; s/REPLACEDBPATHHERE/$dbfileesc/g" >> "$sssvarsfile"
    fi

    # check index file
    cat "$indexfilemid" | sed "s/REPLACECHANNELNAMEHERE/$channelname/g; s/REPLACECHANNELHTMLHERE/$htmlfileparsed/g" >> "$indexfilenew"
  done

  # create new index.html - end
  cat "$indexfilebottom" >> "$indexfilenew"

  # finish index.html
  mv "$indexfilenew" "$indexfile"
sleep 5m
done
