file=$1


create_user() {
    user=$1
    email=$2
    name=$3
    pass=$4
    if coder user show $user > /dev/null 2>&1; then 
        echo "user exists: $email"
        return
    fi
    coder user create --login-type password \
                      --username "$user" \
                      --password "$pass" \
                      --full-name "$name" \
                      --email "$email" > /dev/null 2>&1
    echo "created new user: $user $email $name $pass"
}

create_workspace() {
    user=$1
    if [ -z $user ]; then 
        echo "missing required argument: username"
        return
    fi
    existing=$(coder list --search "owner:$user" 2> /dev/null)
    if [ -n "$existing" ]; then
        echo "$user: vm exists"
        return
    fi
    coder create --yes --template default "$user/workshop"
}


if [ -z "$file" ]; then 
    echo "missing required argument: account csv file"
    exit 1
fi

while read csv_line; do
    if [[ "$csv_line" == "Username,"* ]]; then
        continue
    fi
    user=$(echo "$csv_line" | cut -d',' -f1)
    email=$(echo "$csv_line" | cut -d',' -f2)
    name=$(echo "$csv_line" | cut -d',' -f3)
    pass=$(echo "$csv_line" | cut -d',' -f4)
    
    create_user "$user" "$email" "$name" "$pass"
    create_workspace "$user"
done < $file