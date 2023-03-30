---
sidebar_position: 1
---

## 1 题目

运用你所掌握的数据结构，设计和实现一个  LRU (最近最少使用) 缓存机制 。
**实现 LRUCache 类：**

* LRUCache(int capacity) 以正整数作为容量 capacity 初始化 LRU 缓存
* int get(int key) 如果关键字 key 存在于缓存中，则返回关键字的值，否则返回 -1 。
* void put(int key, int value) 如果关键字已经存在，则变更其数据值；如果关键字不存在，则插入该组「关键字-值」。当缓存容量达到上限时，它应该在写入新数据之前删除最久未使用的数据值，从而为新的数据值留出空间。

**进阶：** 你是否可以在 O(1) 时间复杂度内完成这两种操作？

**示例：**

```txt
输入
["LRUCache", "put", "put", "get", "put", "get", "put", "get", "get", "get"]
[[2], [1, 1], [2, 2], [1], [3, 3], [2], [4, 4], [1], [3], [4]]
输出
[null, null, null, 1, null, -1, null, -1, 3, 4]

解释
LRUCache lRUCache = new LRUCache(2);
lRUCache.put(1, 1); // 缓存是 {1=1}
lRUCache.put(2, 2); // 缓存是 {1=1, 2=2}
lRUCache.get(1);    // 返回 1
lRUCache.put(3, 3); // 该操作会使得关键字 2 作废，缓存是 {1=1, 3=3}
lRUCache.get(2);    // 返回 -1 (未找到)
lRUCache.put(4, 4); // 该操作会使得关键字 1 作废，缓存是 {4=4, 3=3}
lRUCache.get(1);    // 返回 -1 (未找到)
lRUCache.get(3);    // 返回 3
lRUCache.get(4);    // 返回 4
```

**提示：**

* 1 <= capacity <= 3000
* 0 <= key <= 3000
* 0 <= value <= 104
* 最多调用 3 * 104 次 get 和 put

## 2 解题思路

> LRU 缓存机制的原理详见[最近最少使用法](https://ricear.com/project-26/doc-342/#2-5-%E6%9C%80%E8%BF%91%E6%9C%80%E5%B0%91%E4%BD%BF%E7%94%A8%E6%B3%95-Least-Recently-Used--LRU-)。

### 2.1 双向链表

#### 2.1.1 问题解析

1. 这种方法采用的是**哈希表**和**双向链表**相结合的方式，其中哈希表中的**key**存储的是缓存的**key**，**value**存储的是**当前缓存在双向链表中的地址**。
2. 当执行 $get(key)$ 方法时：
   1. 如果 $map$ 中**不存在当前** $key$，则**直接返回-1**。
   2. 否则，**获取当前 $key$ 对应的节点**，并将其**移动到链表头部**，然后**返回当前节点对应的值**。
3. 当执行 $put(key,value)$ 方法时：
   1. 判断 $map$ 中**是否包含当前** $key$：
      
      1. 如果**不包含**的话，判断一下 $map$**中的容量是否大于等于**$capacity$：
         1. 如果 $map$ **中的容量大于或等于** $capacity$：
            1. **将尾部节点从链表中删除**。
            2. **根据 $(key,value)$ 创建一个节点**，并将当前节点**添加到链表头部**。
            3. **将 $key$ 对应的元素从 $map$ 中删除**。
         2. 如果 $map$ **中的容量小于** $capacity$：
            1. **根据 $(key,value)$ 创建一个节点**，并将当前节点**添加到链表头部**。
            2. **将对应的元素添加到 $map$ 中**。
      2. 如果包含的话：
         1. **更新链表中当前 $key$ 对应节点的** $value$。
         2. **将该节点移动到链表头部**。
      
      <iframe src="https://www.youtube.com/embed/4c8k2OKM0U0?list=PLHH5EZ_Bw-YGWD--DBu0-jqb2ptqG_Igg" width="100%" height="480" allow="autoplay" allowfullscreen="true"></iframe>

#### 2.1.2 参考代码

```java
class LRUCache {

    class DLinkNode {
        int key;
        int value;
        //  前驱结点
        DLinkNode prev;
        //  后驱节点
        DLinkNode next;

        DLinkNode() {
        }

        DLinkNode(int _key, int _value) {
            this.key = _key;
            this.value = _value;
        }
    }

    //  模仿 链头 和 链尾
    DLinkNode head, tail;
    //  存储 key 及其对应的链表
    HashMap<Integer, DLinkNode> map = new HashMap<>();

    int capacity;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        //  初始化链表的头部和尾部
        head = new DLinkNode();
        tail = new DLinkNode();
        head.next = tail;
        tail.prev = head;
    }

    public int get(int key) {
        if (!map.containsKey(key)) {
            return -1;
        } else {
            //  获取当前 key 对应的节点，并将其移动至链表头部
            DLinkNode node = map.get(key);
            int value = node.value;
            moveToHead(key, node);
            return value;
        }
    }

    public void put(int key, int value) {
        if (map.size() >= capacity && !map.containsKey(key)) {

            //  将链表尾部的节点删除
            DLinkNode tmpNode = tail.prev;
            tmpNode.prev.next = tail;
            tail.prev = tmpNode.prev;
            map.remove(tmpNode.key);
        }
        if (!map.containsKey(key)) {
            //  将当前 key 对应的节点添加到链表头部
            DLinkNode node = new DLinkNode(key, value);
            map.put(key, node);
            addToHead(node);
        } else {
            //  更新当前 key 对应的元素并将其添加到链表头部
            moveToHeadAndUpdateValue(key, value);
        }
    }

    /**
     * 将当前节点添加到链表头部
     * @param node  当前节点
     */
    public void addToHead(DLinkNode node) {
        node.prev = head;
        node.next = head.next;
        head.next = node;
        node.next.prev = node;
    }

    /**
     * 更新当前 key 对应节点的值，然后将该节点移动到链表头部
     * @param key   key
     * @param value value
     */
    public void moveToHeadAndUpdateValue(int key, int value) {
        DLinkNode node = map.get(key);
        node.value = value;
        moveToHead(key, node);
    }

    /**
     * 将当前节点移动到链表头部
     * @param key   key
     * @param node  当前节点
     */
    public void moveToHead(int key, DLinkNode node) {
        node.next.prev = node.prev;
        node.prev.next = node.next;

        head.next.prev = node;
        node.next = head.next;
        node.prev = head;
        head.next = node;
    }
}
```

#### 2.1.3 扩展题目

##### 2.1.3.1 线程安全的 LRU

###### 2.1.3.1.1 问题解析

1. 要实现线程安全主要在原来的基础上**将 `HashMap` 更改为 `ConcurrentHashMap`**，然后**在 `put` 和 `get` 操作的使用 `ReentrantLock` 进行加锁**即可。

###### 2.1.3.1.2 参考代码

```java
class LRUCache {

    class DLinkNode {
        int key;
        int value;
        //  前驱结点
        DLinkNode prev;
        //  后驱节点
        DLinkNode next;

        DLinkNode() {
        }

        DLinkNode(int _key, int _value) {
            this.key = _key;
            this.value = _value;
        }
    }

    //  模仿 链头 和 链尾
    DLinkNode head, tail;
    //  存储 key 及其对应的链表
    ConcurrentHashMap<Integer, DLinkNode> map = new ConcurrentHashMap<>();
    //  使用 ReadWriteLock 进行加锁，保证线程安全
    ReadWriteLock lock = new ReentrantReadWriteLock();
    Lock readLock = lock.readLock();
    Lock writeLock = lock.writeLock();

    int capacity;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        //  初始化链表的头部和尾部
        head = new DLinkNode();
        tail = new DLinkNode();
        head.next = tail;
        tail.prev = head;
    }

    public int get(int key) {
        //  加读锁
        readLock.lock();
        try {
            if (!map.containsKey(key)) {
                return -1;
            } else {
                //  获取当前 key 对应的节点，并将其移动至链表头部
                DLinkNode node = map.get(key);
                int value = node.value;
                moveToHead(key, node);
                return value;
            }
        } finally {
            //  释放读锁
            readLock.unlock();
        }
    }

    public void put(int key, int value) {
        //  加写锁
        writeLock.lock();
        try {
            if (map.size() >= capacity && !map.containsKey(key)) {

                //  将链表尾部的节点删除
                DLinkNode tmpNode = tail.prev;
                tmpNode.prev.next = tail;
                tail.prev = tmpNode.prev;
                map.remove(tmpNode.key);
            }
            if (!map.containsKey(key)) {
                //  将当前 key 对应的节点添加到链表头部
                DLinkNode node = new DLinkNode(key, value);
                map.put(key, node);
                addToHead(node);
            } else {
                //  更新当前 key 对应的元素并将其添加到链表头部
                moveToHeadAndUpdateValue(key, value);
            }
        } finally {
            //  释放写锁
            writeLock.unlock();
        }
    }

    /**
     * 将当前节点添加到链表头部
     * @param node  当前节点
     */
    public void addToHead(DLinkNode node) {
        node.prev = head;
        node.next = head.next;
        head.next = node;
        node.next.prev = node;
    }

    /**
     * 更新当前 key 对应节点的值，然后将该节点移动到链表头部
     * @param key   key
     * @param value value
     */
    public void moveToHeadAndUpdateValue(int key, int value) {
        DLinkNode node = map.get(key);
        node.value = value;
        moveToHead(key, node);
    }

    /**
     * 将当前节点移动到链表头部
     * @param key   key
     * @param node  当前节点
     */
    public void moveToHead(int key, DLinkNode node) {
        node.next.prev = node.prev;
        node.prev.next = node.next;

        head.next.prev = node;
        node.next = head.next;
        node.prev = head;
        head.next = node;
    }
}
```

##### 2.1.3.2 带有超时自动删除且线程安全的 LRU

###### 2.1.3.2.1 问题解析

> LRU 的超时自动删除策略可以参考 Reis 的[过期键删除策略](https://ricear.com/project-37/doc-812/#1-2-%E8%BF%87%E6%9C%9F%E9%94%AE%E5%88%A0%E9%99%A4%E7%AD%96%E7%95%A5)。

1. 可以使用一个**定时器线程池**来实现 LRU 的超时自动删除功能，**当添加一个元素时**，**同时将该元素及其对应的超时时间添加到定时器线程池中**，**然后当达到了超时时间时**，**定时器线程自动将该元素从 LRU 缓存中移除**。

###### 2.1.3.2.2 参考代码

```java
class LRUCache {

    class DLinkNode {
        int key;
        int value;
        //  前驱结点
        DLinkNode prev;
        //  后驱节点
        DLinkNode next;

        DLinkNode() {
        }

        DLinkNode(int _key, int _value) {
            this.key = _key;
            this.value = _value;
        }
    }

    //  模仿 链头 和 链尾
    DLinkNode head, tail;
    //  存储 key 及其对应的链表
    ConcurrentHashMap<Integer, DLinkNode> map = new ConcurrentHashMap<>();
    //  使用 ReadWriteLock 进行加锁，保证线程安全
    ReadWriteLock lock = new ReentrantReadWriteLock();
    Lock readLock = lock.readLock();
    Lock writeLock = lock.writeLock();

    ScheduledExecutorService scheduledExecutorService;

    int capacity;

    public LRUCache(int capacity) {
        this.capacity = capacity;
        //  初始化链表的头部和尾部
        head = new DLinkNode();
        tail = new DLinkNode();
        head.next = tail;
        tail.prev = head;
        //  初始化定时器线程池
        scheduledExecutorService = Executors.newScheduledThreadPool(capacity);
    }

    public int get(int key) {
        //  加读锁
        readLock.lock();
        try {
            if (!map.containsKey(key)) {
                return -1;
            } else {
                //  获取当前 key 对应的节点，并将其移动至链表头部
                DLinkNode node = map.get(key);
                int value = node.value;
                moveToHead(key, node);
                return value;
            }
        } finally {
            //  释放读锁
            readLock.unlock();
        }
    }

    public void put(int key, int value, long expireTime) {
        //  加写锁
        writeLock.lock();
        try {
            if (map.size() >= capacity && !map.containsKey(key)) {

                //  将链表尾部的节点删除
                DLinkNode tmpNode = tail.prev;
                tmpNode.prev.next = tail;
                tail.prev = tmpNode.prev;
                map.remove(tmpNode.key);
            }
            if (!map.containsKey(key)) {
                //  将当前 key 对应的节点添加到链表头部
                DLinkNode node = new DLinkNode(key, value);
                map.put(key, node);
                addToHead(node);
            } else {
                //  更新当前 key 对应的元素并将其添加到链表头部
                moveToHeadAndUpdateValue(key, value);
            }
            //  将元素添加到定时器线程池中
            if (expireTime > 0) {
                removeAfterExpireTime(key, expireTime);
            }
        } finally {
            //  释放写锁
            writeLock.unlock();
        }
    }

    /**
     * 将当前节点添加到链表头部
     * @param node  当前节点
     */
    public void addToHead(DLinkNode node) {
        node.prev = head;
        node.next = head.next;
        head.next = node;
        node.next.prev = node;
    }

    /**
     * 更新当前 key 对应节点的值，然后将该节点移动到链表头部
     * @param key   key
     * @param value value
     */
    public void moveToHeadAndUpdateValue(int key, int value) {
        DLinkNode node = map.get(key);
        node.value = value;
        moveToHead(key, node);
    }

    /**
     * 将当前节点移动到链表头部
     * @param key   key
     * @param node  当前节点
     */
    public void moveToHead(int key, DLinkNode node) {
        node.next.prev = node.prev;
        node.prev.next = node.next;

        head.next.prev = node;
        node.next = head.next;
        node.prev = head;
        head.next = node;
    }

    /**
     * 自动删除 LRU 缓存中的过期元素
     * @param key   LRU 缓存的 key
     * @param expireTime    LRU 缓存的过期时间
     */
    private void removeAfterExpireTime(final int key, long expireTime) {
        final DLinkNode node = map.get(key);
        scheduledExecutorService.schedule(new Runnable() {
            public void run() {
                //  从双向链表中移除相应节点
                DLinkNode tmpNode = node.prev;
                tmpNode.next = node.next;
                node.next.prev = tmpNode;
                node.prev = null;
                node.next = null;
                //  从 map 中移除相应的元素
                map.remove(key);
            }
        }, expireTime, TimeUnit.MILLISECONDS);
    }
}
```

## 3 参考文献

1. [146. LRU 缓存机制](https://leetcode-cn.com/problems/lru-cache)。
2. [LRU 缓存机制【官方题解】](https://leetcode-cn.com/problems/lru-cache/solution/lruhuan-cun-ji-zhi-by-leetcode-solution)。
3. [Thread-safe LRU Cache Implementation](https://leetcode.com/problems/lru-cache/discuss/1851511/thread-safe-lru-cache-implementation)。
4. [实现一个线程安全带超时时间的 lru(原版 + 变种)](https://leetcode.cn/problems/lru-cache/solution/by-sbsb1122333-kaw0)。
5. [Simple LRU cache with an expiration time](https://codereview.stackexchange.com/questions/60388/simple-lru-cache-with-an-expiration-time)。
6. [LRU 缓存实现案例](https://www.cnblogs.com/helloworldcode/p/13383856.html)。

