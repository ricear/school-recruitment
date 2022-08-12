---
sidebar_position: 4
---

## 1 前言

1. 缓冲池设计的目的是为了**协调 CPU 速度与磁盘速度的鸿沟**，因此**页的操作首先都是在缓冲池中完成的**。
2. 如果一条**DML 语句**，如 `UPDATE` 或 `DELETE`**改变了页中的记录**，那么此时**页是脏的**，即**缓冲池中的页的版本要比磁盘的新**，**数据库需要将新版本的页从缓冲池刷新到磁盘**。
3. **倘若每次一个页发生变化**，**就将新页的版本刷新到磁盘**，那么**这个开销是非常大的**，**若热点数据集中在某几个页中**，那么**数据库的性能将变得非常差**，同时，**如果在从缓冲池将页的新版本刷新到磁盘时发生了宕机**，那么**数据就不能恢复了**。
4. 为了**避免**发生**数据丢失**的问题，当前事务数据库系统普遍都采用了**WAL**（Write Ahead Log）策略，即**当事务提交时**，**先写[重做日志](https://notebook.grayson.top/project-37/doc-740/#2-Redo-Log)**（Redo Log），**再修改页**，**当由于发生宕机而导致数据丢失时**，**通过重做日志来完成数据的恢复**，这也是[事务 ACID](https://notebook.grayson.top/project-37/doc-714/#2-%E4%BA%8B%E5%8A%A1%E7%9A%84%E7%89%B9%E6%80%A7)中[D](https://notebook.grayson.top/project-37/doc-714/#2-4-%E6%8C%81%E4%B9%85%E6%80%A7)（Durability，持久性）的要求。

## 2 为什么需要 Checkpoint 技术

1. 思考下面的场景，如果**重做日志可以无限的做大**，同时**缓冲池也足够大**，**能够缓冲所有数据库的数据**，那么是**不需要将缓冲池页的新版本刷新回磁盘**，因为**当发生宕机时**，完全**可以通过重做日志来恢复整个数据库系统中的数据到宕机发生的时刻**，但是这需要**两个前提条件**：
   1. **缓冲池可以缓存数据库中所有的数据**。
      1. 有经验的用户都知道，当数据库开始建的时候，表中没有任何数据，缓冲池的确可以缓存所有的数据库文件。
      2. 然而随着市场的推广，用户的增加，产品越来越受到关注，使用量也越来越大，这时负责后台存储的数据库的容量注定会不断增大。
      3. 当前 3TB 的 MySQL 数据库已并不少见，但是 3TB 的内存却非常少见，因此这一假设**对于生产环境应用中的数据库是很难得到保证**的。
   2. **重做日志可以无限增大**。
      1. 这个也许是可以的，但是对**成本要求太高**，同时**不便于运维**，因为我们**不知道什么时候重做日志是否已接近于磁盘可使用空间的阈值**，并且要**让存储设备支持可动态扩展也是需要一定的技巧和设备支持**的。
2. 即使上面两个条件都满足，那么还有一个条件需要考虑，那就是**宕机后数据库的恢复时间**，当数据库运行了几个月甚至几年时，这时发生宕机，重新应用重做日志的时间会非常久，此时恢复的代价也会非常大，此时，就需要使用 Checkpoint（检查点）技术了。

## 3 解决的主要问题

Checkpoint 技术的目的是解决以下几个问题：

1. **缩短数据库的恢复时间**。
   1. 当**数据库发生宕机**时，**数据库不需要重做所有的日志**，因为**Checkpoint 之前的页都已经刷新回磁盘**，故数据库**只需对 Checkpoint 后的重做日志进行恢复**，这样就**大大缩短了恢复的时间**。
2. **缓冲池不够用时**，**将脏页刷新到磁盘**。
   1. 当**缓冲池不够用时**，**根据 LRU 算法会溢出最近最少使用的页**，**若此页为脏页**，**那么需要强制执行 Checkpoint**，**将脏页也就是页的新版本刷回磁盘**。
3. **重做日志不可用时**，**刷新脏页**。
   1. **重做日志不可用的情况是因为当前事务数据库系统对重做日志的设计都是循环使用的**，**并不是让其无限增大的**，**这从成本及管理上都是比较困难的**。
   2. **重做日志可以被重用的部分是指这些重做日志已经不再需要**，即**当数据库发生宕机时**，**数据库恢复操作不需要这部分的重做日志**，因此**这部分就可以被覆盖重用**。
   3. **若此时重做日志还需要使用**，那么**必须强制产生 Checkpoint**，**将缓冲池中的页至少刷新到当前重做日志的位置**。

## 4 分类

在 InnoDB 存储引擎中，Checkpoint 发生的时间、条件及脏页的选择等都非常复杂，而**Checkpoint 所做的事情无外乎是将缓冲池中的脏页刷回到磁盘**，不同之处在于**每次刷新多少页到磁盘**，**每次从哪里取脏页**，以及**什么时间触发 Checkpoint**，在 InnoDB 引擎内部，有**两种 Checkpoint**，分别为**Sharp Checkpoint**、**Fuzzy Checkpoint**。

### 4.1 Sharp Checkpoint

**Sharp Checkpoint**发生在**数据库关闭时将所有的脏页都刷新回磁盘**，这是**默认的工作方式**，即参数 `innodb_fast_shutdown = 1`。

### 4.2 Fuzzy Checkpoint

如果数据库在运行时也使用 Sharp Checkpoint，那么数据库的可用性就会受到很大的影响，因此在 InnoDB 存储引擎内部使用**Fuzzy Checkpoint**进行页的刷新，即**只刷新一部分脏页**，**而不是刷新所有的脏页回磁盘**，在 InnoDB 存储引擎内部可能发生如下几种情况的 Fuzzy Checkpoint：

1. Master Thread Checkpoint.
2. FLUSH_LRU_LIST Checkpoint.
3. Async/Sync Flush Checkpoint.
4. Dirty Page too much Checkpoint.

#### 4.2.1 Master Thread Checkpoint

1. 对于**Master Thread 中发生的 Checkpoint**，差不多**以每秒或每十秒的速度从缓冲池的脏页列表中刷新一定比例的页回磁盘**，这个过程是**异步**的，即此时**InnoDB 存储引擎可以进行其他的操作**，**用户查询线程不会阻塞**。

#### 4.2.2 FLUSH_LRU_LIST Checkpoint

1. **FLUSH_LRU_LIST Checkpoint**是因为**InnoDB 存储引擎需要保证 LRU 列表中需要有差不多 100 个空闲页可供使用**。
2. 在**InnoDB 1.1.x 版本之前**，需要**检查 LRU 列表中是否有足够的空间**，这个操作**发生在用户查询线程**中，显然**会阻塞用户的查询操作**，**倘若没有 100 个可用空闲页**，那么 InnoDB 存储引擎会**将 LRU 列表尾端的页移除**，**如果这些页中有脏页**，那么**需要进行 Checkpoint**，而这些页是来自 LRU 列表的，因此也称为 FLUSH_LRU_LIST Checkpoint。
3. 而从**MySQL 5.6**版本，也就是**InnoDB 1.2.x**版本开始，这个**检查被放在了一个单独的 Page Cleaner 线程中进行**，并且用户可以通过参数 `innodb_lru_scan_depth` 控制 LRU 列表中可用页的数量，该值默认为 1024。
   
   ```shell
   mysql> show variables like 'innodb_lru_scan_depth%';
   +-----------------------+-------+
   | Variable_name         | Value |
   +-----------------------+-------+
   | innodb_lru_scan_depth | 1024  |
   +-----------------------+-------+
   ```

#### 4.2.3 Async/Sync Flush Checkpoint

1. **Async/Sync Flush Checkpoint**指的是[**重做日志文件不可用**](#3-解决的主要问题)的情况，这时**需要强制将一些页刷新回磁盘**，而此时**脏页是从脏页列表中选取的**。
2. 若将已经写入到重做日志的 LSN 记为 $redo\_lsn$，将已经刷回磁盘最新页的 LSN 记为 $checkpoint\_lsn$，则可定义：
   
   $$
   checkpoint\_age = redo\_lsn - checkpoint\_lsn
   $$
   
   再定义以下的变量：
   
   $$
   async\_watermark = 75\% * total\_redo\_log\_file\_size
   $$
   
   $$
   sync\_watermark = 75\% * total\_redo\_log\_file\_size
   $$
3. 若每个重做日志文件的大小为 1GB，并且定义了两个重做日志文件，则重做日志文件的总大小为 2GB，那么 $async\_watermark = 1.5GB$，$sync\_watermark = 1.8GB$，则：
   
   1. 当 $checkpoint\_age < async\_watermark$ 时，不需要刷新任何脏页到磁盘。
   2. 当 $async\_watermark < checkpoint\_age < sync\_watermark$ 时触发 Async Flush，从 Flush 列表中刷新足够的脏页回磁盘，使得刷新后满足 $checkpoint\_age < async\_watermark$。
   3. $checkpoint\_age > sync\_watermark$ 这种情况一般很少发生，除非设置的重做日志文件太小，并且在进行类似 LOAD DATA 的 BULK INSERT 操作，此时触发 Sync Flush 操作，从 Flush 列表中刷新足够的脏页回磁盘，使得刷新后满足 $checkpoint\_age < async\_watermark$。
4. 可见，Async/Sync Flush Checkpoint 是为了**保证重做日志的循环使用的可用性**。
5. 在**InnoDB 1.2.x 版本之前**，**Async Flush Checkpoint 会阻塞发现问题的用户查询线程**，而**Sync Flush Checkpoint 会阻塞所有的用户查询线程**，并且**等待脏页刷新完成**。
6. 从**InnoDB 1.2.x**，也就是**MySQL 5.6**版本开始，这部分的**刷新操作**同样**放入到了单独的 Page Cleaner Thread 中**，因此**不会阻塞用户查询线程**。

#### 4.2.4 Dirty Page too much Checkpoint

1. 这种情况是因为**脏页的数量太多**，导致 InnoDB 存储引擎**强制进行 Checkpoint**，其目的总的来说还是**为了保证缓冲池中有足够可用的页**，其可由参数 `innodb_max_dirty_pages_pct` 控制，具体如下：
   
   ```
   mysql> show variables like 'innodb_max_dirty_pages_pct%';
   +--------------------------------+-----------+
   | Variable_name                  | Value     |
   +--------------------------------+-----------+
   | innodb_max_dirty_pages_pct     | 90.000000 |
   | innodb_max_dirty_pages_pct_lwm | 0.000000  |
   +--------------------------------+-----------+
   ```
   
   `innodb_max_dirty_pages_pct` 的值为 90 表示**当缓冲池中脏页的数量占据 90% 时**，**强制进行 Checkpoint**，**刷新一部分的脏页到磁盘**。

## 参考文献

1. 《MySQL 技术内幕（InnoDB 存储引擎）第 2 版》

