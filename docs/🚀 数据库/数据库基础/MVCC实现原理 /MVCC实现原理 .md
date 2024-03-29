---
sidebar_position: 5
---

## 含义

1. MVCC 是**在并发访问数据库时**，通过**对数据做多版本管理**，**避免因为写锁的阻塞而造成数据的并发阻塞问题**。
2. 通俗的讲就是 MVCC**通过保存数据的历史版本**，**根据比较版本号来处理数据的是否显示**，**从而达到读取数据的时候不需要加锁就可以保证事务隔离性的效果**。

## 核心知识点

### 事务版本号

1. **每次事务开启前都会从数据库获得一个自增长的事务 ID**，可以从事务 ID**判断事务执行的先后顺序**。

### 隐藏列

1. **DB_TRX_ID：** 记录**操作该数据事务的事务 ID**。
2. **DP_POLL_PTR：** 指向**上一个版本数据在 Undo Log 里的位置指针**。
3. **DB_ROW_ID：隐藏 ID**，**当建表没有合适的索引作为聚集索引时**，**会用该隐藏 ID 创建聚集索引**。

### Undo Log

#### 含义

1. Undo Log 主要用于**记录数据被修改之前的日志**，在**表信息修改之前会先把数据拷贝到 Undo Log 里**，在**事务进行回滚时可以通过 Undo Log 里的日志进行数据还原**，具体可参考[Undo Log](https://ricear.com/project-37/doc-740/#3-Undo-Log)。

#### 用途

1. **保证事务进行 `ROLLBACK` 时的原子性和一致性**，**当事务进行回滚的时候可以用 Undo Log 的数据进行恢复**。
2. 在**MVCC 版本控制**中，通过**读取 Undo Log 的历史版本数据**可以**实现不同事务版本号都拥有自己独立的快照数据版本**。

#### 事务的版本号、隐藏列、Undo Log 的关系

我们模拟一次数据修改的过程来了解下事务版本号、隐藏列和 Undo Log 他们之间的关系：

1. 首先准备一张原始数据表 `user_info`：
   ![](https://notebook.ricear.com/media/202107/2021-07-01_121234.png)

2. 参考文献开启一个事务 $A$，对 `user_info` 表执行 `update user_info set name = '李四' where id = 1`，这个过程的详细流程如下：

   1. 首先获得一个事务编号 104。
   2. 把`user_info` 表修改前的数据拷贝到 Undo Log。
   3. 修改`user_info` 表`id = 1` 的数据。
   4. 把修改后的数据事务版本号改成当前事务版本号，并把`DB_ROLL_PTR` 地址指向 Undo Log 数据地址。

3. 最后执行完结果如下图所示：

   ![](https://notebook.ricear.com/media/202107/2021-07-01_121348.png)

### Read View

#### 含义

1. 在 InnoDB 中**每个 SQL 语句执行前都会得到一个 Read View**，**主要保存了当前数据库系统中正处于活跃**（**没有 Commit**）**的事务的 ID 号**。
2. 简单的说就是**保存系统中当前不应该被本事务看到的其他事务 ID 列表**。

#### 属性

1. `trx_ids`：**当前系统活跃**（未提交）**事务版本号集合**。
2. `low_limit_id`：**创建当前 Read View 时当前系统最大事务版本号 +1**。
3. `up_limit_id`：**创建当前 Read View 时系统正处于活跃事务最小版本号**。
4. `creator_trx_id`：**创建当前 Read View 的事务版本号**。

#### 匹配条件

##### 数据事务 ID < up_limit_id 则显示

如果**数据事务 ID 小于 Read View 中的最小活跃事务 ID**，则可以肯定该**数据是在当前事务开启之前就已经存在了的**，所以**可以显示**。

##### 数据事务 ID >= low_limit_id 则不显示

如果**数据事务 ID 大于 Read View 中当前系统的最大事务 ID**，则说明该**数据是在当前 Read View 创建之后才产生的**，所以数据**不予显示**。

##### up_limit_id <= 数据事务 ID < low_limit_id，则与活跃事务集合 trx_ids 里匹配

如果**数据的事务 ID 大于最小的活跃事务 ID**，同时**又小于等于系统最大的事务 ID**，这种情况就说明这个数据有可能是在当前事务开始的时候还没有提交的，所以此时我们就需要把数据的事务 ID 与当前 Read View 中的活跃事务稽核 `trx_ids` 匹配。

1. 如果**事务 ID 不存在于 `trx_ids` 集合**，则说明**Read View 产生的时候事务已经 Commit 了**，这种情况数据则**可以显示**。
2. 如果事务 ID**存在于 `trx_ids` 集合**，则说明**Read View 产生的时候数据还没有提交**：
   1. 如果**数据事务 ID 等于 `creator_trx_id`**，那么说明这个**数据就是当前事务自己生成的**，自己生成的数据自己当然能看见，所以这种情况下数据也是**可以显示**的。
   2. 如果**数据事务 ID 不等于 `creator_trx_id`**，那么说明**Read View 产生的时候事务还没有提交**，又不是自己生成的，所以这种情况下数据**不能显示**。

##### 不满足 Read View 条件的时候，从 Undo Log 里面获取数据

当**数据事务 ID 不满足 Read View 条件**的时候，**从 Undo Log 里面获取数据的历史版本**，然后**根据数据的历史版本号回头再和 Read View 条件匹配**，**直到找到一条满足条件的历史数据**，**或者找不到则返回空结果**。

## InnoDB 实现 MVCC 的原理

![](https://notebook.ricear.com/media/202107/2021-07-01_144830.png)

1. 创建`user_info` 表，插入一条初始化数据。![](https://notebook.ricear.com/media/202107/2021-07-01_144907.png)

2. 事务 $A$ 和事务 $B$ 同时对 `user_info` 进行修改和查询操作：

   1. 事务 $A$：`update user_info set name = '李四';`
   2. 事务 $B$：`select * from user_info where id = 1;`

3. 先开启事务 $A$，在事务 $A$ 修改数据后但未进行 Commit，此时执行事务 B，在这期间产生的具体流程如下：
   ![](https://notebook.ricear.com/media/202107/2021-07-01_151059.png)

   1. 事务 $A$：**开启事务**，首先**得到一个事务编号**102。

   2. 事务 $B$：**开启事务**，**得到事务编号**103。

   3. 事务 $A$：**进行修改操作**，首先**把原数据拷贝到 Undo Log**，然后**对数据进行修改**，**标记事务编号和上一个数据版本在 Undo Log 的地址**。

      ![](https://notebook.ricear.com/media/202107/2021-07-01_145538.png)

   4. 事务 $B$：此时**事务 $B$ 获得一个 Read View**，Read View 对应的值如下：

      ![](https://notebook.ricear.com/media/202107/2021-07-01_150519.png)

   5. 事务 $B$：**执行查询语句**，此时**得到的是事务 $A$ 修改后的数据**：

      ![](https://notebook.ricear.com/media/202107/2021-07-01_150613.png)

   6. 事务 $B$：**把数据与 Read View 进行匹配**，事务 ID 为 102：

      1. 不小于`up_limit_id`。
      2. 小于`low_limit_id`。
      3. 存在于`trx_ids`。
      4. 不等于`creator_trx_id`。

   7. 发现**不满足 Read View 条件**，所以**从 Undo Log 获取历史版本的数据**，然后再**和 Read View 进行匹配**，最后返回数据如下：

      ![](https://notebook.ricear.com/media/202107/2021-07-01_151019.png)

## 各种事务隔离级别下的 Read View 的工作方式

事务隔离级别的详细信息可参考[事务隔离级别](https://ricear.com/project-37/doc-714/#2-3-3-%E4%BA%8B%E5%8A%A1%E7%9A%84%E9%9A%94%E7%A6%BB%E7%BA%A7%E5%88%AB%E6%9C%89%E5%93%AA%E4%BA%9B)。

### Read Commit

在**读提交**级别下同一事务里面的**每一次查询都会获得一个新的 Read View 副本**，这样就**可能造成同一个事务里前后读取数据可能不一致的问题**（重复读）。

![](https://notebook.ricear.com/media/202107/2021-07-01_152552.png)

### Repetable Read

在**可重复读**级别下同一事务里面**只会获取一次Read View副本**，从而保证**每次查询的数据都是一样的**，因此在可重复读级别下**不存在幻读问题**。

![](https://notebook.ricear.com/media/202107/2021-07-01_153205.png)

### Read Uncommitted

在**读未提交**级别下事务**不会获取Read View副本**。

## 快照读和当前读

### 快照读

1. 快照读是指**读取数据时不是读取最新版本的数据**，而是**基于历史版本读取的一个快照信息**（MySQL读取Undo Log历史版本）。
2. 快照读可以**使普通的 `SELECT`读取数据时不用对表数据进行加锁**，从而**解决了因为对数据库表加锁而导致的两个问题**：
   1. 解决了**因加锁导致的修改数据时无法对数据进行读取的问题**。
   2. 解决了**因加锁导致的读取数据时无法对数据进行修改的问题**。
3. 快照读**可以避免幻读问题**。
4. 快照读包括的操作主要包括：
   1. `SELECT`。

### 当前读

1. 当前读是**读取数据库最新的数据**。
2. 当前读和快照读不同，因为要**读取最新的数据**，而且要**保证事务的隔离性**，所以当前读是**需要加锁**的。
3. 在当前读的情况下**需要使用间隙锁来解决幻读问题**。
4. 当前读包括的操作主要包括：
   1. `UPDATE`。
   2. `DELETE`。
   3. `INSERT`。
   4. `SELECT ... LOCK IN SHARE MODE`。
   5. `SELECT ... FOR UPDATE`。

## 参考文献

1. [数据库基础（四）Innodb MVCC 实现原理](https://zhuanlan.zhihu.com/p/52977862)。