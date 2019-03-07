docker run --rm --name my_mysql -v $(pwd)/mysql_databasefiles:/var/lib/mysql -v $(pwd)/mysql_databasefiles/xmlimport/xmlimport.cnf:/etc/mysql/conf.d/xmlimport.cnf -p 3306:3306 -e MYSQL_ROOT_PASSWORD=tropaadet -d mysql:latest

docker run --rm --name my_mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=tropaadet -d mysql:latest
