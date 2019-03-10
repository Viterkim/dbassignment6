# DB Assignment 6 (Performance)
Made by Viktor Kim Christiansen, Chris Rosendorf & William Pfaffe
# Overview
School assignment with focus on performance with sample databases.
1. Run the DB with Docker `docker run --rm --name my_mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=tropaadet -d mysql:latest`
2. Connect with Workbench to `localhost` with `tropaadet` as the password¨
3. Import the base databases `classicmodels.sql` & `stackflow.sql` in workbench. (Left panel -> Data Import/Reuse -> Import from Self-Container File -> Start Import)
4. Paste in the queries
5. WHEN YOU ARE DONE: Stop & Remove the Docker container ``docker stop my_mysql`

Overview of classicmodels
![classicmodels](classicmodels.png "classicmodels")


# Prequisites
We were unable to import the StackExchange files into our Docker Container. We resorted to running it outside a container, running the following command after having downloaded the xml files onto our droplet:

```
create database stackoverflow DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

use stackoverflow;

create table badges (
  Id INT NOT NULL PRIMARY KEY,
  UserId INT,
  Name VARCHAR(50),
  Date DATETIME
);

CREATE TABLE comments (
    Id INT NOT NULL PRIMARY KEY,
    PostId INT NOT NULL,
    Score INT NOT NULL DEFAULT 0,
    Text TEXT,
    CreationDate DATETIME,
    UserId INT NOT NULL
);

CREATE TABLE post_history (
    Id INT NOT NULL PRIMARY KEY,
    PostHistoryTypeId SMALLINT NOT NULL,
    PostId INT NOT NULL,
    RevisionGUID VARCHAR(36),
    CreationDate DATETIME,
    UserId INT NOT NULL,
    Text TEXT
);
CREATE TABLE post_links (
  Id INT NOT NULL PRIMARY KEY,
  CreationDate DATETIME DEFAULT NULL,
  PostId INT NOT NULL,
  RelatedPostId INT NOT NULL,
  LinkTypeId INT DEFAULT NULL
);


CREATE TABLE posts (
    Id INT NOT NULL PRIMARY KEY,
    PostTypeId SMALLINT,
    AcceptedAnswerId INT,
    ParentId INT,
    Score INT NULL,
    ViewCount INT NULL,
    Body text NULL,
    OwnerUserId INT NOT NULL,
    LastEditorUserId INT,
    LastEditDate DATETIME,
    LastActivityDate DATETIME,
    Title varchar(256) NOT NULL,
    Tags VARCHAR(256),
    AnswerCount INT NOT NULL DEFAULT 0,
    CommentCount INT NOT NULL DEFAULT 0,
    FavoriteCount INT NOT NULL DEFAULT 0,
    CreationDate DATETIME
);

CREATE TABLE tags (
  Id INT NOT NULL PRIMARY KEY,
  TagName VARCHAR(50) CHARACTER SET latin1 DEFAULT NULL,
  Count INT DEFAULT NULL,
  ExcerptPostId INT DEFAULT NULL,
  WikiPostId INT DEFAULT NULL
);


CREATE TABLE users (
    Id INT NOT NULL PRIMARY KEY,
    Reputation INT NOT NULL,
    CreationDate DATETIME,
    DisplayName VARCHAR(50) NULL,
    LastAccessDate  DATETIME,
    Views INT DEFAULT 0,
    WebsiteUrl VARCHAR(256) NULL,
    Location VARCHAR(256) NULL,
    AboutMe TEXT NULL,
    Age INT,
    UpVotes INT,
    DownVotes INT,
    EmailHash VARCHAR(32)
);

CREATE TABLE votes (
    Id INT NOT NULL PRIMARY KEY,
    PostId INT NOT NULL,
    VoteTypeId SMALLINT,
    CreationDate DATETIME
);

SET GLOBAL local_infile = 1;

load XML local infile '/home/Badges.xml'
into table badges
rows identified by '<row>';

load XML local infile '/home/Comments.xml'
into table comments
rows identified by '<row>';

load XML local infile '/home/PostHistory.xml'
into table post_history
rows identified by '<row>';

load XML local infile '/home/PostLinks.xml'
into table post_links
rows identified BY '<row>';

load XML local infile '/home/Posts.xml'
into table posts
rows identified by '<row>';

load XML local infile '/home/Tags.xml'
into table tags
rows identified BY '<row>';

load XML local infile '/home/Users.xml'
into table users
rows identified by '<row>';

load XML local infile '/home/Votes.xml'
into table votes
rows identified by '<row>';

create index badges_idx_1 on badges(UserId);

create index comments_idx_1 on comments(PostId);
create index comments_idx_2 on comments(UserId);

create index post_history_idx_1 on post_history(PostId);
create index post_history_idx_2 on post_history(UserId);

create index posts_idx_1 on posts(AcceptedAnswerId);
create index posts_idx_2 on posts(ParentId);
create index posts_idx_3 on posts(OwnerUserId);
create index posts_idx_4 on posts(LastEditorUserId);

create index votes_idx_1 on votes(PostId);

ALTER TABLE `stackoverflow`.`posts` 
ADD COLUMN `Comments` JSON NULL AFTER `CreationDate`;
alter table comments modify Id int auto_increment;
```

The files were extracted onto root/home/[FILES HERE]


## Exc 1 
### In the classicmodels database, write a query that picks out those customers who are in the same city as office of their sales representative.
```
SELECT customers.* FROM customers
INNER JOIN employees ON employees.employeeNumber = customers.salesRepEmployeeNumber
INNER JOIN offices ON offices.officeCode = employees.officeCode
WHERE customers.city = offices.city
```
![Execution Plan1](exc1/plan1.png "Execution Plan1")

### What is the main performance problem for this query
We see the biggest prefix cost at the `Non-Unique Key Lookup for customers salesRepEmployeeNumber`


## Exc 2
### Change the database schema so that the query from exercise get better performance.

```
Create index office_city ON offices (city);
Create index customer_city ON customers (city);
```

![Execution Plan2](exc2/plan2.png "Execution Plan2")

### Explain in the readme file what changes you did, if you changed the query or the schema
We add indexes for office_city on the office table & customer_city on the customer table. That way we can circumvent the salesRepEMployeeNumber lookup, and just use the unique indexes the cities give us instead, as well as the employees primary key.

## Exc 3

### We want to find out how much each office has sold and the max single payment for each office. Write two queries which give this information

1. using grouping
```
SELECT offices.officeCode, sum(payments.amount) as paymentPrice, max(payments.amount) as maxSingle FROM payments
INNER JOIN customers ON payments.customerNumber = customers.customerNumber
INNER JOIN employees ON customers.salesRepEmployeeNumber = employees.employeeNumber
INNER JOIN offices ON employees.officeCode = offices.officeCode
GROUP BY offices.officeCode
ORDER BY paymentPrice DESC;

```
## Exc 4
### In the stackexchange forum for coffee (coffee.stackexchange.com), write a query which return the displayName and title of all posts which with the word groundsin the title.
```
SELECT DisplayName, Title FROM posts INNER JOIN users ON posts.OwnerUserId = users.Id where Title LIKE '%grounds%' 
```
![Execution Plan2](/exc4/opg4.png "Execution Plan2")
## Exc 5
### Add a full text index to the posts table and change the query from exercise 4 so it no longer scans the entire posts table.
In order to create the index use the following script:
```
ALTER TABLE posts  
ADD FULLTEXT(Title)
```

And then run:

```
SELECT DisplayName, Title FROM posts INNER JOIN users ON posts.OwnerUserId = users.Id WHERE MATCH(Title) AGAINST ('grounds' IN natural language mode)
```
