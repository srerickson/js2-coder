# directory where workshop datasets are stored
home_data="$HOME/workshop"

if ! command -v ocfl > /dev/null 2>&1; then
    ocfl_tools=https://github.com/srerickson/ocfl-tools/releases/download/v0.3.1/ocfl-tools_Linux_x86_64.tar.gz
    ocfl_tmp=/tmp/ocfl-tools.tar.gz
    ocfl_dst=/usr/local/bin    
    wget -O $ocfl_tmp $ocfl_tools
    sudo tar -C $ocfl_dst -xzf $ocfl_tmp
    rm $ocfl_tmp
fi

mkdir -p $home_data
for proj in $(ocfl ls); do
    dst="$home_data/$proj"
    if [ ! -d "$dst" ]; then
        ocfl export --id $proj --to $dst; 
    fi
done