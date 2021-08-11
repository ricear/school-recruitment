#!bin/bash

# 常量定义
# 项目根目录
BASE_DIR=/Users/weipeng/Personal/Projects/ComputerCookbook-SchoolRecruitment

echo "0. 进入项目根目录"
cd ${BASE_DIR}

echo "1. 生成静态文件"
cd ${BASE_DIR}/exampleSite
hugo --themesDir ../themes -b https://books.grayson.top/school-recruitment
cd ${BASE_DIR}

echo "2. 将静态文件夹名称修改为 school-recruitment"
rm -f ${BASE_DIR}/exampleSite/public/favicon.png
cp ${BASE_DIR}/static/favicon.png ${BASE_DIR}/exampleSite/public/

echo "3. 提交本地更新"
git config --global http.version HTTP/1.1
git add -A ./
git commit -a -m 自动备份
git push origin

echo "4. 服务器更新文件"
ssh root@cloudserver "cd /usr/local/projects/ComputerCookbook-SchoolRecruitment;git pull;rm -rf /www/wwwroot/books.grayson.top/school-recruitment.bak;mv /www/wwwroot/books.grayson.top/school-recruitment /www/wwwroot/books.grayson.top/school-recruitment.bak;cp -R exampleSite/public /www/wwwroot/books.grayson.top/school-recruitment"
