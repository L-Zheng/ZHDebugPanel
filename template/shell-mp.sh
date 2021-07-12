
echo '\n👉：拷贝到release文件夹\n'
rm -rf 'release'
mkdir -p 'release'
cp -R 'dist/' 'release/'
# cp -R 'pages.json' 'release/pages.json'
rm -rf 'release/favicon.ico'

cp -R 'static' 'dist/static'
cp -R 'static' 'release/static'
