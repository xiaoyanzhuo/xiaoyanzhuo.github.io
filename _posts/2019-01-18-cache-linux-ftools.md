---
layout: article
title: About cache
key: 20190118
tags:
- Linux
mathjax: true
---

In this article, you can find how to check cache size, free cache and check which files are cached. 

<!--more-->

## Check cache size

According to specific requirements, we can check cache size by using:

`$cat /proc/cpuinfo`

`$cat /proc/meminfo` 

`$lscpu | grep cache` 

`$dmesg | grep cache`

`$getconf -a | grep CACHE`

`cat /sys/devices/system/cpu/cpu0/cache/index1/size` (level 1)
`cat /sys/devices/system/cpu/cpu0/cache/index2/size` (level 2)
`cat /sys/devices/system/cpu/cpu0/cache/index3/size` (level 3)

- Some device may not have level 3 cache. 
- Or check '/sys/devices/system/cpu/cpu0/cache', maybe you can find 'index0' as well. We can get to know which level it belongs by `cat /sys/devices/system/cpu/cpu0/cache/index0/level` .

Example:

~~~
$ lscpu | grep cache
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              20480K
~~~

Others

`$ lstopo-no-graphics` 

`$ hwloc-ls` 

(may require install packages: hwloc, hwloc-nox)

## Free cache

- Free pagecache:

`$ sudo sh -c 'echo 1 >/proc/sys/vm/drop_caches'`

- Free dentries and inodes:

`$ sudo sh -c 'echo 2 >/proc/sys/vm/drop_caches'`

- Free free page cache, dentries and inodes:

`$ sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'`

## What's in cache

If you'd like to analyze the contents of the buffers & cache, to see what are currently being cached, you can try [linux-ftools](https://code.google.com/archive/p/linux-ftools/). If you cannot not open google, you can check out [github repo of linux-ftools](https://github.com/xiaoyanzhuo/linux-ftools). 

`$ git clone https://github.com/xiaoyanzhuo/linux-ftools`

After you get the linux-ftools, READ file 'INSTALL' and follow the instruction inside. Briefly, what you need to do:

~~~
$ cd linux-ftools
$ ./configure
$ make
$ make install
~~~

>It works well when I installed it on regular linux server. 
However, on embeding system, I got fatal error when `make` the files, showing cannot find `#include <asm/unistd_64.h>`. Check `$find /usr/src/linux-headers-* -name 'unistd*.h'` and make sure build tools `$sudo apt-get update`, `$sudo apt-get install build-essential`. Tried other ways found online but none of them worked. The solution for my case: I just comment out the line `#include <asm/unistd_64.h>` in 'fadvise.c' and 'fallocate.c', the files mentioned in error information.

Finally, we have linux-ftools installed and can use it now.

Go to the dir in which you want to check what files are cached:

`$ fincore --pages=false --summarize --only-cached * `

Example:

~~~
$ cd ~/test_dir/
$ fincore --pages=false --summarize --only-cached *
filename size   total pages     cached pages    cached size     cached percentage
bikegray_6400x4800.pgm 30720056 7501 7501 30724096 100.000000
...
---
total cached size: 123404288
$ sudo sh -c 'echo 1 >/proc/sys/vm/drop_caches'
$ fincore --pages=false --summarize --only-cached *
filename size   total pages     cached pages    cached size     cached percentage
---
total cached size: 0
~~~


##### [References]
1. [empty-the-buffers-and-cache-on-a-linux-system](https://unix.stackexchange.com/questions/87908/how-do-you-empty-the-buffers-and-cache-on-a-linux-system)
2. [linux-ftools on code.google](https://code.google.com/archive/p/linux-ftools/)