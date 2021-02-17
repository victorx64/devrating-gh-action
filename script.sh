#!/usr/bin/env sh

devrating_repository="$1"
devrating_organization="$2"
devrating_key="$3"
base_branch="$4"
github_token="$5"

send_to_devrating()
{
  json=$(devrating serialize diff -t $1 -b $2 -e $3 -a $4 -l $5 -p $GITHUB_WORKSPACE -o $devrating_organization -n $devrating_repository)

  set -x
  curl -i -X POST "https://devrating.net/api/v1/diffs/key" -H "key: ${devrating_key}" -H "Content-Type: application/json" --data-raw $json
  set +x
}

analyze_pr()
{
  remainder="$1"
  merged_at="${remainder%% *}"; remainder="${remainder#* }"
  merge_commit="${remainder%% *}"; remainder="${remainder#* }"
  base_commit="${remainder%% *}"; remainder="${remainder#* }"
  head_commit="${remainder%% *}"; remainder="${remainder#* }"
  email="${remainder%% *}"; remainder="${remainder#* }"
  url="${remainder%% *}";

  if [ "$merge_commit" != "null" ]; then
    send_to_devrating $merged_at $merge_commit~ $merge_commit $email $url
  else
    send_to_devrating $merged_at $base_commit $head_commit $email $url
  fi
}

request_prs()
{
  minus_90_days_year=$(date --date="90 days ago" +"%Y")
  minus_90_days_month=$(date --date="90 days ago" +"%m")
  minus_90_days_day=$(date --date="90 days ago" +"%d")
  merged_after="$minus_90_days_year-$minus_90_days_month-$minus_90_days_day"

  prs=$(curl -H "Authorization: token ${github_token}" -X POST -d "{ \
    \"query\": \"query { \
        search (query: \\\"repo:${GITHUB_REPOSITORY} base:${base_branch} type:pr merged:>=${merged_after} sort:updated-desc\\\", type: ISSUE, first: 100) { \
          nodes { \
            ... on PullRequest { \
              mergedAt \
              mergeCommit { \
                oid \
              } \
              baseRefOid \
              headRefOid \
              commits(first: 1) { \
                nodes { \
                  commit { \
                    author { \
                      email \
                    } \
                  } \
                } \
              } \
              url \
            } \
          } \
        } \
      }\" \
    }" https://api.github.com/graphql | \
    jq -c -r '.data.search.nodes | .[] | "\(.mergedAt) \(.mergeCommit.oid) \(.baseRefOid) \(.headRefOid) \(.commits.nodes | .[0] | .commit.author.email) \(.url)"' | \
    sort)

  printf "$prs"

  IFS=$'
'

  for pr in $prs; do
    analyze_pr $pr
  done
}

dotnet tool install -g devrating.consoleapp --version 3.1.5
request_prs

url_org=$(jq -rn --arg x $devrating_organization '$x|@uri')
url_repo=$(jq -rn --arg x $devrating_repository '$x|@uri')

echo "Visit: https://devrating.net/#/repositories/${url_org}/${url_repo}"