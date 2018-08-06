#!/bin/bash
#source /etc/profile
#source $HOME/.bash_profile
#set -e

LOG="/var/log/git/sync.log"


source $HOME/.keychain/${HOSTNAME}-sh

chk=$(command -v git)
len=${#chk}

if [[ $len == 0 ]]
  then 
    sudo echo "$1 is not found. Script ended." ; exit 11 >> ${LOG}
fi




REPO='/home/liloli/linotes'
COMMIT_TIMESTAMP=`date +'%Y-%m-%d %H:%M:%S %Z'`
DATELOG=`date +'%Y.%m.%d %H:%M:%S'`

sudo echo -e "== ${DATELOG} ==============================\n" >> ${LOG}

if [ ! -d ${REPO}/.git ]
  then
    sudo echo "${REPO} is not a valid git repo! Aborting..." >> ${LOG}
    exit 0
  else
    cd ${REPO}

    sudo echo -e "\n\n.........................  jekyll buid  ....... \n\n" >> ${LOG}
    /home/liloli/gems/wrappers/jekyll build >> ${LOG} 2>&1

    sudo echo -e "\n\n..........................    git add   ....... \n\n" >> ${LOG}
    /usr/bin/git  add -A >> ${LOG} 2>&1

    sudo echo -e "\n\n.........................  git commit  ....... \n\n" >> ${LOG}
    /usr/bin/git  commit -m "update on ${COMMIT_TIMESTAMP}" >> ${LOG} 2>&1

    sudo echo -e "\n\n.........................   git push  .......\n\n" >> ${LOG}
    /usr/bin/git push >> ${LOG} 2>&1

    sudo echo -e "\n\n============================== git sync finished =====\n\n\n" >> ${LOG}
fi
