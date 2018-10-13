---
toc: true
toc_label: "MySQL 常用命令"
toc_icon: "copy"
title: "MySQL 常用命令"
tags: mysql 命令
categories: "mysql"
classes: wide
excerpt: ""
header:
  overlay_image: /assets/images/header/mysql.jpg
  overlay_filter: rgba(0, 0, 0, 0.8)
---





## 全局


### 登陆 MySQL

```bash
mysql -h host -u user -p
```

登陆时指定数据库名称：

```bash
mysql -h host -u user -p db_name
```



























## 管理操作





### 用户管理


#### 创建用户

```sql
CREATE USER 'hawk'@'%' IDENTIFIED BY 'password';
CREATE USER 'hawk'@'localhost' IDENTIFIED BY 'password'
CREATE USER 'hawk'@'192.168.1.101' DEFAULT ROLE administrator, developer;
CREATE USER 'hawk'@'localhost' WITH MAX_QUERIES_PER_HOUR 500 MAX_UPDATES_PER_HOUR 100;
CREATE USER 'hawk'@'localhost' PASSWORD EXPIRE INTERVAL 180 DAY;
```


#### 删除用户

```sql
DROP USER 'hawk'@'localhost';
```


#### 为用户分配权限

```sql
GRANT ALL ON db.* TO 'hawk'@'localhost';
GRANT ALL ON *.* TO 'hawk'@'localhost' IDENTIFIED BY ’something’ WITH GRANT OPTION;
GRANT SELECT,INSERT ON test.* TO 'hawk'@'%';
```


#### 撤消用户权限

```sql
REVOKE INSERT ON *.* FROM 'hawk'@'localhost';
REVOKE 'role1', 'role2' FROM 'hawk'@'localhost', 'user2'@'localhost';
REVOKE SELECT ON world.* FROM 'role3';
```


#### 为用户修改密码

```sql
SET PASSWORD FOR 'neo'@'%' = PASSWORD('password');
ALTER USER 'hawk'@'localhost' IDENTIFIED BY 'newpassword'
```




























## 数据定义





### 库操作



#### 创建库

```sql
CREATE DATABASE db_name;
CREATE DATABASE IF NOT EXISTS southwind;
```



#### 查看库的创建参数

```sql
SHOW CREATE DATABASE db_name
```



#### 查看库列表

```sql
SHOW DATABASES;
```



#### 配置默认库

切换到某个库，从而随后的命令都默认是针对该库进行操作的。

```sql
USE db_name;
```



#### 查看默认库

查看当前默认操作哪个库。

```sql
SELECT DATABASE();
```



#### 删除库

```sql
DROP DATABASE db_name
DROP DATABASE IF EXISTS southwind;
```

```bash
$ sudo mysqladmin -u root -p drop db_name
```






### 表操作



#### 查看当前库中的所有表

```sql
SHOW TABLES;
```



#### 查看表的结构

```sql
DESCRIBE tbl_name;
```



#### 创建表


##### 语法：

```sql
CREATE TABLE [IF NOT EXISTS] table_name(
    column_list
) ENGINE=storage_engine;
```

其中 column_list 的语法：

```sql
column_name data_type(length) [NOT NULL] [DEFAULT value] [AUTO_INCREMENT]
```


##### 范例：

###### 新建空表

```sql
CREATE TABLE IF NOT EXISTS tasks (
    task_id INT AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    start_date DATE,
    due_date DATE,
    status TINYINT NOT NULL,
    priority TINYINT NOT NULL,
    description TEXT,
    PRIMARY KEY (task_id)
)  ENGINE=INNODB;
```

```sql
CREATE TABLE IF NOT EXISTS products (
     productID    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
     productCode  CHAR(3)       NOT NULL DEFAULT '',
     name         VARCHAR(30)   NOT NULL DEFAULT '',
     quantity     INT UNSIGNED  NOT NULL DEFAULT 0,
     price        DECIMAL(7,2)  NOT NULL DEFAULT 99999.99,
     PRIMARY KEY  (productID)
   );
```


###### 从现有表创建

```sql
CREATE TABLE NewTable AS
SELECT name, age
FROM OldTable
WHERE age > 25;
```

原表中的数据会携带过来，相当于另存为新表。



#### 查看表的创建参数

```sql
SHOW CREATE TABLE tbl_name \G
```



#### 修改表参数


##### 增加字段

```sql
ALTER TABLE t2 ADD COLUMN
```


##### 删除字段

```sql
ALTER TABLE t2 DROP COLUMN c, DROP COLUMN d;
```


##### 修改字段

```sql
ALTER TABLE tbl_name
CHANGE COLUMN old_name new_name INT(11) NOT NULL AUTO_INCREMENT;
```


#### 删除表

```sql
DROP TABLE IF EXISTS tbl_name;
```




































## 附表





### 用户权限列表


#### 访问级别

即 Privilege Level。

* `*`
* `*.*`
* `db_name.*`
* `db_name.tbl_name`
* `tbl_name`
* `db_name.routine_name`


#### 可授予、可撤消的静态权限

权限 | 授权的操作 | 访问级别
--- | --- | ---
ALL [PRIVILEGES] | 所有权限，但不包括 GRANT OPTION 与 PROXY | 特定级别
ALTER | `ALTER TABLE` | 全局，库，表
ALTER ROUTINE | 修改、删除存储例程 | 全局，库，例程
CREATE | 创建库和表 | 全局，库，表
CREATE ROUTINE | 创建存储例程 | 全局，库
CREATE TABLESPACE | 创建、修改、删除表空间及日志文件组 | 全局
CREATE TEMPORARY TABLES | `CREATE TEMPORARY TABLE` | 全局，库
CREATE USER | `CREATE USER`，`DROP USER`，`RENAME USER`，`REVOKE ALL PRIVILEGES` | 全局
CREATE VIEW | 创建、修改视图 | 全局，库，表
DELETE | `DELETE` | 全局，库，表
DROP | 删除库、表、视图 | 全局，库，表
EVENT | 使用事件，用于事件调度 | 全局，库
EXECUTE | 执行存储例程 | 全局，库，例程
FILE | 用户可以让服务端读写文件 | 全局
GRANT OPTION | 为他人授予、撤消权限 | 全局，库，表，例程，代理
INDEX | 创建、删除索引 | 全局，库，表
INSERT | `INSERT` | 全局，库，表，字段
LOCK TABLES | `LOCK TABLES`，需有 `SELECT` 权限 | 全局，库
PROCESS | `SHOW PROCESSLIST` | 全局
PROXY | 用户代理 | 用户之间
REFERENCES | 创建外键 | 全局，库，表，字段
RELOAD | `FLUSH` 操作 | 全局
REPLICATION CLIENT | 用户可以查询哪些是主、从服务器 | 全局
REPLICATION SLAVE | 从服务器读取主服务器的 binlog | 全局
SELECT | `SELECT` | 全局，库，表，字段
SHOW DATABASES | `SHOW DATABASES` | 全局
SHOW VIEW | `SHOW CREATE VIEW` | 全局，库，表
SHUTDOWN | `mysqladmin shutdown` | 全局
SUPER | 其它管理操作，如 `CHANGE MASTER TO`，`KILL`，`PURGE BINARY LOGS`，`SET GLOBAL`，`mysqladmin` | 全局
TRIGGER | 触发器操作 | 全局，库，表
UPDATE | UPDATE | 全局，库，表，字段
USAGE | 无权限 |


#### 可授予、可撤消的动态权限

权限 | 说明 | 访问级别
--- | --- | ---
AUDIT_ADMIN | 配置审计日志 | 全局
BINLOG_ADMIN | 控制二进制日志 | 全局
CONNECTION_ADMIN | 控制连接限制 | 全局
ENCRYPTION_KEY_ADMIN | InnoDB 密钥轮换 | 全局
FIREWALL_ADMIN | 管理所有用户的防火墙规则 | 全局
FIREWALL_USER | 管理自己的防火墙规则 | 全局
GROUP_REPLICATION_ADMIN | 控制组复制 | 全局
REPLICATION_SLAVE_ADMIN | 控制普通复制 | 全局
ROLE_ADMIN | `WITH ADMIN OPTION` | 全局
SET_USER_ID | 为其他用户设置 `DEFINER` 值 | 全局
SYSTEM_VARIABLES_ADMIN | 修改或保持全局系统变量 | 全局
VERSION_TOKEN_ADMIN | Enable use of Version Tokens UDFs. | 全局