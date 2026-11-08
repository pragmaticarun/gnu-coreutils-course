---
number: 37
slug: identity-and-host
title: Identity, the host, and what is not a terminal
module: Space, time, and processes
level: intermediate
minutes: 28
summary: id, whoami, uname, and hostid describe the account and the kernel. users, who, logname, and tty describe a login session this capture does not have. SELinux tools fail closed here.
objectives:
  - Read the user and groups from id without confusing them with a login session
  - Print a kernel line with uname -srm and keep the nodename out of it
  - Interpret empty users output and a failing logname and tty
  - See id -Z and runcon fail because SELinux is not enabled
manual: id invocation | https://www.gnu.org/software/coreutils/manual/html_node/id-invocation.html
manual: whoami invocation | https://www.gnu.org/software/coreutils/manual/html_node/whoami-invocation.html
manual: uname invocation | https://www.gnu.org/software/coreutils/manual/html_node/uname-invocation.html
manual: users invocation | https://www.gnu.org/software/coreutils/manual/html_node/users-invocation.html
manual: logname invocation | https://www.gnu.org/software/coreutils/manual/html_node/logname-invocation.html
manual: tty invocation | https://www.gnu.org/software/coreutils/manual/html_node/tty-invocation.html
manual: hostid invocation | https://www.gnu.org/software/coreutils/manual/html_node/hostid-invocation.html
gnu_vs_bsd: |
  POSIX specifies `id`, `uname`, `logname`, `tty`, and `who`. `whoami` is ubiquitous and not the same spelling everywhere in older systems. GNU `id -Z` and `runcon` / `chcon` are SELinux interfaces. BSD uses different mandatory-access tools and does not accept `-Z`. GNU `uname` field selectors match the letters this lesson uses. `stty` exists in both userlands. This course does not point `stty` at the session terminal, because it changes terminal modes. No BSD identity command was executed.
---

`id` prints the user and group identifiers of the process. `id -un` prints the name only. `whoami` prints that same name. On this capture both print the sandbox account, which is the account the runner used, not a student name and not a machine name. `groups` lists the supplementary groups. Those groups are why a process can read plugdev or sudo-owned files. They are not a list of logged-in people.

`uname -srm` prints the kernel name, the release, and the machine. This host produced a line beginning `Linux` and ending `x86_64`. The lesson uses `-srm` on purpose. `-n` would print the nodename, and a nodename is often a hostname you did not mean to publish in a course page or a bug report. `arch` prints the machine hardware name and matches the trailing field of that `uname` line on this host. Neither command reads `/etc/hostname`. The `hostname` binary on Ubuntu is a different package, documented with the companions.

`users` and `who` read the login accounting files. In this capture there is no logged-in user in that table. `users` prints nothing and exits 0. `who` prints nothing and exits 0. An empty success is not "the command is broken". It is "the table is empty". `pinky` prints a header and no rows in the same situation. `logname` asks for the login name associated with the terminal and fails here with "no login name", status 1. `tty` prints "not a tty" and exits 1, because the runner's stdout is a pipe, not a terminal. The exit-status node lists `tty` as a command whose non-zero status is an answer. A script that does `set -e` and then calls `tty` will stop on a pipe, which is often what you want when you were about to launch an interactive pager.

`hostid` prints a 32-bit hex identifier. The captured value on this host is `007f0100`. Treat it as a host tag the binary printed, not as a credential and not as proof of a particular network address. Do not key a license check on it. It is stable enough to confuse you and weak enough to be the wrong authenticator.

`printenv` prints the environment. It is the inspection tool that matches `env`, which modifies the environment for a child. `printenv HOME` prints the sandbox home the runner set. `printenv` of an unset name exits 1. That status is one of the exceptions in the exit-status node.

SELinux is not enabled on this kernel. `id -Z` exits 1 and says `--context` works only on an SELinux-enabled kernel. `chcon` cannot apply a partial context to an unlabeled file. `runcon` exits 125 and says it may be used only on an SELinux kernel. The course records those failures so you do not copy a Fedora snippet onto this Ubuntu image and treat the failure as a mystery. `stty` is installed and is the tool that changes terminal settings. The examples do not run it against a terminal. `--help` is as far as this lesson goes, because a stray `stty` in a captured session can change echo and erase for the person watching.

## Worked examples

### Account and groups

```run
# title: id, whoami, and groups
/usr/bin/id -un
/usr/bin/whoami
/usr/bin/groups
```

### Kernel line without the nodename

```run
# title: uname -srm and arch
/usr/bin/uname -srm
/usr/bin/arch
```

### No login session on this runner

```run
# title: users, who, logname, and tty
/usr/bin/printf 'users:[%s]\n' "$(/usr/bin/users)"
/usr/bin/printf 'who_lines:%s\n' "$(/usr/bin/who | /usr/bin/wc -l)"
set +e
/usr/bin/logname
/usr/bin/printf 'logname:%s\n' $?
/usr/bin/tty
/usr/bin/printf 'tty:%s\n' $?
set -e
```

### SELinux interfaces fail closed

```run
# title: id -Z, chcon, and runcon
/usr/bin/printf 'x\n' > unlabeled
set +e
/usr/bin/id -Z
/usr/bin/printf 'idz:%s\n' $?
/usr/bin/chcon -t user_home_t unlabeled
/usr/bin/printf 'chcon:%s\n' $?
/usr/bin/runcon -t user_home_t /usr/bin/true
/usr/bin/printf 'runcon:%s\n' $?
set -e
```

## Recipes

Put `uname -srm` and `id -un` in a bug report, plus the coreutils version from the orientation lesson. Leave the nodename out unless the bug is about the name. Add `tty` status when the bug is "it behaves differently in CI", because CI is usually not a terminal and your laptop is.

Before a script calls `logname` or opens `/dev/tty`, check `tty` and branch. A pipeline that assumes a terminal will fail in the course runner, in cron, and in a GitHub Actions job for the same reason.

Do not gate a feature on `id -Z` succeeding. Test for SELinux explicitly and skip the context commands when the kernel says they do not apply. The statuses above are the skip signal on this image.

## Tips and pitfalls

`whoami` and `logname` answer different questions. `whoami` is the effective user of the process. `logname` is the user who logged in on the terminal. They diverge under `su` and they diverge here because there is no terminal login at all.

`users` exiting 0 with an empty line is success. A monitor that alerts on empty stdout will false-alarm. Alert on status, or on a parsed count you printed yourself.

`pinky` is a friendlier `who`. It still reads the same kind of accounting data. An empty body under a header is the same fact as `who` printing zero lines.

`stty -a` on a real terminal dumps settings and is harmless. `stty raw` or `stty -echo` is not harmless. This course does not run those. If you experiment, run them in a terminal you can close, and remember `reset` from ncurses is the usual recovery. `reset` is not coreutils.

## Exercises

```exercise
expect-exit: 0
---title---
Print the user name
---prompt---
Print `id -un` and `whoami` on separate lines.
---hint---
Both read the process owner.
---solution---
The two lines match. On this runner they are the sandbox account.
---script---
/usr/bin/id -un
/usr/bin/whoami
```

```exercise
expect-exit: 0
---title---
Show the kernel without the nodename
---prompt---
Run `uname -srm`.
---hint---
`-s` system, `-r` release, `-m` machine. There is no `-n`.
---solution---
Three fields. The machine field matches `arch` on this host.
---script---
/usr/bin/uname -srm
```

```exercise
expect-exit: 1
---title---
Ask tty and accept the failure
---prompt---
Run `tty` in this non-terminal runner.
---hint---
Status 1 and the text "not a tty" is the answer.
---solution---
The command fails because stdout is not a terminal. That is expected here.
---script---
/usr/bin/tty
```

## Performance

These commands are lookups. `id` and `uname` are single syscalls plus formatting. `who` and `users` read a small accounting file. None of them belong in a per-file loop. Call them once, store the string, and reuse it in a banner. `hostid` is also a single call and still the wrong thing to hash on every request of a service.

`tty` is cheap and worth calling once at startup of an interactive tool. Calling it per line to decide whether to colorize is unnecessary once you know the answer does not change mid-process, unless you reopened stdout. The performance question for identity commands is not their CPU cost. It is the cost of logging too much: a nodename and a hostid in every line of a high-volume log is bytes you pay to store and a privacy problem, not a speedup.
