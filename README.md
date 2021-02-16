This action builds a rating of contributors by the stability of code. 
You can compete with each other and earn XP for pull requests.

## Usage

Just throw this to `.github/workflows/devrating.yml` in your repo:

```yaml
name: Updating ranks in devrating.net
on:
  pull_request:
    branches: [ main ]  # Put your dev branch
    types: [ closed ]
jobs:
  devrating:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
      with:
        fetch-depth: 0  # Required to be 0

    - uses: victorx64/devrating-gh-action@v0
      with:
        devrating-organization: # Your Organization_ID. Visit https://devrating.net/#/keys to obtain
        devrating-api-key: # Your API_Key. Visit https://devrating.net/#/keys to create new
```

Then, merge a pull request to initiate the export.