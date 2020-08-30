#!/bin/bash

command=$(
cat <<-EOF
        echo 'step1: enter project path'
        if [ ! -d '/usr/local/opt/hexo/source/_posts' ]; then
          echo 'error: project uninitialized' && exit
        fi
        cd /usr/local/opt/hexo/source/_posts && pwd

        echo 'step2: get project'
        if [ ! -d '/usr/local/opt/hexo/source/_posts/.git' ]; then
          cd ../
          echo 'clone project'
          git clone https://$REPOSITORY_USER:$REPOSITORY_PASSWORD@$PROJECT_ADDRESS
          rm -rf _posts && mv Markdown/ _posts/ && cd _posts
        else
          echo 'project exist'
          git checkout . && git clean -fd && git checkout master
        fi

        echo 'step3: update project'
        git fetch origin && git reset --hard origin/master && git push origin master

        echo 'check hexo server status'
        ps | grep hexo
        process=\$(ps | grep hexo | grep -v grep | wc -l)
        echo "\$process hexo process running"

        echo 'step4: generate static files and start hexo server'
        hexo clean
        hexo generate

        if [[ \$process -lt 1 ]]; then
            echo 'starting hexo server'
            nohup hexo server >> /dev/null 2>&1 &
        fi

        echo 'end'
        exit
EOF
)

docker exec hexo sh -c "$command"
