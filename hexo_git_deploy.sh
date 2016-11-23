#!/bin/bash

hexo clean
hexo generate 
hexo deploy

( cd ~/hexo_static ; git pull ; git push live master ; cp -r ~/hexo_static/ /var/www/hexo/)
