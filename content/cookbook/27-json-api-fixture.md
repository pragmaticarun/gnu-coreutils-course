---
number: 27
slug: json-api-fixture
title: JSON from an API fixture
module: Cookbook
level: beginner
minutes: 20
summary: jq reads a saved JSON document. sort orders the names. No network is required. jq is not coreutils.
manual: jq | https://jqlang.org/manual/
manual: sort invocation | https://www.gnu.org/software/coreutils/manual/html_node/sort-invocation.html
gnu_vs_bsd: |
  jq is the same upstream on BSD ports. BSD sort differs in key syntax. This recipe ran Ubuntu jq 1.7 and GNU sort. It did not open a socket.
---

API responses are JSON files once you have saved them. `jq` is jq, not coreutils. The sandbox must not call the network, so the recipe writes the document itself and treats it as the file `curl` would have left behind. `.items[].name` walks an array. `-r` prints raw strings instead of JSON quotes. `sort` is coreutils and orders those lines under `LC_ALL=C`, which is byte order, not dictionary order. `wc -l` counts them. A missing key is jq's error and a non-zero status, which is what you want under `set -o pipefail`.

Do not scrape a live endpoint from a lesson script. The bytes would change, the capture would rot, and the sandbox rule would be broken.

## Steps

```run
# title: Names from a fixture
# companion: jq
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"},{"name":"libfoo","arch":"amd64"}]}' > api.json
/usr/bin/jq -r '.items[].name' api.json | LC_ALL=C /usr/bin/sort | /usr/bin/uniq -c | /usr/bin/sed 's/^ *//'
```

```run
# title: One architecture, one count
# companion: jq
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"}]}' > api.json
/usr/bin/jq -r '.items[] | select(.arch=="arm64") | .name' api.json | /usr/bin/wc -l | /usr/bin/tr -d ' '
```

## Check yourself

```exercise
expect-exit: 0
---title---
Print the arm64 name
---prompt---
From a two-item document, print the name whose arch is arm64.
---hint---
`select(.arch=="arm64")` inside jq.
---hint2---
`-r` drops the JSON quotes. The name is `libfoo`.
---solution---
`libfoo`.
---script---
/usr/bin/printf '%s\n' '{"items":[{"name":"libfoo","arch":"arm64"},{"name":"libbar","arch":"amd64"}]}' > api.json
/usr/bin/jq -r '.items[] | select(.arch=="arm64") | .name' api.json
```

## Performance

jq parses the document. A giant array is a memory cost, visible as RSS if you wrap jq in `/usr/bin/time -v` at a terminal. This fixture is three objects and is not that measurement. Line-delimited JSON can be processed a line at a time so the process does not hold the whole dump. Sorting the extracted names is the coreutils cost, and it is cheap at this size. `LC_ALL=C` avoids locale work you do not need for identifiers. The course does not time jq against a live API, because the network would dominate and the sandbox forbids it.
