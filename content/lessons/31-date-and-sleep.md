---
number: 31
slug: date-and-sleep
title: date and sleep
module: Space, time, and processes
level: intermediate
minutes: 26
summary: GNU date -d parses a date string and @epoch. sleep accepts a decimal and a suffix. Neither one is a scheduler.
objectives:
  - Format a fixed epoch instant in UTC
  - Add a relative day with -d
  - Read date --resolution as a property of this host
  - Reject an invalid sleep interval and use a short valid one
manual: date invocation | https://www.gnu.org/software/coreutils/manual/html_node/date-invocation.html
manual: sleep invocation | https://www.gnu.org/software/coreutils/manual/html_node/sleep-invocation.html
gnu_vs_bsd: |
  GNU `date -d` is the parse-this-string interface. BSD `date` uses `-f` for an input format and `-v` for adjustments. A script with `date -d` fails on macOS unless it calls `gdate`. GNU `sleep` accepts decimals and suffixes `s`, `m`, `h`, `d`. Some older sleeps only accept integers. `timeout` is the GNU tool that stops another command; BSD base systems often lack it. This lesson ran GNU date and GNU sleep only.
---

`date` formats the clock or a timestamp you name. The default is "now", which makes a captured lesson unreproducible, so the examples pass `-d` or `@epoch`. `-u` forces UTC. `date -u -d @1700000000 '+%Y-%m-%dT%H:%M:%SZ'` is a fixed instant, the same on every machine that agrees on UTC and on GNU date's parser. `date -d '2020-01-02 + 1 day'` adds a day in the parser's relative grammar. The date-input-formats node is the long description of what those strings allow. `--debug` prints how a string was interpreted. Use it when a build's `SOURCE_DATE_EPOCH` formatting looks shifted by a day, which is usually a timezone, not a broken calendar.

`--resolution` prints the clock resolution date believes it has. On this capture host it is one nanosecond. That is not a promise that every filesystem timestamp has nanosecond granularity, and it is not a promise that `sleep` can delay for one nanosecond accurately. It is a property of the clock interface on this kernel.

`sleep` pauses the process. `sleep 0.05` returns quickly. `sleep 1m` is a minute. `sleep foo` exits non-zero and prints "invalid time interval". Sleep is not a timer you share across machines with better than "about this long" accuracy, and it is not the tool that kills a hung child. `timeout` does that. A test that `sleep 5` to "wait for the server" is a race. Poll the condition, and use timeout as a backstop.

Do not embed `date` with no argument in a file you will checksum. The digest will change every second. Format a fixed input, or accept that the line is a label and not a byte-stable artifact.

## Worked examples

### A fixed instant

```run
# title: date -u -d @epoch
/usr/bin/date -u -d @1700000000 '+%Y-%m-%dT%H:%M:%SZ'
```

### A relative day

```run
# title: Add one day
/usr/bin/date -u -d '2020-01-02 + 1 day' '+%Y-%m-%d'
```

### Resolution of this clock

```run
# title: date --resolution
/usr/bin/date --resolution
```

### Valid and invalid sleep

```run
# title: sleep 0.05 and a bad interval
/usr/bin/sleep 0.05
/usr/bin/printf 'slept\n'
set +e
/usr/bin/sleep foo
/usr/bin/printf 'bad:%s\n' $?
set -e
```

## Recipes

Stamp a release note with `date -u -d "@${SOURCE_DATE_EPOCH:-0}"` only when the epoch is actually exported. If it is unset, the `:-0` fallback is the epoch, which is obvious in the output and better than silently using "now". Prefer failing the script when the variable must be set.

Pause a retry loop with `sleep 0.2` and a counted attempt, and wrap the whole loop's command in `timeout` if the command itself can hang. Sleep does not bound the command. It only delays the next try.

## Tips and pitfalls

`date -d` of an ambiguous string can pick a timezone you did not mean. Pass `-u` and a numeric offset or `Z` when the instant must be absolute. `--debug` if you are unsure.

`TZ=UTC date` and `date -u` are related and not identical in every format. The examples use `-u`.

`sleep 0` returns immediately. It is a legal interval. It is not a yield you can count on for scheduling fairness.

## Exercises

```exercise
expect-exit: 0
---title---
Format the epoch
---prompt---
Print `@0` in UTC as `YYYY-MM-DD`.
---hint---
`date -u -d @0 +%Y-%m-%d`.
---solution---
`1970-01-01`.
---script---
/usr/bin/date -u -d @0 '+%Y-%m-%d'
```

```exercise
expect-exit: 0
---title---
Sleep a short interval
---prompt---
Sleep for 0.05 seconds and print `awake`.
---hint---
A decimal is accepted by GNU sleep.
---solution---
The script continues after the pause. The pause is not a precise 50 milliseconds on a loaded machine, and this capture does not claim it was.
---script---
/usr/bin/sleep 0.05
/usr/bin/printf 'awake\n'
```

```exercise
expect-exit: 1
---title---
Reject a bad interval
---prompt---
Run `sleep later` and let it fail.
---hint---
The operand is not a number.
---solution---
Status is non-zero and the message says the interval is invalid.
---script---
/usr/bin/sleep later
```

## Performance

`date` is a formatting process. Calling it once per file in a loop of a million files dominates the loop. Format once, or format in the language that is already walking the files. `sleep` in a polling loop is a latency choice: shorter sleeps burn wakeups, longer sleeps notice the event later. Neither is "faster" in general. A busy sleep loop is not a benchmark of the CPU. The timeout and buffering benchmarks are the ones that measure a bound and a delay with a stated input. Do not put `sleep` inside a timing trial unless the delay is the thing you are measuring, and then report it as a delay, not as work.
