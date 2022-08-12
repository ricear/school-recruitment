---
sidebar_position: 2
---

## 1 HashMap

### 1.1 简介

1. Java 为数据结构中的映射定义了一个接口 `java.util.Map`，此接口主要有四个常用的实现类，分别是**HashMap**、**HashTable**、**LinkedHashMap**和**TreeMap**，类继承关系如下图所示：![](https://notebook.grayson.top/media/202107/2021-07-28_1649030.15704050584702112.png)
2. 下面针对各个实现类的特点做一些说明：
   1. **HashMap**：
      1. **根据键的 `hashCode` 值存储数据**，**大多数情况下可以直接定位到他的值**，**因而具有很快的访问速度**，**但遍历顺序却是不确定的**。
      2. **最多只允许一条记录的键为 `null`**，**允许多条记录为 `null`**。
      3. **非线程安全**，**任一时刻可以有多个线程同时写 HashMap**，**可能会导致数据的不一致**。
      4. **如果需要满足线程安全**，**可以用 Collections 的 `synchronizedMap()` 方法**（该方法也是使用一个全局锁来同步多个线程间的并发访问）**使 HashMap 具有线程安全能力**，**或者使用 ConcurrentHashMap**。
   2. **HashTable**：
      1. **HashTable 是遗留类**，**很多映射的常用功能与 HashMap 类似**，**不同的是他继承自 Dictionary 类**，**并且是线程安全的**：
         1. HashTable**线程安全的策略实现代价比较大**，简单粗暴，`get/put`**所有相关的操作都是 `synchronized` 的**，这**相当于给整个哈希表加了一把大锁**，**多线程访问的时候**，**只要有一个线程访问或操作该对象**，**那其他线程只能阻塞**，**相当于将所有的操作串行化**，**在竞争激烈的并发场景中性能就会非常差**。![](https://notebook.grayson.top/media/202107/2021-07-29_1707350.2864095646869024.png)
      2. **HashTable 不建议在新代码中使用**，**不需要线程安全的场合可以用 HashMap 替换**，**需要线程安全的场合可以用 ConcurrentHashMap 替换**，因为**ConcurrentHashMap 采用了分段锁**，**并发性比 HashTable 要高很多**，具体可参考[2.1 实现原理](#2-1-实现原理)。![](https://notebook.grayson.top/media/202107/2021-07-29_1710410.7268898193128783.png)
   3. **LinkedHashMap**：
      1. **LinkedHashMap 是 HashMap 的一个子类**，**保存了记录的插入顺序**，**在用 Iterator 遍历 LinkedHashMap 时**，**先得到的记录肯定是先插入的**，**也可以在构造时带参数**，**按照访问次序排序**。
   4. **TreeMap**：
      1. **TreeMap 实现了 SortedMap 接口**，**能够把保存的记录根据键排序**，**默认是按键值的升序排序**，**也可以指定排序的比较器**，**当用 Iterator 遍历 TreeMap 时**，**得到的记录是排过序的**，**如果使用排序的映射**，**建议使用 TreeMap**。
      2. **在使用 TreeMap 时**，`key`**必须实现 Comparable 接口**，**或者在构造 TreeMap 传入自定义的 Comparator**，**否则会在运行时抛出 `java.lang.ClassCastException` 类型的异常**。
3. 对于上述四种 Map 类型的类，要求**映射中的 `key` 是不可变对象**，即**该对象在创建后他的哈希值不会被改变**，**如果对象的哈希值发生变化**，**Map 对象很可能就定位不到映射的位置了**。

### 1.2 内部实现

#### 1.2.1 存储结构

1. 从**结构实现**来讲，HashMap 是**数组**+**链表**+**[红黑树](https://notebook.grayson.top/project-53/doc-891)**（JDK1.8 增加了红黑树部分）实现的，如下图所示：![](https://notebook.grayson.top/media/202107/2021-07-28_1717200.8508396937310263.png)
2. 从源码可知，HashMap 类中有一个非常重要的字段，就是 `Node<K,V>[] table;`，即**哈希桶数组**，他是一个**Node 数组**，Node 是**HashMap 的一个内部类**，**实现了 `Map.Entry` 接口**，**本质就是一个映射**（键值对），**上图中的每个黑色圆点就是一个 Node 对象**，Node 的源码如下：
   
   ```java
   static class Node<K,V> implements Map.Entry<K,V> {
       final int hash;
       final K key;
       V value;
       Node<K,V> next;
   
       Node(int hash, K key, V value, Node<K,V> next) {...}
   
       public final K getKey()        { return key; }
       public final V getValue()      { return value; }
       public final String toString() { return key + "=" + value; }
   
       public final int hashCode() {...}
   
       public final V setValue(V newValue) {...}
   
       public final boolean equals(Object o) {...}
   }
   ```
3. HashMap 就是**使用哈希表来存储**的，哈希表为**解决冲突**，可以采用**开放地址法**和**链地址法**，Java 中**HashMap 采用了链地址法**，即**数组加链表的结合**，**在每个数组元素上都有一个链表结构**，**当数据被 Hash 后**，**得到数组下标**，**把数据放在对应下标元素的链表上**。
4. HashMap 中其他几个字段如下：
   
   ```java
   int threshold;             // 所能容纳的 key-value 对极限 
   final float loadFactor;    // 负载因子
   int modCount;  
   int size;
   ```
   
   1. `threshold`：
      1. HashMap**所能容纳的最大数据量的 Node**（键值对）**的个数**，计算公式为 $threshold = length * loadFactor$，其中 `length`**为 `table` 的长度**，**默认为 16**，而且 `length`**的大小必须为 2 的 $n$ 次方**，主要是**为了在取模和扩容时做优化**，**同时为了减少冲突**，**HashMap 定位哈希桶索引位置时**，**也加入了高位参与运算的过程**。
      2. 当 HashMap 中**键值对的数量超过这个数目就需要重新扩容**，**扩容后的 HashMap 容量是之前容量的两倍**。
   2. `loadFactor`：
      1. **负载因子**，**默认为 0.75**，**该值是对空间和时间效率的一个平衡选择**，**建议不要修改**。
   3. `modCount`：
      1. 主要用来**记录 HashMap 内部结构发生变化的次数**，**主要用于迭代的快速失败**，其中**内部结构发生变化指的是结构发生变化**，例如 `put` 新键值对，但是某个 `key` 对应的 `value` 值被覆盖不属于结构变化。
   4. `size`：
      1. HashMap 中**实际存在的键值对数量**。
5. **即使负载因子和 Hash 算法设计的再合理**，**也免不了出现拉链过长的情况**，**一旦出现拉链过长**，**则会严重影响 HashMap 的性能**，**于是**，**在 JDK1.8 版本中**，**对数据结构做了进一步优化**，**引入了红黑树**，**当链表长度太长**（默认超过 8）**时**，**链表就转化为红黑树**，**利用红黑树快速增删改查的特点提高 HashMap 的性能**。

#### 1.2.2 功能实现

HashMap 的内部功能实现很多，本文主要从**根据 `key` 获取哈希桶数组索引位置**、`put`**方法的执行原理**、**扩容机制**三个具有代表性的点深入展开讲解。

##### 1.2.2.1 确定哈希桶数组索引位置

1. HashMap 中**使用 Hash 算法确定哈希桶数组索引位置**，具体源码如下：
   
   ```java
   public V get(Object key) {
       Node<K,V> e;
       return (e = getNode(hash(key), key)) == null ? null : e.value;
   }
   ```
   
   ```java
   // 方法一：
   static final int hash(Object key) {  // jdk1.8 & jdk1.7
       int h;
       //  h = key.hashCode()  1. 取 hashCode 值
       //  h ^ (h >>> 16)    2. 高位参与运算
       return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
   }
   
   // 方法二：
   static int indexFor(int h, int length) {      //    jdk1.7 的源码，jdk1.8 没有这个方法，但是实现原理一样的
       return h & (length-1);  //  3. 取模运算
   }
   ```
2. 这里的 Hash 算法本质上就是三步，分比为**取 `key` 的 `hashCode` 值**、**高位运算**、**取模运算**。
3. 对于任意给定的对象，**只要他的 `hashCode` 返回值相同**，那么程序调用方法一所**计算得到的 Hash 码值总是相同的**。
4. 对于**索引位置的确定**，我们首先想到的是把 `hash` 值对数组长度取模运算，这样一来，元素的分布相对来说是比较均匀的，但是**模运算的消耗是比较大的**，在 HashMap 中是**通过调用方法二来计算该对象应该保存在 `table` 数组的哪个索引处**，**这个方法非常巧妙**，**他通过 `h & (length - 1)` 来得到该对象的保存位**，而**HashMap 底层数组的长度总是 2 的 $n$ 次方**，此时 `h & (length - 1)`**运算等价于对 `length` 取模**，**也就是 `h % length`**，但是 `&`**比 `%` 具有更高的效率**。
5. 在 JDK 1.8 的实现中，**优化了高位运算的算法**，**通过 `hashCode` 的高 16 为异或低 16 位实现的**，即 `(h = key.hashCode()) ^ (h >>> 16)`，这样做**可以在数组 `table` 的长度比较小的时候**，**也能保证到高低 `bit` 都参与到 Hash 的计算中**，**同时不会有太大的开销**，具体示例如下：
   
   ![](https://notebook.grayson.top/media/202107/2021-07-29_1028090.24429923051565483.png)

##### 1.3.2.2 put 方法的执行原理

1. HashMap 的 `put` 方法执行过程如下图所示：![](https://notebook.grayson.top/media/202107/2021-07-29_1051260.7361479512008406.png)
   
   1. **判断键值对数组 `table[i]` 是否为空或 `null`**，**如果是的话**，**则对 HashMap 进行扩容**。
   2. **根据键值 `key` 计算 `hash` 值得到插入的数组索引 `i`**：
      1. **如果 `table[i] == null`**，**直接新建节点添加**，**然后转向 6**。
      2. **否则**，**转向 3**。
   3. **判断 `table[i]` 的首个元素是否和 `key` 一样**：
      1. **如果相同**（`hashCode` 和 `equals` 值均相同），**直接覆盖 `value`**。
      2. **否则**，**转向 4**。
   4. **判断 `table[i]` 是否为 TreeNode**，**即红黑树**：
      1. **如果是红黑树**，**则直接在树中插入键值对**。
      2. **否则**，**转向 5**。
   5. **遍历 `table[i]`**，**判断链表长度是否大于 8**：
      1. **如果大于 8 的话**，**则把链表转换为红黑树**，**然后在红黑树中执行插入操作**。
      2. **否则**，**进行链表的插入操作**，**遍历过程中**，**如果发现 `key` 已经存在**，**则直接覆盖 `value` 即可**。
   6. **插入成功后**，**判断实际存在的键值对数量**`size`**是否超过了最大容量**`threshold`：
      1. **如果超过了**，**则进行扩容**。
2. JDK 1.8 中 HashMap 的 `put` 方法源码如下：
   
   ```java
   public V put(K key, V value) {
       return putVal(hash(key), key, value, false, true);
   }
   
   final V putVal(int hash, K key, V value, boolean onlyIfAbsent,
                  boolean evict) {
       Node<K,V>[] tab; Node<K,V> p; int n, i;
       //  1. 判断键值对数组 table 是否为空或者 table 的长度是否为 0
       if ((tab = table) == null || (n = tab.length) == 0)
           //  如果是，则对 HashMap 进行扩容
           n = (tab = resize()).length;
       //  2. 根据键值 key 计算 hash 值得到插入的数组索引 i，判断 table[i] 是否为空
       if ((p = tab[i = (n - 1) & hash]) == null)
           //  如果 table[i] 为空，则创建新的节点
           tab[i] = newNode(hash, key, value, null);
       else {
           Node<K,V> e; K k;
           //  3. 判断 table[i] 的首个元素是否和 key 一样（hashCode 和 equals 值均相同）
           if (p.hash == hash &&
               ((k = p.key) == key || (key != null && key.equals(k))))
               //  如果一样，则直接覆盖 value
               e = p;
           //  4. 判断 table[i] 是否为红黑树
           else if (p instanceof TreeNode)
               //  如果是红黑树，则直接在树中插入键值对
               e = ((TreeNode<K,V>)p).putTreeVal(this, tab, hash, key, value);
           else {
               //  5. 遍历 table[i]
               for (int binCount = 0; ; ++binCount) {
                   if ((e = p.next) == null) {
                       p.next = newNode(hash, key, value, null);
                       //  判断链表长度是否大于 8
                       if (binCount >= TREEIFY_THRESHOLD - 1) // -1 for 1st
                           //  如果链表长度大于 8，则把链表转换为红黑树，在红黑树中执行插入操作
                           treeifyBin(tab, hash);
                       break;
                   }
                   //  进行链表的插入操作，如果 key 已经存在，则直接覆盖 value 即可
                   if (e.hash == hash &&
                       ((k = e.key) == key || (key != null && key.equals(k))))
                       break;
                   p = e;
               }
           }
           if (e != null) { // existing mapping for key
               V oldValue = e.value;
               if (!onlyIfAbsent || oldValue == null)
                   e.value = value;
               afterNodeAccess(e);
               return oldValue;
           }
       }
       ++modCount;
       //  6. 插入成功之后，判断实际存在的键值对数量 size 是否超过了最大容量 threshold，如果超过，则进行扩容
       if (++size > threshold)
           resize();
       afterNodeInsertion(evict);
       return null;
   }
   ```

##### 1.2.2.3 扩容机制

1. 扩容就是**重新计算容量**，当**向 HashMap 对象中不同的添加元素**，而**HashMap 对象内部的数组无法承载更多的元素时**，**对象就需要扩大数组的长度**，**以便能装入更多的元素**，但是**Java 里的数组是无法自动扩容的**，**方法是使用一个新的数组代替已有的容量小的数组**，**就像我们用一个小桶装水**，**如果想装更多的水**，**就得换大水桶**。
2. 下面我们分析下 `resize` 的源码，因为 JDK 1.8 融入了红黑树，较复杂，为了便于理解，我们仍使用 JDK 1.7 的源码，这样好理解一些，本质上区别不大，具体区别后文再说：
   
   ```java
   void resize(int newCapacity) {  /*传入新的容量*/
       Entry[] oldTable = table;   /*引用扩容前的 Entry 数组*/
       int oldCapacity = oldTable.length;
       if (oldCapacity == MAXIMUM_CAPACITY) {  /*扩容前的数组大小如果已经达到最大（2^30）了*/
           threshold = Integer.MAX_VALUE;  /*修改阈值为 int 的最大值（2^31 - 1），这样以后就不会扩容了*/
           return;
       }
   
       Entry[] newTable = new Entry[newCapacity];  /*初始化一个新的 Entry 数组*/
       boolean oldAltHashing = useAltHashing;
       useAltHashing |= sun.misc.VM.isBooted() &&
               (newCapacity >= Holder.ALTERNATIVE_HASHING_THRESHOLD);
       boolean rehash = oldAltHashing ^ useAltHashing;
       transfer(newTable, rehash); /*将数据转移到新的 Entry 数组里*/
       table = newTable;   /*HashMap 的 table 属性引用新的 Entry 数组*/
       threshold = (int)Math.min(newCapacity * loadFactor, MAXIMUM_CAPACITY + 1);  /*修改阈值*/
   }
   ```
   
   这里就是**使用一个容量更大的数组来代替已有的容量小的数组**，`transfer()`**方法将原有 `Entry` 数组的元素拷贝到新的 `Entry` 数组里**，具体源码如下：
   
   ```java
   5void transfer(Entry[] newTable, boolean rehash) {
       int newCapacity = newTable.length;
       for (Entry<K,V> e : table) {    /*遍历旧的 Entry 数组*/
           while(null != e) {
               Entry<K,V> next = e.next;
               if (rehash) {
                   e.hash = null == e.key ? 0 : hash(e.key);
               }
               int i = indexFor(e.hash, newCapacity);  /*重新计算每个元素在数组中的位置*/
               e.next = newTable[i];   /*标记*/
               newTable[i] = e;    /*将元素放在数组上*/
               e = next;   /*访问下一个 Entry 链上的元素*/
           }
       }
   }
   ```
   
   `newTable[i]` 的引用赋给了 `e.next`，也就是**使用了单链表的头插入方式**，**同一位置上新元素总会被放在链表的头部位置**，这样**先放在一个索引上的元素终会被放到 `Entry` 链的尾部**（如果发生了 `hash` 冲突的话），这一点和 JDK 1.8 有区别，下文讲解，**在旧数组中同一条 `Entry` 链上的元素**，**通过重新计算索引位置后**，**有可能被放到了新数组的不同位置上**。
3. 下面举个例子说明下扩容过程，假设我们的 `hash` 算法就是简单的用 `key` 去 `mod` 一下表的大小（也就是数组的长度），负载因子 `loadFactor` 为 1，即当键值对的实际大小 `size` 大于 `table` 的实际大小时进行扩容，具体的过程如下图所示：
   
   ![](https://notebook.grayson.top/media/202107/2021-07-29_1137300.5816776400600694.png)
4. 下面我们讲解下 JDK 1.8 做了哪些优化：
   
   1. 经过观测可以发现，我们使用的是**2 次幂的扩展**（指长度扩展为原来的 2 倍），所以，**元素的位置要么是在原位置**，**要么是在原位置再移动 2 次幂的位置**，看下图就可以明白这个意思，$n$ 为 `table` 的长度，图（a）表示扩容前的 `key1` 和 `key2` 两种 `key` 确定索引位置的示例，图（b）表示扩容后 `key1` 和 `key2` 两种 `key` 确定索引位置的示例，其中 `hash1` 是 `key1` 对应的哈希与高位运算结果：![](https://notebook.grayson.top/media/202107/2021-07-29_1436240.5522429648167162.png)
   2. 元素在重新计算 `hash` 之后，因为 $n$**变为 2 倍**，那么 $n-1$**的 `mask` 范围在高位多 1bit**（红色），因此，**新的 `index` 就会发生这样的变化**：![](https://notebook.grayson.top/media/202107/2021-07-29_1439560.29372264905797085.png)
   3. 因此，我们**在扩充 HashMap 的时候**，**不需要像 JDK 1.7 那样重新计算 `hash`**，**只需要看看原来的 `hash` 值新增的那个 `bit` 是 1 还是 0 就好了**，**如果是 0 的话**，**索引没变**，**如果是 1 的话**，**索引变成原索引 + 扩容前 HashMap 的容量**，下图为 16 扩充为 32 的扩容示意图：![](https://notebook.grayson.top/media/202107/2021-07-29_1446130.0976090829432632.png)
   4. 这个设计确实非常巧妙，既**省去了重新计算 `hash` 值的时间**，而且同时，由于**新增的 1bit 是 0 还是 1 可以认为是随机的**，因此**扩容的过程中**，**均匀的把之前冲突的节点分散到新的桶中了**，**这一块就是 JDK 1.8 新增的优化点**。
   5. 有一点需要注意的是，**JDK 1.7 中 `rehash` 的时候**，**如果在新表的数组的索引位置相同**，则**链表元素会倒置**，但是从上图可以看出，**JDK 1.8 不会倒置**。
      
      > 为什么 HashMap 的数组长度一定是 2 的次幂？
      > 
      > 1. 这样可以**保证扩容后与原容量相比只有一位差异**，例如：
      >    1. 假设初始 HashMap 的长度 $length$ 为 16，用二进制表示为 10000，则 $length - 1$ 为 15，用二进制表示为 01111。
      >    2. 扩容后数组的长度 $newLength$ 为 32，用二进制表示为 100000，则 $newLength - 1$ 为 011111。
      >    3. 这样可以保证最低位全为 1，而且扩容后只有一位差异，也就是最左位的 1。
      > 2. 这样既**省去了重新计算 `hash` 的时间**，同时**可以把之前冲突的节点均匀的分散到新的桶中**，具体的原因可以参考[1.3.2.3 扩容机制](#1-3-2-3-扩容机制)中第 4 点的描述。![](https://notebook.grayson.top/media/202107/2021-07-29_1528120.7520437480289052.png)

##### 1.2.2.4 线程安全性

1. 在多线程使用场景中，应该**尽量避免使用线程不安全的 HashMap**，而**使用线程安全的 ConcurrentHashMap**，因为：
   1. **HashMap 不是线程安全的**，**在多线程并发的情况下容易发生线程安全问题**，**在进行扩容时也会出现死循环问题**，例如在并发的情况下，线程进行了 `put` 操作，由于某种情况随后 `sleep` 了两秒，在这两秒期间，线程 2 修改了线程 1 之前 `put` 的值，等到线程 1 结束 `sleep` 后再次 `get` 到原来值的时候，就有可能取到的值已经不是原来的值了，就会存在问题。
   2. **在并发的多线程使用场景中使用 HashMap 可能会在扩容的时候形成环状链表**，**导致 `get` 操作时 CPU 空转**。

### 1.3 HashMap 在 JDK 1.7 和 JDK 1.8 之间的区别

1. **数据结构**：
   1. JDK 1.7 的底层结构是**数组 + 链表**。
   2. JDK 1.8 的底层结构是**数组 + 链表 + 红黑树**，**当单条链表的长度大于 8 时**，**将链表转换为红黑树**，**然后插入键值对**。
2. **扩容机制**：
   1. JDK 1.7 为**先判断是否需要扩容**，**再插入**。
   2. JDK 1.8 为**先插入**，**再判断是否需要扩容**。
3. **节点插入**：
   1. JDK 1.7 为**头插法**，存在**多线程成环**的问题。
   2. JDK 1.8 为**尾插法**，存在**数据丢失**问题。

## 2 ConcurrentHashMap

### 2.1 实现原理

> 如无特殊说明，下面关于 ConcurrentHashMap 原理的分析是基于 JDK 1.7 的。

#### 2.1.1 Segment

1. ConcurrentHashMap 采用了非常精妙的**分段锁**策略，COncurrentHashMap 的**主干是个 Segment 数组**：
   
   ```java
   final Segment<K,V>[] segments;
   ```
   
   > 分段锁的优缺点是什么？
   > 
   > 1. **优点：**
   >    1. **保证在操作不同段 Map 的时候可以并发执行**，**操作同段 Map 的时候**，**进行锁的竞争和等待**，这**相对于对整个 Map 同步**（Synchronized）**是有优势的**。
   > 2. **缺点**：
   >    1. 分段锁**每个锁控制的是一段**，**当每个 Segment 越来越大时**，**锁的粒度就变得有些大了**。
   >    2. **分成很多段会比较浪费内存空间**（不连续，碎片化）。
   >    3. 操作 Map 时**竞争同一个分段锁的概率非常小**，**分段锁反而会造成更新操作的长时间等待**。
2. Segment**继承了 ReentrantLock**，所以**他就是一种[可重入锁](https://notebook.grayson.top/project-34/doc-531/#2-1-1-%E5%8F%AF%E9%87%8D%E5%85%A5%E9%94%81)**（ReentrantLock），同时，一个 Segment 就**是一个子哈希表**（一些属性和[HashMap](#1-HashMap)差不多，例如负载因子、阈值），Segment 里**维护了一个 HashEntry 数组**，**并发环境下**，**对于不同 Segment 的数据进行操作是不用考虑锁竞争的**，所以**对于同一个 Segment 的操作才需要考虑线程同步**，**不同的 Segment 则无需考虑**。
   
   ```java
   transient volatile HashEntry<K,V>[] table;  /*链表数组，使用 volatile 修饰，保证可见性*/
   
   transient int count;    /*Segment 中元素的个数*/
   
   transient int modCount; /*Segment 中可变操作的总次数*/
   
   transient int threshold;    /*阈值，当 Segment 的大小超过此阈值时，将对其进行 rehash 操作*/
   
   final float loadFactor; /*负载因子，默认为 0.75*/
   
   Segment(float lf, int threshold, HashEntry<K,V>[] tab) {
       this.loadFactor = lf;
       this.threshold = threshold;
       this.table = tab;
   }
   ```

#### 2.1.2 构造方法

1. 我们来看一下 ConcurrentHashMap 的构造方法：
   
   ```java
   public ConcurrentHashMap(int initialCapacity,
                            float loadFactor, int concurrencyLevel) {
       if (!(loadFactor > 0) || initialCapacity < 0 || concurrencyLevel <= 0)
           throw new IllegalArgumentException();
       if (concurrencyLevel > MAX_SEGMENTS)    /*MAX_SEGMENTS 为 1 << 16 = 65536，即最大并发数为 65536*/
           concurrencyLevel = MAX_SEGMENTS;
       // Find power-of-two sizes best matching arguments
       int sshift = 0; /*2 的 sshift 次方等于 ssize，例如 ssize = 16，ssift = 4；ssize = 32，sshit = 5*/
       int ssize = 1;  /*ssize 为 segments 数组的长度，根据 concurrentLevel 计算得出*/
       while (ssize < concurrencyLevel) {
           ++sshift;
           ssize <<= 1;
       }
       this.segmentShift = 32 - sshift;    /*segmentShift 和 segmentMask 这两个变量在定位 segment 时会用到，后面会详细讲*/
       this.segmentMask = ssize - 1;
       if (initialCapacity > MAXIMUM_CAPACITY)
           initialCapacity = MAXIMUM_CAPACITY;
       int c = initialCapacity / ssize;    /*计算 cap 的大小，即 segment 中 HashEntry 的数组长度，cap 也一定为 2 的 n 次方*/
       if (c * ssize < initialCapacity)
           ++c;
       int cap = MIN_SEGMENT_TABLE_CAPACITY;
       while (cap < c)
           cap <<= 1;
       // create segments and segments[0]
       Segment<K,V> s0 =   /*创建 segments 数组并初始化第一个 Segment，其余的 Segment 延迟初始化*/
           new Segment<K,V>(loadFactor, (int)(cap * loadFactor),
                            (HashEntry<K,V>[])new HashEntry[cap]);
       Segment<K,V>[] ss = (Segment<K,V>[])new Segment[ssize];
       UNSAFE.putOrderedObject(ss, SBASE, s0); // ordered write of segments[0]
       this.segments = ss;
   }
   ```
   
   1. 初始化方法有**三个参数**，分别为 `initialCapacity`（默认为 16）、`loadFactor`（默认为 0.75）、`concurrencyLevel`（默认为 16），如果用户不指定，则会使用默认值。
   2. **Segment 数组的大小 `ssize` 是由 `concurrencyLevel` 决定**，为**大于或等于 `concurrencyLevel` 的最小的 2 的次幂**，例如，默认情况下 `concurrencyLevel` 为 16，则 `ssize` 为 16；若 `concurrencyLevel` 为 14，则 `ssize` 为 16；若 `concurrencyLevel` 为 17，则 `ssize` 为 32。
      
      > 为什么 Segment 的数组大小一定是 2 的次幂？
      > 
      > 1. 主要是**便于通过按位与的散列算法来定位 Segment 的 Index**，具体可参考[1.2.2.3 扩容机制](https://notebook.grayson.top/project-34/doc-813/#1-2-2-3-%E6%89%A9%E5%AE%B9%E6%9C%BA%E5%88%B6)。

#### 2.1.3 get 方法

1. ConcurrentHashMap 的 `get` 方法的源码如下：
   
   ```java
   public V get(Object key) {
       Segment<K,V> s; // manually integrate access methods to reduce overhead
       HashEntry<K,V>[] tab;
       int h = hash(key);
       long u = (((h >>> segmentShift) & segmentMask) << SSHIFT) + SBASE;
       if ((s = (Segment<K,V>)UNSAFE.getObjectVolatile(segments, u)) != null &&    /*先定位到 Segment，再定位到 HashEntry*/
           (tab = s.table) != null) {
           for (HashEntry<K,V> e = (HashEntry<K,V>) UNSAFE.getObjectVolatile
                    (tab, ((long)(((tab.length - 1) & h)) << TSHIFT) + TBASE);
                e != null; e = e.next) {
               K k;
               if ((k = e.key) == key || (e.hash == h && key.equals(k)))
                   return e.value;
           }
       }
       return null;
   }
   ```
2. `get` **方法无需加锁**，由于其中**涉及到的共享变量都使用 [volatile](https://notebook.grayson.top/project-34/doc-528)修饰**，`volatile`**可以保证内存可见性**，所以**不会读取到过期的数据**。

#### 2.1.4 put 方法

1. ConcurrentHashMap 的 `put` 方法的源码如下：
   
   ```java
   public V put(K key, V value) {
       Segment<K,V> s;
       if (value == null)  /*这里的 value 不能为空*/
           throw new NullPointerException();
       int hash = hash(key);   /*计算 key 的 hash 值*/
       int j = (hash >>> segmentShift) & segmentMask;  /*根据 hash 值计算待插入对象在 segments 数组中的位置*/
       if ((s = (Segment<K,V>)UNSAFE.getObject     /*检查当前数组中指定位置的 Segment 是否为空，如果为空，则先初始化 Segment 再进行 put，如果不为空，则直接执行 put 操作*/
            (segments, (j << SSHIFT) + SBASE)) == null)
           s = ensureSegment(j);
       return s.put(key, hash, value, false);
   }
   ```
2. SegmentShift 和 SegmentMask 主要用来定位 Segment，其中 `int j = (hash >>> segmentShift) & segmentMask;`：
   
   1. **segmentShift**：
      1. 2 的 `sshift` 次方等于 `ssize`，`segmentShift = 32 - sshift`，若 `segments` 的长度为 16，，则 `segmentShift = 32 - 4 = 28`。
      2. 计算得出的 `hash` 值最大为 32 位，无符号右移 `segmentShift`，则意味着只保留高几位（其余位是没用的），然后与段掩码进行与运算来定位 Segment。
   2. **segmentMask**：
      1. **段掩码**，等于 `segments` 的长度减 1，即 `segmentMask = ssize - 1;`，若 `segments` 长度为 16，则 `segmentMask = 16 - 1 = 15`。
3. 从源码可以看出，`put` 的主要逻辑也就两步：
   
   1. **定位 Segment**，**并确保定位的 Segment 已经初始化**。
   2. **调用 Segment 的 `put` 方法**，Segment 的 `put` 方法源码如下：
      
      ```java
      final V put(K key, int hash, V value, boolean onlyIfAbsent) {
          HashEntry<K,V> node = tryLock() ? null :    /*先获取锁，获取到则返回 null，否则执行 scanAndLockForPut*/
              scanAndLockForPut(key, hash, value);
          V oldValue;
          try {
              HashEntry<K,V>[] tab = table;   /*此 table 被 volatile 修饰*/
              int index = (tab.length - 1) & hash;    /*计算在 HashEntry[] 中的位置*/
              HashEntry<K,V> first = entryAt(tab, index); /*找到 HashEntry[] 中指定位置的第一个节点，即 first 指向桶中链表的第一个节点*/
              for (HashEntry<K,V> e = first;;) {
                  if (e != null) {    /*如果当前节点不为空，则遍历该链表*/
                      K k;
                      if ((k = e.key) == key ||   /*如果之前已经存在了该 key，则用新值替换旧值*/
                          (e.hash == hash && key.equals(k))) {
                          oldValue = e.value;
                          if (!onlyIfAbsent) {
                              e.value = value;
                              ++modCount;
                          }
                          break;
                      }
                      e = e.next; /*来到下一个节点*/
                  }
                  else {  /*如果当前节点为空，则进入 else*/
                      if (node != null)
                          node.setNext(first);
                      else
                          node = new HashEntry<K,V>(hash, key, value, first); /*采用链表的头插法新建一个节点*/
                      int c = count + 1;  /*键值对数量加 1*/
                      if (c > threshold && tab.length < MAXIMUM_CAPACITY) /*如果超过阈值则扩容*/
                          rehash(node);
                      else
                          setEntryAt(tab, index, node);   /*没有超过阈值的话，则放在指定的位置*/
                      ++modCount;
                      count = c;
                      oldValue = null;    /*桶中不存在相同 key 的节点，所以返回 null*/
                      break;
                  }
              }
          } finally {
              unlock();   /*解锁操作*/
          }
          return oldValue;    /*put 成功，则返回旧值*/
      }
      ```
      
      1. 首先会**尝试获取锁**，**如果获取失败则肯定有其他线程存在竞争**，**则利用 `scanAndLockForPut` 自旋获取锁**：
         
         ```java
         HashEntry<K,V> node = tryLock() ? null : scanAndLockForPut(key, hash, value);
         ```
         
         ```java
         private HashEntry<K,V> scanAndLockForPut(K key, int hash, V value) {
             HashEntry<K,V> first = entryForHash(this, hash);    /*通过 Segment 和 hash 寻找匹配的 HashEntry*/
             HashEntry<K,V> e = first;
             HashEntry<K,V> node = null;
             int retries = -1; // 重试次数   negative while locating node
             while (!tryLock()) {    /*不断循环，尝试获取锁*/
                 HashEntry<K,V> f; // to recheck first below
                 if (retries < 0) {
                     if (e == null) {    /*之前表中不存在当前 key*/
                         if (node == null) // speculatively create node
                             node = new HashEntry<K,V>(hash, key, value, null);  /*新增一个节点*/
                         retries = 0;    /*将重试次数置为 0*/
                     }
                     else if (key.equals(e.key))
                         retries = 0;
                     else
                         e = e.next; /*第一个节点也不是，则继续来到下一个节点*/
                 }
                 else if (++retries > MAX_SCAN_RETRIES) {    /*尝试次数大于了最大次数（64）的话，则改为阻塞式获取，保证能获取成功*/
                     lock();
                     break;
                 }
                 else if ((retries & 1) == 0 &&  /*在 MAX_SCAN_RETRIES 次过程中，key 对应的 entry 发生了变化，则从头开始*/
                          (f = entryForHash(this, hash)) != first) {
                     e = first = f; // re-traverse if entry changed
                     retries = -1;
                 }
             }
             return node;
         }
         ```
         
         1. 假如当前环境下没有任何线程进行 `put` 操作，此时如果线程 1 进行了 `put` 操作，他首先会去尝试获得锁，由于之前没有任何一个线程持有锁，所以线程 1 是可以执行到 `tryLock()` 并返回 `null` 的，即线程 1**成功的拿到了锁**，然后**根据计算找到对应桶的位置**，**新添加一个键值对**。
         2. 如果此时在**线程 1 还没有释放锁**的情况下，**线程 2 又执行了 `put` 操作**，则假如**线程 2 恰好也定位到了和线程 1 同一个段**，然后尝试去进行 `put` 操作，即尝试获取锁，但是线程 1 还没有释放锁，所以**线程 2 在一开始的时候会执行 `scanAndLockForPut` 方法**。
         3. 线程 2 虽然没有得到锁，但是也没有闲着，而是**将准备存放的键值对在对应数组中相应的位置给计算了出来**，**一旦线程 2 获取到了锁**，那么就可以利用等待获取锁的这段时间所做的工作，**直接定位到具体的位置**，从而**节省了时间**，**提高了执行效率**。
         4. 如果**线程 2 在等待锁的期间**，**线程 1 将 `key` 对应的 `entry` 进行了修改**，则**线程 2 需要重新确定接下来要定位的位置**。
      2. 如果**获取锁成功**，则**将当前的 Segment 中的 `table` 通过 `key` 的 `hash` 值定位到 HashEntry**。
      3. 然后**遍历该 HashEntry**：
         
         1. **如果当前节点不为空**，**则判断传入的 `key` 和当前遍历到的 `key` 是否相等**，**如果相等**，**则覆盖旧的 `value`**。
         2. **如果当前节点为空**，**则新建一个 HashEntry 并加入到 Segment 中**，**再判断是否需要扩容**。
      4. 最后**在 `finally` 中解除之前获得的锁**。
   
   ![1604851702c89293 (1031×1501)](https://notebook.grayson.top/media/202107/2021-07-30_1539390.0048849912925379435.png)

### 2.2 JDK 1.8 中的 ConcurrentHashMap

#### 2.2.1 与 JDK 1.7 中的 ConcurrentHashMap 的区别

1. **抛弃了 JDK 1.7 中的 Segment 锁分段技术**，而是**采用 CAS + Synchronized 的方式保证并发的安全性**，**体现在 `put` 操作的不同**，**在 JDK 1.8 中则是对数组中单个位置加锁**。
   
   > 为什么要使用 CAS + Synchronized 取代 Segment + ReentrantLock？
   > 
   > 1. 分段锁具有相应的缺点，具体可参考[2.1.1 Segment](/#2-1-1-Segment)。
   > 2. **使用 ReentrantLock 需要节点继承 AQS 来获得同步支持**，**锁定的是一整个段**，**增加内存开销**，**而 JDK 1.8 中加锁的对象是每个链表的头结点**，也就是**锁定的是冲突的链表**，因此**提高了并发度**，同时**降低了内存开销**。
   > 3. **Synchronized 是 JVM 直接支持的**，**JDK 1.8 之后进行了许多优化**，**能够在运行期间调整锁的粒度**，**而不需要在开始就是用重量级锁操作**。
2. **将 JDK 1.7 中用于存放数据的内部类 HashEntry 替换成了内部类 Node**，**但作用相同**。
3. JDK 1.8 中的**结构转换为数组 + 链表 + 红黑树**。

## 3 TreeMap

### 3.1 简介

1. TreeMap 是一个**有序的 `key-value` 集合**，是**非线程安全**的，**基于[红黑树](https://notebook.grayson.top/project-53/doc-891)实现**。
2. TreeMap 的**映射默认根据键的自然顺序进行排序**，**也可以根据创建映射时提供的 Comparator 进行排序**，**具体取决于使用的构造方法**，当**自定义比较器时**，**需要自定义类实现 `java.lang.Comparable` 接口**，**并重写 `compareTo()` 方法**。

### 3.2 实现原理

#### 3.2.1 成员变量

1. TreeMap 中主要的成员变量如下：
   
   ```java
   /**
    * TreeMap 可以自动排序，默认情况下 comparator 为空，这个时候按照 key 的自然顺序进行排序，
    * 然而并不是所有情况下都可以直接使用 key 的自然顺序，有时候我们想让 TreeMap 的自动排序按照
    * 我们自己的规则，这个时候我们就需要传递 Comparator 的实现类
    *
    * @serial
    */
   private final Comparator<? super K> comparator;
   
   /**
    * TreeMap 的存储结构既然是红黑树，那么必然会有唯一的根节点。
    */
   private transient Entry<K,V> root;
   
   /**
    * Map 中 key-val 键值对的数量，也即是红黑树中节点 Entry 的数量
    */
   private transient int size = 0;
   
   /**
    * 红黑树结构的调整次数
    */
   private transient int modCount = 0;
   ```
2. 上面的主要成员变量根节点 `root` 是 `Entry` 类的实体，其源码如下：
   
   ```java
   static final class Entry<K,V> implements Map.Entry<K,V> {
       //  key、val 存储的是原始数据
       K key;
       V value;
       //  节点的左孩子
       Entry<K,V> left;
       //  节点的右孩子
       Entry<K,V> right;
       //  节点的父节点
       Entry<K,V> parent;
       //  默认情况下为黑色节点，可调整
       boolean color = BLACK;
   }
   ```

#### 3.2.2 构造函数

1. TreeMap 的构造函数如下：
   
   ```java
   /**
    * 默认构造函数，按照 key 的自然顺序排列
    */
   public TreeMap() {
       comparator = null;
   }
   
   /**
    * 传递 Comparator 具体实现，按照该实现规则进行排序
    */
   public TreeMap(Comparator<? super K> comparator) {
       this.comparator = comparator;
   }
   
   /**
    * 传递一个 map 实类构建 TreeMap，按照默认规则排序
    */
   public TreeMap(Map<? extends K, ? extends V> m) {
       comparator = null;
       putAll(m);
   }
   
   /**
    * 传递一个 map 实类构建 TreeMap，按照传递的 map 的排序规则进行排序
    */
   public TreeMap(SortedMap<K, ? extends V> m) {
       comparator = m.comparator();
       try {
           buildFromSorted(m.size(), m.entrySet().iterator(), null, null);
       } catch (java.io.IOException cannotHappen) {
       } catch (ClassNotFoundException cannotHappen) {
       }
   }
   ```

#### 3.2.3 put 方法

1. TreeMap 的 `put()` 方法大概流程如下：![](https://notebook.grayson.top/media/202201/2022-01-09_2102100.02601055058283097.png)
2. `put()` 方法对应的源码如下：
   
   ```java
   public V put(K key, V value) {
       Entry<K,V> t = root;
       /**
        * 如果根节点都为 null，还没建立起来红黑树，我们先 new Entry 并赋值给 root，把红黑树建立起来，这时候
        * 红黑树中已经有一个节点了，同时修改操作 +1
        */
       if (t == null) {
           compare(key, key); // type (and possibly null) check
           root = new Entry<>(key, value, null);
           size = 1;
           modCount++;
           return null;
       }
       /**
        * 如果节点不为 null：
        *  1. 定义 cmp，这个变量用来进行二分查找时的比较。
        *  2. 定义 parent，是 new Entry 时必须要的参数。
        */
       int cmp;
       Entry<K,V> parent;
       //  cpr 表示有无自己定义的排序规则，分两种情况遍历执行
       Comparator<? super K> cpr = comparator;
       if (cpr != null) {
           /**
            * 有自己定义的排序规则
            * 从 root 节点开始遍历，通过二分查找逐步向下找：
            *  1. 第一次循环：
            *      1.1 从根节点开始，这个时候 parent 就是根节点，然后通过自定义的排序算法 cpr.compare(key, t.key)
            *          比较传入的 key 和根节点的 key 值：
            *              1.1.1 如果传入的 key < root.key，那么继续在 root 的左子树中找，从 root 的左孩子节点(root.left)开始。
            *              1.1.2 如果传入的 key > root.key，那么继续在 root 的右子树中找，从 root 的右孩子节点(root.right)开始。
            *              1.1.3 如果恰好 key == root.key，那么直接根据 root 节点的 value 值即可。
            *  2. 后面的循环规则一样，把遍历到的当前节点作为起始节点，逐步往下找。
            *  3. 需要注意的是，这里并没有对 key 是否为 null 进行判断，建议自己的实现 Comparator 时应该要考虑在内。
            */
           do {
               parent = t;
               cmp = cpr.compare(key, t.key);
               if (cmp < 0)
                   t = t.left;
               else if (cmp > 0)
                   t = t.right;
               else
                   return t.setValue(value);
           } while (t != null);
       }
       else {
           /**
            * 没有自己定义的排序规则
            * 从这里看出，当默认排序时，key 值是不能为 null 的
            */
           if (key == null)
               throw new NullPointerException();
           @SuppressWarnings("unchecked")
               Comparable<? super K> k = (Comparable<? super K>) key;
           /**
            * 这里的实现逻辑和上面一样，都是通过二分查找，就不再多说了
            */
           do {
               parent = t;
               cmp = k.compareTo(t.key);
               if (cmp < 0)
                   t = t.left;
               else if (cmp > 0)
                   t = t.right;
               else
                   return t.setValue(value);
           } while (t != null);
       }
       /**
        * 能执行到这里，说明前面并没有找到相同的 key，节点已经遍历到最后了，我们只需要 new 一个 Entry 放到
        * parent 下面即可，但放到左子节点上还是右子节点上，就需要按照红黑树的规则来
        */
       Entry<K,V> e = new Entry<>(key, value, parent);
       if (cmp < 0)
           parent.left = e;
       else
           parent.right = e;
       /**
        * 节点加进去了，并不算完，一般情况下加入节点都会对红黑树的结构造成破坏，我们需要通过一些操作来进行自动平衡初值
        */
       fixAfterInsertion(e);
       size++;
       modCount++;
       return null;
   }
   ```
3. `put()` 方法源码中通过 `fixAfterInsertion()` 方法来进行自平衡处理，具体过程可参考[插入后红黑树的调整](https://notebook.grayson.top/project-53/doc-891/#2-2-%E6%8F%92%E5%85%A5)，具体源码如下：
   
   ```java
   private void fixAfterInsertion(Entry<K,V> x) {
       //  新插入的节点为红色节点
       x.color = RED;
   
       //  父节点为黑色时，不需要进行树结构调整
       //  父节点为红色时，才需要进行树结构调整
       while (x != null && x != root && x.parent.color == RED) {
           if (parentOf(x) == leftOf(parentOf(parentOf(x)))) {
           //  父节点是左节点，对应上表中情况 1 和情况 2
               Entry<K,V> y = rightOf(parentOf(parentOf(x)));
               if (colorOf(y) == RED) {
                   //  插入节点是红色
                   //  如果叔父节点为红色，对应于“父节点和叔父节点”都为红色，此时通过变色即可实现平衡
                   //  此时父节点和叔父节点都设置为黑色，祖父节点设置为红色
                   setColor(parentOf(x), BLACK);
                   setColor(y, BLACK);
                   setColor(parentOf(parentOf(x)), RED);
                   x = parentOf(parentOf(x));
               } else {
                   //  插入节点是黑色
                   //  插入的是右子节点，通过【左右节点旋转】即可实现平衡（这里先进行父节点左旋）
                   if (x == rightOf(parentOf(x))) {
                       x = parentOf(x);
                       rotateLeft(x);
                   }
                   //  设置父节点和祖父节点颜色
                   setColor(parentOf(x), BLACK);
                   setColor(parentOf(parentOf(x)), RED);
                   //  进行祖父节点右旋（这里【变色】和【旋转】并没有严格的先后顺序，达成目的就行）
                   rotateRight(parentOf(parentOf(x)));
               }
           } else {
               //  父节点是右节点
               Entry<K,V> y = leftOf(parentOf(parentOf(x)));
               if (colorOf(y) == RED) {
                   //  插入节点是红色
                   //  对应于“父节点和叔父节点都为红色”，此时通过变色即可实现平衡
                   setColor(parentOf(x), BLACK);
                   setColor(y, BLACK);
                   setColor(parentOf(parentOf(x)), RED);
                   x = parentOf(parentOf(x));
               } else {
                   //  插入节点是黑色
                   //  插入的是左子节点，通过【右左节点旋转】（这里先进行父节点右旋）
                   if (x == leftOf(parentOf(x))) {
                       x = parentOf(x);
                       rotateRight(x);
                   }
                   //  设置父节点和祖父节点颜色
                   setColor(parentOf(x), BLACK);
                   setColor(parentOf(parentOf(x)), RED);
                   //  进行祖父节点左旋（这里【变色】和【旋转】并没有严格的先后顺序，达成目的就行）
                   rotateLeft(parentOf(parentOf(x)));
               }
           }
       }
       //  根节点必须为黑色
       root.color = BLACK;
   }
   ```

#### 3.2.4 get 方法

1. `get()` 方法是通过[二分查找](https://notebook.grayson.top/project-21/doc-759)的思想，具体源码如下：
   
   ```java
   /**
    * 默认排序情况下的查找
    *
    * 从 root 节点开始遍历，通过二分查找逐步向下找：
    *  1. 第一次循环：
    *      1.1 从根节点开始，这个时候 parent 就是根节点，然后通过自定义的排序算法 cpr.compare(key, t.key)
    *          比较传入的 key 和根节点的 key 值：
    *              1.1.1 如果传入的 key < root.key，那么继续在 root 的左子树中找，从 root 的左孩子节点(root.left)开始。
    *              1.1.2 如果传入的 key > root.key，那么继续在 root 的右子树中找，从 root 的右孩子节点(root.right)开始。
    *              1.1.3 如果恰好 key == root.key，那么直接根据 root 节点的 value 值即可。
    *  2. 后面的循环规则一样，把遍历到的当前节点作为起始节点，逐步往下找。
    */
   final Entry<K,V> getEntry(Object key) {
       // Offload comparator-based version for sake of performance
       if (comparator != null)
           return getEntryUsingComparator(key);
       if (key == null)
           throw new NullPointerException();
       @SuppressWarnings("unchecked")
           Comparable<? super K> k = (Comparable<? super K>) key;
       Entry<K,V> p = root;
       while (p != null) {
           int cmp = k.compareTo(p.key);
           if (cmp < 0)
               p = p.left;
           else if (cmp > 0)
               p = p.right;
           else
               return p;
       }
       return null;
   }
   
   /**
    * 自定义排序规则下的查找
    *
    * 从 root 节点开始遍历，通过二分查找逐步向下找：
    *  1. 第一次循环：
    *      1.1 从根节点开始，这个时候 parent 就是根节点，然后通过自定义的排序算法 cpr.compare(key, t.key)
    *          比较传入的 key 和根节点的 key 值：
    *              1.1.1 如果传入的 key < root.key，那么继续在 root 的左子树中找，从 root 的左孩子节点(root.left)开始。
    *              1.1.2 如果传入的 key > root.key，那么继续在 root 的右子树中找，从 root 的右孩子节点(root.right)开始。
    *              1.1.3 如果恰好 key == root.key，那么直接根据 root 节点的 value 值即可。
    *  2. 后面的循环规则一样，把遍历到的当前节点作为起始节点，逐步往下找。
    */
   final Entry<K,V> getEntryUsingComparator(Object key) {
       @SuppressWarnings("unchecked")
           K k = (K) key;
       Comparator<? super K> cpr = comparator;
       if (cpr != null) {
           Entry<K,V> p = root;
           while (p != null) {
               int cmp = cpr.compare(k, p.key);
               if (cmp < 0)
                   p = p.left;
               else if (cmp > 0)
                   p = p.right;
               else
                   return p;
           }
       }
       return null;
   }
   ```

#### 3.2.5 remove 方法

1. `remove()` 方法可以分为两个步骤，先是找到这个节点，直接调用了上面介绍的 `getEntry()` 方法，然后是执行删除操作，调用的是 `deleteEntry()` 方法，具体源码如下：
   
   ```java
   public V remove(Object key) {
       Entry<K,V> p = getEntry(key);
       if (p == null)
           return null;
   
       V oldValue = p.value;
       deleteEntry(p);
       return oldValue;
   }
   ```
2. `deleteEntry()` 的过程可参考[红黑树删除](https://notebook.grayson.top/project-53/doc-891/#2-3-1-%E4%BA%8C%E5%8F%89%E6%90%9C%E7%B4%A2%E6%A0%91%E5%88%A0%E9%99%A4)，具体源码如下：

```java
private void deleteEntry(Entry<K,V> p) {
    modCount++;
    size--;

    //  当左右子节点都不为空时，通过 successor(p) 遍历红黑树找到后继节点 s，
    //  然后将后继节点 s 的 key 和 value 复制到当前节点 p 中，最后删除节点 s（通过将节点 p 引用指向 s）
    if (p.left != null && p.right != null) {
        Entry<K,V> s = successor(p);
        p.key = s.key;
        p.value = s.value;
        p = s;
    }

    Entry<K,V> replacement = (p.left != null ? p.left : p.right);

    if (replacement != null) {
        //  至少有一个子节点不为 null，直接用这个有值的节点替换掉当前节点，给 replacement 的 parent 属性赋值，
        //  给 parent 节点的 left 属性和 right 属性赋值，同时要记住叶子节点必须为 null，当删除的节点为黑色节点时，需要通过 fixAfterDeletion 方法进行自平衡处理
        //  将待删除节点的子节点挂到待删除节点的父节点上
        replacement.parent = p.parent;
        if (p.parent == null)
            root = replacement;
        else if (p == p.parent.left)
            p.parent.left  = replacement;
        else
            p.parent.right = replacement;

        p.left = p.right = p.parent = null;

        if (p.color == BLACK)
            //  删除的节点为黑色节点，需要通过 fixAfterDeletion 方法进行自平衡处理
            fixAfterDeletion(replacement);
    } else if (p.parent == null) {
        //  要删除的节点为根节点，直接删除即可
        root = null;
    } else {
        //  没有子节点
        if (p.color == BLACK)
            //  删除的节点为黑色节点，需要通过 fixAfterDeletion 方法进行自平衡处理
            fixAfterDeletion(p);

        if (p.parent != null) {
            if (p == p.parent.left)
                p.parent.left = null;
            else if (p == p.parent.right)
                p.parent.right = null;
            p.parent = null;
        }
    }
}
```

3. `fixAfterDeletion()` 的过程可参考[删除后红黑树的调整](https://notebook.grayson.top/project-53/doc-891/#2-3-2-%E5%88%A0%E9%99%A4%E5%90%8E%E7%BA%A2%E9%BB%91%E6%A0%91%E7%9A%84%E8%B0%83%E6%95%B4)，具体源码如下：
   
   ```java
   private void fixAfterDeletion(Entry<K,V> x) {
       while (x != root && colorOf(x) == BLACK) {
           /**
            * x 不是根节点且颜色为黑色
            * 首先分两种情况，当前节点 x 是左节点或者当前节点 x 是右节点，这两种情况都是下面四种场景，
            * 这里通过代码分析一下 x 为左节点的情况，右节点可参考左节点理解，因为他们非常相似
            */
           if (x == leftOf(parentOf(x))) {
               Entry<K,V> sib = rightOf(parentOf(x));
   
               /**
                * 场景 1：当 x 是左黑节点，兄弟节点 sib 是红色节点
                * 兄弟节点由红转黑，父节点由黑转红，按父节点左旋
                * 左旋后树的结构变化了，这时重新赋值 sib，此时 sib 指向了 x 的兄弟节点
                */
               if (colorOf(sib) == RED) {
                   setColor(sib, BLACK);
                   setColor(parentOf(x), RED);
                   rotateLeft(parentOf(x));
                   sib = rightOf(parentOf(x));
               }
   
               /**
                * 场景 2：节点 x、x 的兄弟节点 sib、sib 的左子节点和右子节点都为黑色时，
                * 需要将该节点 sib 由黑变红，同时将 x 指向当前 x 的父节点
                */
               if (colorOf(leftOf(sib))  == BLACK &&
                   colorOf(rightOf(sib)) == BLACK) {
                   setColor(sib, RED);
                   x = parentOf(x);
               } else {
                   /**
                    * 场景 3：节点 x、x 的兄弟节点 sib、sib 的右子节点都为黑色，sib 的左子节点为红色时，
                    * 需要将 sib 左子节点设置为黑色，sib 节点设置为红色，同时按 sib 右旋，
                    * 再将 sib 指向 x 的兄弟节点
                    */
                   if (colorOf(rightOf(sib)) == BLACK) {
                       setColor(leftOf(sib), BLACK);
                       setColor(sib, RED);
                       rotateRight(sib);
                       sib = rightOf(parentOf(x));
                   }
                   /**
                    * 场景 4：节点 x、x 的兄弟节点 sib 都为黑色，而 sib 的左右子节点都为红色或者右子节点为红色、左子节点为黑色时，
                    * 需要将 sib 节点的颜色设置成和 x 的父节点 p 相同的颜色，设置 x 的父节点为黑色，设置 sib 右子节点为黑色，
                    * 左旋 x 的父节点 p，然后将 x 赋值为 root
                    */
                   setColor(sib, colorOf(parentOf(x)));
                   setColor(parentOf(x), BLACK);
                   setColor(rightOf(sib), BLACK);
                   rotateLeft(parentOf(x));
                   x = root;
               }
           } else { // x 是右节点的情况
               Entry<K,V> sib = leftOf(parentOf(x));
   
               if (colorOf(sib) == RED) {
                   setColor(sib, BLACK);
                   setColor(parentOf(x), RED);
                   rotateRight(parentOf(x));
                   sib = leftOf(parentOf(x));
               }
   
               if (colorOf(rightOf(sib)) == BLACK &&
                   colorOf(leftOf(sib)) == BLACK) {
                   setColor(sib, RED);
                   x = parentOf(x);
               } else {
                   if (colorOf(leftOf(sib)) == BLACK) {
                       setColor(rightOf(sib), BLACK);
                       setColor(sib, RED);
                       rotateLeft(sib);
                       sib = leftOf(parentOf(x));
                   }
                   setColor(sib, colorOf(parentOf(x)));
                   setColor(parentOf(x), BLACK);
                   setColor(leftOf(sib), BLACK);
                   rotateRight(parentOf(x));
                   x = root;
               }
           }
       }
   
       setColor(x, BLACK);
   }
   ```

## 参考文献

1. [Java 8 系列之重新认识 HashMap](https://tech.meituan.com/2016/06/24/java-hashmap.html)。
2. [第三天：HashMap 为什么是线程不安全的](https://zhuanlan.zhihu.com/p/42703011)。
3. [ConcurrentHashMap 实现原理及源码分析](https://www.cnblogs.com/chengxiao/p/6842045.html)。
4. [HashMap 实现原理及源码分析](https://www.cnblogs.com/chengxiao/p/6059914.html)。
5. [HashMap 1.7 和 1.8 的区别 --答到面试官怀疑人生](https://www.geek-share.com/detail/2810195384.html)。
6. [Java 容器之 ConcurrentHashMap](https://dyfloveslife.github.io/2020/03/24/JavaSrc-ConcurrentHashMap)。
7. [JAVA8 的 ConcurrentHashMap 为什么放弃了分段锁，有什么问题吗，如果你来设计，你如何设计。](https://github.com/woniu201/interview-reference/blob/main/04.%E8%85%BE%E8%AE%AF%E7%AF%87/4.1.6%20JAVA8%E7%9A%84ConcurrentHashMap%E4%B8%BA%E4%BB%80%E4%B9%88%E6%94%BE%E5%BC%83%E4%BA%86%E5%88%86%E6%AE%B5%E9%94%81%EF%BC%8C%E6%9C%89%E4%BB%80%E4%B9%88%E9%97%AE%E9%A2%98%E5%90%97%EF%BC%8C%E5%A6%82%E6%9E%9C%E4%BD%A0%E6%9D%A5%E8%AE%BE%E8%AE%A1%EF%BC%8C%E4%BD%A0%E5%A6%82%E4%BD%95%E8%AE%BE%E8%AE%A1.md)
8. [TreeMap 实现原理及源码分析之 JDK8](https://www.cnblogs.com/nananana/p/10426377.html)。
9. [TreeMap 原理实现及常用方法](https://www.cnblogs.com/LiaHon/p/11221634.html)。

