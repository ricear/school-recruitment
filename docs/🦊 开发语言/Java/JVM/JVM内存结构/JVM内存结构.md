---
sidebar_position: 2
---

## 1 概述

JVM 内部使用**Java 内存模型**，在逻辑上将内存划分为**线程栈**（Thread Stacks）和**堆内存**（Heap）两个部分，如下图所示：

![4pajs.jpg (1148×816)](https://notebook.ricear.com/media/202105//1621914622.9091363.png)

### 1.1 线程栈

JVM 中，每个正在运行的线程，都有自己的**线程栈**。

1. **线程栈包含了当前正在执行的方法链或调用链上的所有方法的状态信息**， 所以线程栈又被称为**方法栈**或**调用栈**。
2. **线程栈里面保存了调用链上正在执行的所有方法中的局部变量：**
   1. **每个线程都只能访问自己的线程栈。**
   2. **每个线程都不能访问其他线程的局部变量。**
3. **即使两个线程正在执行完全相同的代码，但每个线程都会在自己的线程栈内创建对应代码中声明的局部变量，所以每个线程都有一份自己的局部变量副本：**
   1. 所有**原生类型的局部变量**都存储在**线程栈**中，因此**对其他线程是不可见的**。
   2. 线程可以**将一个原生变量值的副本传给另一个线程**，但**不能共享原生局部变量本身**。

### 1.2 堆内存

堆内存又称为**共享堆**，堆中的所有对象，可以被所有线程访问，只要他们能拿到对象的引用地址：

* **如果一个线程可以访问某个对象时，也就可以访问该对象的成员变量。**
* 如果两个线程**同时调用某个对象的同一个方法**，则他们**都可以访问到这个对象的成员变量**，但**每个线程的局部变量副本是独立的**。

**虽然各个线程自己使用的局部变量都在自己的栈上，但是大家可以共享堆上的对象，各个不同线程访问同一个对象实例的基础类型的成员变量，会给每个线程一个变量的副本。**

![6j9fe.jpg (1688×1078)](https://notebook.ricear.com/media/202105//1621914622.9118786.png)

### 1.3 总结

1. 如果是**原生数据类型的局部变量**，那么他的内容就全部保留在**线程栈**中。
2. 如果是**对象引用**，在**对象的引用地址**保存在**栈**中，而**实际的对象内容**保存在**堆**中。
3. **对象的成员变量**与**对象本身**一起存储在堆上，不管成员变量的类型是原生数值，还是对象引用。
4. **类的静态变量**则和**类定义**一样都保存在**堆**中。

总结一下：

1. **原始数据类型的局部变量和对象引用地址在栈上。**
2. **对象、对象成员与类定义、静态变量在堆上。**

![ksq1n.jpg (1728×1098)](https://notebook.ricear.com/media/202105//1621914622.9144847.png)

## 2 线程栈

![6yhj7.jpg (1450×986)](https://notebook.ricear.com/media/202105//1621914622.9165661.png)

* 每启动一个线程，JVM 就会在栈空间分配对应的**线程栈**。
* 线程栈也叫做**Java 方法栈**，如果使用了**JNI**（Java Native Interface）方法，则会分配一个单独的**本地方法栈**（Native Stack）。
* 线程执行过程中，一般会有多个方法组成**调用栈**（Stack Trace），比如 A 调用 B，B 调用 C......。每执行到一个方法，就会创建对应的**栈帧**（Frame）。
  * 栈帧是一个逻辑上的概念，具体的大小在一个方法完成后基本上就能确定。
  * 比如**返回值**需要有一个空间存放；每个**局部变量**都需要对应的地址空间；此外还有给指令使用的**操作数栈**；以及**Class 指针**（标识这个栈帧对应的是哪个类的方法，指向非堆里面的 Class 对象）。

![ze6dq.jpg (1448×844)](https://notebook.ricear.com/media/202105//1621914622.9184902.png)

## 3 堆

![u0xac.jpg (1474×1010)](https://notebook.ricear.com/media/202105//1621914622.9199617.png)

1. 堆内存是所有线程共用的内存空间，理论上大家都可以访问。
2. 逻辑上的 Java 堆划分为 `堆`（Heap）和 `堆外`（Non-Heap）两个部分：

### 3.1 堆内存（Heap Memory）

JVM 将 Heap 内存分为 `年轻代`（Young Generation）和 `老年代`（Old Generation）两部分。

#### 3.1.1 年轻代

年轻代划分为三个内存池，分别为 `新生代`（Eden Space）和 `存活区`（Survivor Spaces）。

##### 3.1.1.1 新生代（Eden Space）

新生代，也叫**伊甸区**，**用来分配新创建的对象**。

1. 通常会有多个线程同时创建对象，所以 Eden 区被划分为多个**线程本地分配缓冲区**（Thread Local Allocation Buffer, TLAB）。通过这种缓冲区的划分，大部分对象直接由 JVM 在对应线程的**TLAB**中分配，避免与其他线程的同步操作。
   1. 如果 TLAB 中没有足够的内存空间时，就会在**共享 Eden 区**（Shared Eden Space）之中分配。
      1. 如果共享 Eden 区也没有足够的空间，就会触发一次**年轻代 GC**来释放内存空间。
         1. 如果 GC 之后 Eden 区依然没有足够的空闲内存区域，则对象就会被分配到**老年代空间**（Old Generation）。
2. 当 Eden 区进行垃圾回收时，GC 将从所有 `root` 可达的对象过一遍，并标记为存活对象。
3. **标记阶段完成后，Eden 区所有存活的对象都会被复制到存活区（Survivor Spaces）里面，整个 Eden 区就可以被认为是空的，然后就能用来分配新对象，** 这种方法称为**标记-复制算法**（Mark and Copy）。

##### 3.1.1.2 存活区（Survivor Spaces）

Eden 区的旁边是两个**存活区**（Survivor Spaces），称为 **from 空间**和**to 空间**，**任意时刻总有一个存活区是空的。**

1. 空的那个存活区用于在下一次年轻代 GC 时存放收集的对象，年轻代中所有的存活对象（包括**Eden 区**和**非空的那个 from 存活区**）都会被复制到**to 存活区**。GC 过程完成后，to 区有对象，而 from 区没有对象，二者的角色正好进行切换，from 变成 to，to 变成 from。
2. 存活的对象会在两个存活区之间复制多次，**直到某些对象的存活时间达到一定阈值**，因为根据分带理论假设，存活超过一定时间的对象很可能会继续存活更长时间，因此**这些年老的对象将会被提升到老年代**，提升的时候，**存活的对象不再是复制到另一个存活区，而是迁移到老年代，并在老年代一直驻留，直到变为不可达对象**。
3. 为了确定一个对象是否足够老，GC 模块会跟踪记录每个存活区对象存活的次数，每次分代 GC 完成后，存活对象的年龄就会增长，当年龄超过**提升阈值**（Tenuring Threshold），就会被提升到老年代区域。
   1. 具体的提升阈值由 JVM 动态调整，但也可以用参数 `-XX:+MaxTenuringThreshold` 来指定上限。
   2. 如果设置 `-XX:+MaxTenuringThreshold=0`，则 GC 时存活对象不在存活区之间复制，直接提升到老年代。
   3. 现代 JVM 中，这个阈值默认设置为 15 个 GC 周期，这也是 HotSpot JVM 中允许的最大值。
   4. 如果存活区空间不够存放年轻代中的存活对象，提升也可能更早的进行。

![c5e75250-322d-11ea-b6b0-159b6a0308ab (1652×784)](https://notebook.ricear.com/media/202105//1621914622.9213243.png)

#### 3.1.2 老年代

1. 老年代的 GC 实现要复杂的多，其空间通常会更大，GC 发生的频率比年轻代要小很多。
2. 因为预期老年代中的对象大部分是存活的，所以**不再使用标记-复制算法，而是采用移动对象的方式来实现最小化内存碎片**。
3. 老年代空间的清理算法通常是建立在不同基础上的，原则上，会执行以下这些步骤：
   1. 通过标志位，标记所有 GC Roots 可达的对象。
   2. 删除所有不可达的对象。
   3. 整理老年代空间中的内容，方法是**将所有的存活对象复制，从老年代开始的地方依次存放**。

### 3.2 堆外内存（No-Heap Memory）

Non-Heap 的本质还是 Heap，只是一般不归 GC 管理，里面划分为三个内存池：**Metaspace**、****Compressed Class Space****、**Code Cache**。

#### 3.2.1 Metaspace

1. 以前叫**持久代**（Permanent Generation），主要用于存放以下信息：
   
   1. **JVM 中类的元数据在 Java 堆中的存储区域。**
   2. **Java 类对应的 HotSpot 虚拟机中的内部表示也存储在这里。**
   3. **类的层级信息，字段，名字。**
   4. **方法的编译信息及字节码。**
   5. **变量。**
   6. **常量池和符号解析。**
2. 由于很难预测这块区域到底需要占用多少内存空间，预测失败可能会导致内存溢出错误，因此 Java8 直接删除了永久代，改用 Metaspace，同时**将方法区移至 Metaspace**。
3. **Metaspace 并不在虚拟机中，而是使用本地内存**，因此，**默认情况下，元空间的大小仅受本地内存限制**。

## 参考文献

1. [Java8 Non-Heap 中的 metaspace 和 compressed class space 解释](https://blog.csdn.net/jijijijwwi111/article/details/51564271)。
2. [Metaspace 之一：Metaspace 整体介绍（永久代被替换原因、元空间特点、元空间内存查看分析方法）](https://www.cnblogs.com/williamjie/p/9558094.html)。

