#!/bin/bash

# list all zones
for zone in $(ls ./zones)
do
    # Delete domain
    # Ignore all config line starting with '#'
    while IFS=, read -r name type content
    do [[ $name =~ (^#.*) ]] && continue 
        name="$(echo -e "${name}" | tr -d '[[:space:]]')"
        type="$(echo -e "${type}" | tr -d '[[:space:]]')"
        content="$(echo -e "${content}" | tr -d '[[:space:]]')"

        if [ "$name" = "" ] 
        then
            continue
        fi

        while IFS="|" read -r id type name content proxied ttl
        do            
            id="$(echo -e "${id}" | tr -d '[[:space:]]')"
            echo Remove $id $name
            ./flarectl dns delete --zone=$zone --id=$id
        done < <(./flarectl dns list --zone $zone --name $name.$zone --type $type | grep -P "\s*[a-z0-9]+");
    done < <(git --no-pager diff --ignore-space-at-eol HEAD~1 -- ./zones/$zone | grep -P "^[\-]([^,]+,){2}[^,]+" | cut -c 2-);

    # Add domain
    # Ignore all config line starting with '#'
    while IFS=, read -r name type content
    do [[ $name =~ (^#.*) ]] && continue 
        name="$(echo -e "${name}" | tr -d '[[:space:]]')"
        type="$(echo -e "${type}" | tr -d '[[:space:]]')"
        content="$(echo -e "${content}" | tr -d '[[:space:]]')"

        if [ "$name" = "" ] 
        then
            continue
        fi

        ./flarectl dns create-or-update --zone=$zone --name=$name --content=$content --type=$type;
    done < <(git --no-pager diff --ignore-space-at-eol HEAD~1 -- ./zones/$zone | grep -P "^[\+]([^,]+,){2}[^,]+" | cut -c 2-);
done
