---
layout: article
title: How to use PAPI to collect performance data
key: 20200620
tags:
- Linux
- tool
mathjax: true
---

In this article, you can find how to use Performance API (papi) to collect performance data.

<!--more-->

## Install

Follow papi offical instructions [Downloading-and-Installing-PAPI](https://bitbucket.org/icl/papi/wiki/Downloading-and-Installing-PAPI.md).

**Note**: Before running PAPI with your own code, do the following:

~~~
export PAPI_DIR=<you location where PAPI is installed>
export PATH=${PAPI_DIR}/bin:$PATH
export LD_LIBRARY_PATH=${PAPI_DIR}/lib:$LD_LIBRARY_PATH
~~~

There are many events and operations can be done via papi. In my experiment, all the data I want to be collect are all in preset event, and I can use [high-level API](https://bitbucket.org/icl/papi/wiki/PAPI-HL.md). 

After install papi, you can check what events are available in our board/system:

`$papi_avail`

## Use high-level API of papi 

To utilize high-level API of papi, you can mainly follow the instructions of [high-level API](https://bitbucket.org/icl/papi/wiki/PAPI-HL.md).

More path/env setting are needed:

~~~
export PAPI_EVENTS="PAPI_L1_DCM,PAPI_L1_ICM,PAPI_L2_DCM,PAPI_TLB_DM,PAPI_TLB_IM,PAPI_TOT_INS,PAPI_TOT_CYC,PAPI_L1_DCA,PAPI_L2_DCA" 
#export PAPI_EVENTS="PAPI_L1_TCM,PAPI_L2_TCM,PAPI_TLB_DM,PAPI_L1_LDM,PAPI_L1_STM,PAPI_L2_LDM,PAPI_L2_STM,PAPI_MEM_SCY,PAPI_MEM_RCY,PAPI_MEM_WCY,PAPI_STL_ICY"   
export PAPI_OUTPUT_DIRECTORY="/home/firefly/xyz/repo_test/openvx-kernels/tiling/bin_tiling_papi/output"
export PAPI_MULTIPLEX=1   # enable PAPI_MULTIPLEX
~~~

- `PAPI_EVENTS`: check the available event(`$ papi_avail`) and set the event you are interested.
- `PAPI_OUTPUT_DIRECTORY`: default is your current dir, you can set as needed and the output file name following rules which can be found in source code, pretty interesting. The latest dir one will always be `papi_hl_output` and previous one(s) will automatically change the name based on the timestamps (when the file was created); while file name start with 'rank_xxxxxx' follow the name rules they made. 

After you have set the above path/env, you can start to edit your code. The following code example shows the use of the high-level API by marking a code section (from official docs).

~~~ c
#include "papi.h"    //(1)

int main()
{
    int retval;      //(2)

    retval = PAPI_hl_region_begin("computation"); //(3)
    if ( retval != PAPI_OK )
        handle_error(1);

    /* Do some computation here */

    retval = PAPI_hl_region_end("computation");   //(4)
    if ( retval != PAPI_OK )
        handle_error(1);
}
~~~
- The comments with number (1-4) are the basic parts add to your code to use papi hl api to collect performance data, you can add others as needed.

The output file `rank_xxxxx` like:

~~~
{
  "cpu in mhz":"1416",
  "threads":[
    {
      "id":"18470",
      "regions":[
        {
          "computation":{
            "region_count":"1",
            "cycles":"397839932",
            "perf::TASK-CLOCK":"16571689677",
            "PAPI_TOT_INS":"17280998071",
            "PAPI_TOT_CYC":"29496779176"
          }
        }
      ]
    }
  ]
}

~~~

## Convert json-style output file to csv

The output is json style and here is snippet I use to convert the json output to dataframe and save as .csv file:

~~~ python
import subprocess

import json
import pandas as pd
import os
from pandas.io.json import json_normalize   # help un-nest the layers in jason

path = './output/papi_hl_output'  # dir of saving papi out result
if not os.path.exists(path):
    os.makedirs(path)

dict_data = {}

def read_papi_rec(path):
        file_name = os.listdir(path)[0]
        file_path = os.path.join(path, file_name)

        with open(str(file_path)) as json_file:
            rec = json.load(json_file)

        df = json_normalize(rec['threads'][0]['regions'])
        df_0 = df.iloc[0]
        return df_0

for i in range(3):
        subprocess.call("./tiling_alpha", shell=True)  # testing purpose
        dict_key = 'iter' + str(i)  # define key as needed
        df_0 = read_papi_rec(path)
        dict_data[dict_key] = df_0

df_saved = pd.DataFrame.from_dict(dict_data, orient='index')
df_saved.to_csv('papi_data.csv')
~~~



