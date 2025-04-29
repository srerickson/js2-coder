
CODER_URL=coder.oth240004.projects.jetstream-cloud.org
workspaces=$(coder list --all --column=workspace 2>/dev/null | grep -v WORKSPACE)
for name in $workspaces; do
    echo "deleting $name ..."
    coder delete -y $name > /dev/null 2>&1;
done
