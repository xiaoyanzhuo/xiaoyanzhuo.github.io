#!/bin/bash
#**************************************
# File Name: post.sh
# Author: Xiaoyan Zhuo
# Mail: Xiaoyan_Zhuo@student.uml.edu
# Created Time : 18 Sep 2018 23:25:08 
#**************************************
git add ./
git commit -a -m "new post at $(date)"
git pull origin master
git push origin master
