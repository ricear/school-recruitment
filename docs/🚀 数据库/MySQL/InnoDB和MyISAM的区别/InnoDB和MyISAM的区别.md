---
sidebar_position: 3
---

存储引擎主要用于从数据库中读取数据，MySQL 支持很多[存储引擎](https://dev.mysql.com/doc/refman/8.0/en/storage-engines.html)，但是 MyISAM 和 InnoDB 是使用最广泛的两个存储引擎，他们每一个都有各自的优缺点，因此选取一个适合我们应用的存储引擎来说非常重要。

> MySQL 5.5.5 之前的版本的默认存储引擎是 MyISAM，5.5.5 及其之后的版本的默认存储引擎是 InnoDB。

MyISAM 和 InnoDB 的主要区别包括**参照完整性**（Referential Integrity）、**事务和原子性**（Transactions & Atomicity）、**表锁定与行锁定**（Table-locking vs Row-locking）、**可靠性**（Reliability）、**全文索引**（FULLTEXT Indexing）、**缓存**（Caching）、**ACID 属性**（ACID property）七个方面。

## 1 参照完整性

1. 参照完整性**确保了表与表之间的关系的一致性**，比如一张表拥有指向另外一张表的外键，当被指向的表发生更改时，这些更改也会级联到链接表。
2. InnoDB 是一个关系型数据库管理系统（RDBMS），因此**InnoDB 支持外键和参照完整性**，包括**级联删除和更新**，但是**MyISAM 不支持外键**。

## 2 事务和原子性

1. **MyISAM 不支持事务**，但是**InnoDB 支持**。
2. 因此，当一张表**使用 MyISAM 引擎**并且**操作在执行的过程中被终止了**，**已经被更改的行将会被永久更改**，即使操作还没有完成，但是当一张表是**使用 InnoDB 引擎**并且**操作在执行的过程中被终止了**，因为使用了事务，因此**当我们提交之前**，**所有的更改将不会生效**。
3. 当我们**使用 MyISAM 引擎**时，**所有的更改不能回滚**，但是当我们**使用 InnoDB 引擎**时，**更改是可以被回滚的**。

## 3 表锁定和行锁定

1. 当在**MyISAM 引擎的表**中**执行一个查询时**，**整张表都会被锁定**，这意味着后续查询只能等到当前查询结束之后才会被执行，当我们正在读一张大表时，而且同时这张表会有其他频繁的读写操作，这可能导致大量的查询被积压。
2. 当在**InnoDB 引擎的表**中**执行一个查询时**，**只有相关的行才会被锁定**，**表中的其他行可以继续进行其他操作**，这意味着当查询不使用同一行时，可以在一个表上同时运行。

## 4 可靠性

1. **MyISAM 引擎不提供数据完整性**，比如**硬件损坏**（Hardware Failures）、**突然关机**（Unclean Shutdowns）或者**操作取消**（Canceled Operations）都**会导致数据损坏**，这就**需要对表进行完全修复或者重建索引和表**。
2. **InnoDB 引擎使用事务日志**（Transactional Log）、**双写缓冲区**（Double-Write Buffer）以及**自动校验和验证**（Automatic Checksum and Validation）**来防止数据损坏**，当 InnoDB**对数据进行更改之前**，他会**在事务之前把数据记录到一个名为 `ibdata1` 的系统表空间文件**（System Tablespace File），**如果 MySQL 服务器发生崩溃**，**InnoDB 将会根据这些日志来自动恢复数据**。

## 5 全文索引

1. **在 MySQL 5.6.4 版本之前 InnoDB 不支持全文索引**，**从 MySQL 5.6.4 版本 InnoDB 开始支持全文索引**。
2. **使用全文索引的 MyISAM 表不能转换为 InnoDB 表**。

## 6 缓存

1. **InnoDB 会将数据和索引都缓存在内存中**，**所有的更改会先写入到日志缓冲区**（Log Buffer），**然后再根据设置的策略**（根据 `innodb_flush_log_at_trx_commit` 来控制）**刷到日志文件中**，这种将数据保存在内存中的方式**对性能来说是一个巨大的提升**，但同时**需要的内存和存储也会更高**。
2. **MyISAM 只把索引缓存进内存**，因此相对于 InnoDB 来说**性能会稍微差一些**，但是**使用的内存和存储可能会更低一些**。

## 7 ACID 属性

**InnoDB 支持 ACID**（Atomicity, Consistency, Isolation, and Durability）**属性**，**即原子性、一致性、隔离性和持久性**，但是**MyISAM 不支持这些属性**。

## 参考文献

1. [Difference Between InnoDB and MyISAM](http://acmeextension.com/difference-between-innodb-and-myisam).

