#!/usr/bin/env sh

devrating_repository="$1"
devrating_organization="$2"
devrating_key="$3"
base_branch="$4"
github_token="$5"

send_to_devrating()
{
  json=$(devrating serialize commit -m $1 -p $GITHUB_WORKSPACE -l $2 -o $devrating_organization -n $devrating_repository -t $3)

  set -x
  curl -X POST "https://devrating.net/api/v1/diffs/${devrating_key}" -H "Content-Type: application/json" --data-raw $json
  set +x
}

analyze_pr()
{
  remainder="$1"
  merged_at="${remainder%% *}"; remainder="${remainder#* }"
  sha="${remainder%% *}"; remainder="${remainder#* }"
  url="${remainder%% *}";

  if [ "$merged_at" != "null" ]; then
    send_to_devrating $sha $url $merged_at
  fi
}

request_prs()
{
  prs=$(curl -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${github_token}" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls?base=${base_branch}&sort=updated&direction=desc&state=closed&per_page=100" | \
    jq -c -r '.[] | "\(.merged_at) \(.merge_commit_sha) \(.html_url)"' | \
    awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }')

  printf "$prs"

  IFS=$'
'

  for pr in $prs; do
    analyze_pr $pr
  done
}

dotnet tool install -g devrating.consoleapp --version 3.1.1
request_prs
echo "Visit: https://devrating.net/#/repositories/${devrating_organization}/${devrating_repository}"