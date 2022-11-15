set -e

npm run docs:build

cd docs/.vuepress/dist

cp -r ../../../.github ./

git init
git add -A
git commit -m "deploy"

git push -f git@github.com:Beareleven/Bear-s-Blog.git master:gh-pages
# git push -f git@gitee.com:saw-string/Bear-s-Blog.git master:gh-pages
# git push -f git@106.15.188.56:/home/www/website/ts.git master
git push -f git@39.108.58.119:/home/www/website/blog.git master

cd -