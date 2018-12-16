#!/bin/bash

hexo clean
hexo generate 
hexo deploy

( cd ~/git/hexo_static ; git pull ; git push origin master ; cp -r ~/git/hexo_static/ /var/www/hexo/)
