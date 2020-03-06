#!/usr/local/bin/bash
# shellcheck disable=SC1003

# yml Parser function
# Based on https://gist.github.com/pkuczynski/8665367
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("export %s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# automatic update function
gitupdate() {
echo "checking for updates using Branch: $1"
git fetch
git update-index -q --refresh
CHANGED=$(git diff --name-only origin/$1)
if [ ! -z "$CHANGED" ];
then
    echo "script requires update"
    git reset --hard
    git checkout $1
    git pull
    echo "script updated"
    exit 1
else
    echo "script up-to-date"
fi
}
