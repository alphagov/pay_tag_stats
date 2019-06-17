## Pay: Build lead time stats

These scripts look at the lead time between:
- merge to master (merge commit)
- a tagged release candidate (tag `alpha_release-nnn`)

## Usage

it operates on a locally checked out repo

```sh
$ ./bin/stats ../pay-connector
```

stats are emitted in CSV format to STDOUT