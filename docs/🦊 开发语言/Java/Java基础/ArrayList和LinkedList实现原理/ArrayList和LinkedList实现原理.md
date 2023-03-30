---
sidebar_position: 3
---

> 如无特殊说明，下面内容的叙述基于的 JDK 版本为[JDK 1.8.0_181](https://ricear.com/media/attachment/2021/08/jdk1.8.0_181.zip)。

## 1 ArrayList

### 1.1 概述

1. ArrayList 的**底层数据结构是数组**，虽然**对于用户来说 ArrayList 是个动态的数组**，但是**实际上底层是个定长数组**，只是**在必要的时候**，**对底层的数组进行扩容**，**每次扩容 1.5 倍**，但是**扩容**、**删除都是有代价的**，**极端情况下**，**需要将大量的元素进行移位**。
2. ArrayList**不是线程安全的**，**只能在单线程环境下使用**，**多线程环境下可以考虑用 `Collections.synchronizedList(List<T> list)` 返回一个线程安全的 ArrayList 类**，**也可以使用 `concurrent` 并发包下的 `CopyOnWriteArrayList` 类**。
3. ArrayList**实现了 Serializable 接口**，因此他**支持序列化**，**能够通过序列化传输**，**实现了 RandomAccess 接口**，**支持快速随机访问**，实际上就是**通过下标序号进行快速访问**，**实现了 Cloneable 接口**，**能被克隆**。

### 1.2 实现原理

#### 1.2.1 构造函数

ArrayList 的构造函数一共有三种，分别是**无参构造**、**传入一个整数**、**传入一个集合**。

##### 1.2.1.1 无参构造

1. ArrayList 的无参构造函数源码如下：

   ```java
   transient Object[] elementData;

   private static final Object[] DEFAULTCAPACITY_EMPTY_ELEMENTDATA = {};

   public ArrayList() {
       this.elementData = DEFAULTCAPACITY_EMPTY_ELEMENTDATA;
   }
   ```
2. 通过源码我们可以看出，ArrayList 的**底层是一个 `Object[]`**，**添加到 ArrayList 中的数据都保存在了 `elementData` 属性中**。
3. 当调用 `new ArrayList<>()` 时，**将一个空数组 `{}` 赋值给了 `elementData`**，这个时候**集合的长度** `size`**为默认长度 0**。

##### 1.2.1.2 整数有参构造

1. ArrayList 的整数有参构造函数源码如下：

   ```java
   transient Object[] elementData;

   private static final Object[] EMPTY_ELEMENTDATA = {};

   public ArrayList(int initialCapacity) {
       if (initialCapacity > 0) {
           this.elementData = new Object[initialCapacity];
       } else if (initialCapacity == 0) {
           this.elementData = EMPTY_ELEMENTDATA;
       } else {
           throw new IllegalArgumentException("Illegal Capacity: "+
                                              initialCapacity);
       }
   }
   ```
2. 通过源码可知，当调用 `new ArrayList<>(capacity)` 时，ArrayList 会**根据传入的长度**，**创建一个大小为 `capacity` 的 Object 数组赋值给 `elementData`**，如果 `capacity`**为 0 的话**，会**将一个空数组赋值给 `elementData`**。

##### 1.2.1.3 集合有参构造

1. ArrayList 的集合有参构造函数源码如下：

   ```java
   transient Object[] elementData;

   private static final Object[] EMPTY_ELEMENTDATA = {};

   public ArrayList(Collection<? extends E> c) {
       elementData = c.toArray();
       if ((size = elementData.length) != 0) {
           // c.toArray might (incorrectly) not return Object[] (see 6260652)
           if (elementData.getClass() != Object[].class)
               elementData = Arrays.copyOf(elementData, size, Object[].class);
       } else {
           // replace with empty array.
           this.elementData = EMPTY_ELEMENTDATA;
       }
   }
   ```

   ```java
   public static <T,U> T[] copyOf(U[] original, int newLength, Class<? extends T[]> newType) {
       @SuppressWarnings("unchecked")
       T[] copy = ((Object)newType == (Object)Object[].class)
           ? (T[]) new Object[newLength]
           : (T[]) Array.newInstance(newType.getComponentType(), newLength);
       System.arraycopy(original, 0, copy, 0,
                        Math.min(original.length, newLength));
       return copy;
   }
   ```
2. 通过源码可知：

   1. 当**传递一个实现了 Collections 接口的类后**，**会将传递的集合调用 `toArray()` 方法转化为数组**，然后**将其赋值给 `elementData`**。
   2. 如果**传入的集合类型和我们定义用来保存添加到集合中值的 `Object[]` 类型不一致**（例如`List<String> setList = new ArrayList<>(new HashSet());`）时，会**定义一个新的 `Object[]`**，然后**调用 `Arrays.copyOf()` 将原数组中的数据拷贝到新数组中**，最后再**把新数组赋值给 `elementData`**。

#### 1.2.2 常用方法

##### 1.2.2.1 add(E element)

1. `add(E element)` 的源码如下：

   ```java
   public boolean add(E e) {
       ensureCapacityInternal(size + 1);  // Increments modCount!!
       elementData[size++] = e;
       return true;
   }
   ```
2. 这里 `ensureCapacityInternal()`**的作用为保证在不停的往 ArrayList 插入数据时**，**数组不会越界**，**并且实现自动扩容**，源码如下：

```java
private void ensureCapacityInternal(int minCapacity) {
    ensureExplicitCapacity(calculateCapacity(elementData, minCapacity));
}
```

3. 这里的 `minCapacity` 实际上就是**在调用完当前这次 `add` 操作之后**，**数组中元素的数量**，比如调用 `add` 之前，ArrayList 中有 3 个元素，那么此时这个 `minCapacity` 的值就为 4。
4. 同时，可以看到**将函数 `calculateCapacity()` 的返回值作为了 `ensureExplicitCapacity()` 的输入**，`calculateCapacity()` 的功能为：

   1. 如果**当前数组为空**，则**直接返回数组默认长度**（10）**和 `minCapacity` 的最大长度**。
   2. 如果**当前数组不为空**，则**直接返回 `minCapacity`**。

   源码如下：

   ```java
   private static final int DEFAULT_CAPACITY = 10;

   private static int calculateCapacity(Object[] elementData, int minCapacity) {
       if (elementData == DEFAULTCAPACITY_EMPTY_ELEMENTDATA) {
           return Math.max(DEFAULT_CAPACITY, minCapacity);
       }
       return minCapacity;
   }
   ```
5. 接下来是 `ensureExplicitCapacity()`，源码如下：

   ```java
   private void ensureExplicitCapacity(int minCapacity) {
       modCount++;

       // overflow-conscious code
       if (minCapacity - elementData.length > 0)
           grow(minCapacity);
   }
   ```

   1. `modCount`**表示该 ArrayList 被更改过多少次**，**这里的更改不只是新增**，**删除也是一种更改**。
   2. 通过上面的了解我们知道：
      1. **如果添加一个元素后数组内的元素个数是小于等于数组长度的**，则 `minCapacity`**的值一定小于 `elementData` 的长度**。
      2. **如果添加一个元素后数组内的元素个数是大于数组长度的**，则 `minCapacity`**的值一定大于 `elementData` 的长度**，**此时就会调用 `grow()` 函数来进行数组扩容**，源码如下：

         ```java
         private static final int MAX_ARRAY_SIZE = Integer.MAX_VALUE - 8;

         private void grow(int minCapacity) {
             // overflow-conscious code
             int oldCapacity = elementData.length;
             int newCapacity = oldCapacity + (oldCapacity >> 1);
             if (newCapacity - minCapacity < 0)
                 newCapacity = minCapacity;
             if (newCapacity - MAX_ARRAY_SIZE > 0)
                 newCapacity = hugeCapacity(minCapacity);
             // minCapacity is usually close to size, so this is a win:
             elementData = Arrays.copyOf(elementData, newCapacity);
         }
         ```

         1. 扩容的核心逻辑很简单，即**新的数组长度 = 旧数组长度 + 旧数组长度 / 2**，即**ArrayList 的扩容是每次扩容 1.5 倍**。
         2. 这里可能会有一个疑问，因为上文提到**扩容时 `minCapacity` 的值和数组长度应该是相等的**，所以**新数组长度减去 `minCapacity` 应该永远大于 0**才对，为什么会有小于 0 的情况，这是因为 `addAll()`**底层也会调用 `ensureCapacityInternal()`**：

            1. `add()`**是往数组中添加单个元素**，而`addAll()` 则是**往数组中添加整个数组**。
            2. 例如我们**传入的数组元素有 20 个**，因为 ArrayList 的默认数组长度为 10，扩容一次之后长度为 15，因此**即使扩容一次还是不足以放下所有的元素**。
            3. 所以这时才会出现`newCapacity`**（扩容之后的数组长度）小于 `minCapacity`（执行完当前操作之后的数组内元素数量）的情况**。
         3. 如果**扩容后的长度大于 `MAX_ARRAY_SIZE`**，**就会调用 `hugeCapacity()` 函数**，源码如下：

            ```java
            private static int hugeCapacity(int minCapacity) {
                if (minCapacity < 0) // overflow
                    throw new OutOfMemoryError();
                return (minCapacity > MAX_ARRAY_SIZE) ?
                    Integer.MAX_VALUE :
                    MAX_ARRAY_SIZE;
            }
            ```

            1. 如果**扩容后的长度溢出了**，则**直接抛出 OOM 异常**。
            2. 否则，**保证其容量不会超过 `Integer.MAX_VALUE`**。
         4. 最后是**真正执行扩容的操作**，**调用了 `java.util` 包里的 `Arrays.copyOf()` 方法**。
6. 数组扩容完成后，就会**将本次添加的元素写入 `elementData` 的末尾**，即 `elementData[size++] = e`。

   ![图片](https://ricear.com/media/202108/2021-08-02_1647200.28581888628803354.png)
7. `add()` 方法可能会导致线程不安全：

   1. **多个线程进行 `add` 操作时可能会导致 `elementData` 数组越界**：

      1. 假如 ArrayList 的大小为 9，即`size = 9`。
      2. 线程 A 开始进入`add()` 方法，这时他获得的`size` 的值为 9，调用`ensureCapacityInternal()` 方法进行容量判断。
      3. 线程 B 此时也进入`add()` 方法，他获得的`size` 值也为 9，也开始调用`ensureCapacityInternal()` 方法进行容量判断。
      4. 线程 A 发现需求大小为 10，而`elementData` 的大小就为 10，可以容纳，于是他不再扩容，返回。
      5. 线程 B 也发现需求大小为 10，也可以容纳，返回。
      6. 线程 A 开始进行设置值的操作，即`elementData[size++] = e`，此时`size` 变为 10。
      7. 线程 B 也开始进行设置值的操作，他尝试设置`elementData[size++] = e`，而`elementData` 没有进行过扩容，他的下标最大为 9，此时就会报出一个数组越界的异常。
   2. **多线程进行 `elementData[size++] = e` 操作时会导致线程不安全**，因为 `elementData[size++] = e` 不是一个原子操作，他由如下两步操作构成：

      ```txt
      elementData[size] = e;
      size = size + 1;
      ```

      在单线程执行着两条代码时没有任何问题，但是当多线程环境下执行时，**可能会发生一个线程的值覆盖另一个线程的值**：

      1. 假如 ArrayList 的大小为 0，即`size = 0`。
      2. 线程 A 开始添加一个元素，值为`a`，此时他执行第一条操作，将`a` 放在了`elementData` 下标为 0 的位置上。
      3. 接着线程 B 刚好也要开始添加一个值为`b` 的元素，且走到了第一步操作，此时线程 B 获取到`size` 的值依然为 0，于是他将`b` 也放在了`elementData` 下标为 0 的位置上。
      4. 线程 A 开始将`size` 的值增加为 1。
      5. 线程 B 开始将`size` 的值增加为 2。
      6. 这样线程 A、B 执行完毕后，理想情况为`size` 为 2，`elementData` 下标 0 的位置为`a`，下标`1` 的位置为`b`，而实际情况变成了`size` 为 2，`elementData` 下标为 0 的位置变成了`b`，下标 1 的位置上什么都没有，后续除非使用`set` 方法修改此位置的值，否则将一直为`null`，因为`size` 为 2，添加元素时会从下标为 2 的位置上开始。

## 2 LinkedList

### 2.1 概述

1. LinkedList的类定义源码如下：

   ```java
   public class LinkedList<E>
       extends AbstractSequentialList<E>
       implements List<E>, Deque<E>, Cloneable, java.io.Serializable {}
   ```

   1. LinkedList是一个**继承于AbstractSequentialList的双向链表**，**可以被当做堆栈**、**队列或者双端队列进行操作**。
   2. LinkedList**实现了List接口**，**能对他进行列表操作**；**实现了Deque接口**，**能当做双端队列使用**；**实现了Cloneable接口**，**能克隆**；**实现了java.io.Serializable接口**，**支持序列化**，**能通过序列化去传输**。
   3. LinkedList**不是线程安全的**，**只能在单线程环境下使用**，**多线程环境下可以考虑用 `Collections.synchronizedList(List<T> list)` 返回一个线程安全的 LinkedList 类**，**也可以使用 `concurrent` 并发包下的 `CopyOnWriteArrayList` 类**。![](https://ricear.com/media/202108/2021-08-03_1030400.039698365669505686.png)
2. LinkedList的优缺点如下：

   1. **优点**：
      1. **添加和删除元素比较快**，**因为只是移动指针**，**并且不需要判断是否扩容**。
   2. **缺点**：
      1. **查询和遍历效率比较低**。
3. LinkedList的结构图如下：![](https://ricear.com/media/202108/2021-08-03_1026380.5915336679737497.png)

### 2.2 实现原理

#### 2.2.1 整体结构

1. LinkedList类就包括三个属性，具体源码如下：

   ```java
   transient int size = 0;

   transient Node<E> first;

   transient Node<E> last;
   ```

   1. `size`：用来**记录双向链表的大小**。
   2. `first`：用来**指向链表的头**。
   3. `last`：用来**指向链表的尾**。
2. 其中 `Node`是**内部类**，**表示LinkedList的每一个数据节点**，具体源码如下：

   ```java
   private static class Node<E> {
       E item;
       Node<E> next;
       Node<E> prev;

       Node(Node<E> prev, E element, Node<E> next) {
           this.item = element;
           this.next = next;
           this.prev = prev;
       }
   }
   ```

   1. `item`：**表示数据本身**。
   2. `next`：**表示指向下一个节点的指针**。
   3. `prev`：**表示指向上一个节点的指针**。
3. LinkedList的构造方法主要有两种，一种是**无参构造**，另一种是**有参构造**，即**调用 `addAll()`方法通过集合来构造LinkedList**，具体源码如下：

   ```java
   public LinkedList() {
   }

   public LinkedList(Collection<? extends E> c) {
       this();
       addAll(c);
   }
   ```

#### 2.2.2 常用方法

##### 2.2.2.1 add(E element)

1. 该方法是**在LinkedList的尾部插入元素**，因为**有 `last`指向链表尾部**，所以**只需要简单修改几个相关引用即可**，**花费的时间是常数时间**，具体源码如下：

   ```java
   public boolean add(E e) {
       linkLast(e);
       return true;
   }

   void linkLast(E e) {
       final Node<E> l = last;
       final Node<E> newNode = new Node<>(l, e, null);
       last = newNode;
       if (l == null)
           first = newNode;    /*原来链表为空，这是插入的第一个元素*/
       else
           l.next = newNode;
       size++;
       modCount++;
   }
   ```

   * 定义临时变量 `l`表示之前的 `last`。
   * 调用Node的有参构造方法创建新的节点 `newNode`，其 `prev`指向 `last`，`next`为 `null`。
   * 将 `newNode`赋值给 `last`。
   * 将 `l`的 ` next`指向 `newNode`。
   * 将LinkedList的长度 `size`加1，同时将LinkedList的修改次数 `modCount`加1。

     ![](https://ricear.com/media/202108/2021-08-03_105908.png)

## 参考文献

1. [Java 集合---ArrayList 的实现原理](https://zhuanlan.zhihu.com/p/68397302)。
2. [Java 集合 ArrayList 原理及使用](https://www.cnblogs.com/wlx6/p/12461894.html)。
3. [ArrayList 从源码角度剖析底层原理](https://mp.weixin.qq.com/s?src=11×tamp=1627874584&ver=3227&signature=cnQmzCSf3ms6p*IVkI3Sdo-49FsdoxkTTue745G6SOo44dgq9zDNfvFvB25ev9MTtrNE*bxjxUqUphupuGTwc00zetHTulMYVgJORVEbXGMg1UI7qDsTbFxHGpXPeh7H&new=1)。
4. [为什么说 ArrayList 是线程不安全的？](https://blog.csdn.net/u012859681/article/details/78206494)
5. [JDK8中LinkedList的工作原理剖析【我是攻城师】](https://mp.weixin.qq.com/s?src=11×tamp=1627955623&ver=3229&signature=32uwaNDwovuqVg-qPcfezO7TO2UL1nJrwUqTyuo2Hqp-NmlJYUPRPnqWcV35ySXPEEPoQhPdE559Jl6Yvf6ghy2BjBJ*QMMXdhjnXE-gfULNTYpnpmSJuD1DqorBhnt7&new=1)。
6. [LinkedList 的实现原理浅析【OSC开源社区】](https://mp.weixin.qq.com/s?src=11×tamp=1627955623&ver=3229&signature=ofAEeMGswVvID8DgRSDJRT8NMJsLwEv5cBKctrFStlp3iObZXou59Z5l8O7HoProLn1qFcTasQ67z9uNY-0U4DMjWQRgk26XJtL3O0LS1qjyd3t4WJUACNItoqWvxgww&new=1)。
7. [深入LinkedList原理源码解析【与你同在架构之路】](https://mp.weixin.qq.com/s?src=11×tamp=1627955623&ver=3229&signature=0oQFEmo4Mdfxz00z6F*3RwOA60In3CisBhQ1HemjBa0hCP8akDQYx6TH4w1*X4gX9dhxaWX8X55HMuzQYSYEQSJZgJ-QyHXcoLFgXs*b0OWma8MyYxlGYGkGEi1hlj0K&new=1)。
