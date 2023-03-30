---
sidebar_position: 7
---

## 1 特性

Synchronized 具有[**原子性**](https://ricear.com/project-34/doc-526/#1-%E5%8E%9F%E5%AD%90%E6%80%A7)、[**可见性**](https://ricear.com/project-34/doc-526/#2-%E5%8F%AF%E8%A7%81%E6%80%A7)、[**有序性**](https://ricear.com/project-34/doc-526/#3-%E6%9C%89%E5%BA%8F%E6%80%A7)、[**可重入性**](https://ricear.com/project-34/doc-531/#2-1-1-%E5%8F%AF%E9%87%8D%E5%85%A5%E9%94%81)。

## 2 用法

Synchronized 可以修饰**静态方法**、**成员函数**，同时还可以直接**定义代码块**，但是归根结底他上锁的资源只有两类，一个是**对象**，一个是**类**。

> 关于 `static` 需要注意以下地方：
> 
> 1. `static`**修饰的静态方法**、**静态属性都是归类所有**，同时**该类的所有实例对象都可以访问**。
> 2. **普通成员属性**、**成员方法是归实例化的对象所有**，**必须实例化之后才能访问**，这也是为什么静态方法不能访问非静态属性的原因。

### 2.1 修饰成员函数

> 下面的代码均定义在 `SynchronizedTest` 类中，且该类中的变量定义如下：
> 
> ```java
> private int i = 0;
> private static int j = 0;
> private final SynchronizedTest instance = new SynchronizedTest();
> ```

1. 具体的代码如下：
   
   ```java
   //  对成员函数加锁，必须获得该类的实例对象的锁才能进入同步块
   public synchronized void add1() {
       i++;
   }
   ```
2. 该方法**没有被 `static` 修饰**，也就是说**该方法是归实例化的对象所有**，那么**这个锁就是加给 `SynchronizedTest` 类所实例化的对象**。

### 2.2 修饰静态方法

1. 具体的代码如下：
   
   ```java
   //  对静态方法加锁，必须获得类的锁才能进入同步块
   public static synchronized void add2() {
       j++;
   }
   ```
2. 该方法是**静态方法**，**归 `SynchronizedTest` 类所有**，所以**这个锁是加给 `SynchronizedTest` 类的**。

### 2.3 修饰代码块

1. 具体的代码如下：
   
   ```java
   public void method() {
       synchronized (SynchronizedTest.class) {
           //  同步块，执行前必须获得 SynchronizedTest 类的锁
       }
   
       synchronized (instance) {
           //  同步块，执行前必须先获得实例对象的锁
       }
   }
   ```
2. `method` 方法中的两个同步代码块，**第一个代码块锁定的是 `SynchronizedTest.class`**，**该锁是加给 `SynchronizedTest` 类的**，**第二个代码块锁定的是 `instance`**，这个 `instance`**是 `SynchronizedTest` 类的一个实例化对象**，因此**他所上的锁是给 `insatnce` 实例化对象的**。

## 3 相关概念

### 3.1 Java 对象头

1. 在 JVM 中，对象在内存中的布局分为三块区域，分别是**对象头**、**实例数据**和**对齐填充**，如下图所示：![图片](https://ricear.com/media/202107/2021-07-31_1508100.8334154685442979.png)
   1. **实例数据**：
      1. **存放类的属性数据信息**，**包括父类的属性信息**。
   2. **对齐填充**：
      1. 由于虚拟机要求，**对象起始地址必须是 8 字节的整数倍**，**填充数据不是必须存在的**，**仅仅是为了字节对齐**。
   3. **对象头**：
      1. Java 对象头**一般占用 2 个机器码**（在 32 位虚拟机中，1 个机器码等于 4 字节，也就是 32bit，在 64 位虚拟机中，1 个机器码是 8 个字节，也就是 64bit），但是**如果对象是数组类型**，则**需要三个机器码**，因为**需要一块来记录数组长度**。
      2. Hotspot 虚拟机的对象头主要包括两部分数据，分别是**Mark Word**（标记字段）、**Class Pointer**（类型指针）：
         1. **Mark Word**：
            
            1. Mark Word 主要用于**存储对象自身的运行时数据**，如哈希码（HashCode）、GC 分代年龄、锁状态标志、线程持有的锁、偏向线程 ID、偏向时间戳等，**是实现轻量级锁和偏向锁的关键**。
            2. **对象头信息是与对象自身定义的数据无关的额外存储成本**，但是**考虑到虚拟机的空间效率**，Mark Word**被设计成一个非固定的数据结构**，**以便在极小的空间内存储尽量多的数据**，他**会根据对象的状态复用自己的存储空间**，也就是说，Mark Word**会随着程序的运行发生变化**，可能变化为存储以下四种数据（32 位虚拟机）：![在这里插入图片描述](https://ricear.com/media/202108/2021-08-01_1429370.555284820987625.png)
            3. 对象头的**最后两位存储了锁的标志位**，**01 是初始状态**，**未加锁**，其**对象头里存储的是对象本身的哈希码**，随着锁级别的不同，对象头里会存储不同的内容：
               
               1. 偏向锁存储的是当前占用此对象的线程 ID。
               2. 轻量级锁存储的是指向线程栈中锁记录的指针。
            4. 从这里我们可以看到：
               
               1. **锁可能是个锁记录 + 对象头里的引用指针**（判断线程是否拥有锁时**将线程的锁记录地址和对象头里的指针地址比较**）。
               2. **锁也可能是对象里头的线程 ID**（判断线程是否拥有锁时**将线程的 ID 和对象里存储的线程 ID 比较**）。
               
               ![](https://ricear.com/media/202107/2021-07-31_1540400.9407862051207854.png)
            5. 锁也分为不同的状态，**JDK 1.6 之前只有两个状态**，分别是**无锁**、**有锁**（重量级锁），在 JDK 1.6 之后，对 Synchronized 进行了优化，**新增了两种状态**，**总共就是四个状态**，分别是**无锁**、**偏向锁**、**轻量级锁**、**重量级锁**，**锁的类型和状态在对象头 Mark Word 中都有记录**，**在申请锁**、**锁升级等过程中 JVM 都需要读取对象的 Mark Word 数据**。
         2. **Class Pointer**：
            
            1. Class Pointer**是对象指向他的类元数据的指针**，**虚拟机通过这个指针来确定这个对象是哪个类的实例**。

### 3.2 对象头中的 Mark Word 与线程中的 Lock Record

1. 在**线程进入同步代码块的时候**，如果此**同步对象没有被锁定**，即**他的所标志位是 01**，则**虚拟机首先在当前线程的栈中创建我们称之为锁记录**（Lock Record）**的空间**，**用于存储锁对象的 Mark Word 拷贝**。
2. **Lock Record 是线程私有的数据结构**，**每一个线程都有一个可用 Lock Record 列表**，**同时还有一个全局列表**，**每一个被锁住的对象 Mark Word 都会和一个 Lock Record 关联**（对象头的 Mark Word 中的 Lock Word 指向 Lock Record 的起始地址），**同时 Lock Record 中有一个 `Owner` 字段存放拥有该锁的唯一标识**，**表示该锁被这个线程占用**。
3. Lock Record 主要包括以下字段：
   1. **Owner**：**初始时为 `null`**，**表示当前没有任何线程拥有该 Lock Record**，**当线程成功拥有该锁后保存线程唯一标识**，**当锁被释放时又设置为 `null`**。
   2. **EntryQ**：**关联一个系统互斥锁**（`Semaphore`），**阻塞所有试图锁住该 Lock Record 失败的线程**。
   3. **RcThis**：**表示 `blocked` 或 `waiting` 在该 Lock Record 上的所有线程的个数**。
   4. **Nest**：**用来实现重入锁的计数**。
   5. **HashCode**：**保存从对象头拷贝过来的 HashCode 值**。
   6. **Candidate**：**用来避免不必要的阻塞或等待线程唤醒**，**因为每一次只有一个线程能够成功拥有锁**，**如果每次前一个释放锁的线程唤醒所有正在阻塞或等待的线程**，**会引起不必要的上下文切换**（从阻塞到就绪，然后因为竞争锁失败又被阻塞），**从而导致性能严重下降**，Candidate**只有两种可能的值**，**0 表示没有需要唤醒的线程**，**1 表示要唤醒一个继任线程来竞争锁**。

### 3.3 Monitor

1. Monitor**是一个同步工具**，**每个对象都有一个 Monitor 与之关联**，**当一个 Monitor 被持有后**，**他将处于锁定状态**。
2. Synchronized 在 JVM 里的实现都是**基于进入和退出 Monitor 对象来实现方法同步和代码块同步**，虽然具体实现细节不一样，但是都可以通过成对的 MonitorEnter 和 MonitorExit 指令来实现：
   
   1. **MonitorEnter**：**插入在同步代码块的开始位置**，**当代码执行到该指令时**，**将会尝试获取该对象 Monitor 的所有权**，**即尝试获得该对象的锁**。
   2. **MonitorExit**：**插入在方法结束处和异常处**，**JVM 保证每个 MonitorEnter 必须有对应的 MonitorExit**。
3. 在 Java 虚拟机（HotSpot）中，Monitor 是由[ObjectMonitor](https://ricear.com/media/attachment/2021/07/jdk8u-hotspot.zip)（`src/share/vm/runtime/objectMonitor.hpp`）实现，其主要数据结构如下：
   
   ```c++
   ObjectMonitor() {
     _header       = NULL;
     _count        = 0;  //  记录个数
     _waiters      = 0,
     _recursions   = 0;
     _object       = NULL;
     _owner        = NULL;
     _WaitSet      = NULL;   //  处于 wait 状态的线程，会被加入到 _WaitSet
     _WaitSetLock  = 0 ;
     _Responsible  = NULL ;
     _succ         = NULL ;
     _cxq          = NULL ;
     FreeNext      = NULL ;
     _EntryList    = NULL ;  //  处于等待锁 block 状态的线程，会被加入到 _EntryList
     _SpinFreq     = 0 ;
     _SpinClock    = 0 ;
     OwnerIsThread = 0 ;
     _previous_owner_tid = 0;
   }
   ```
   
   1. ObjectMonitor 中有两个队列，分别是 `_WaitSet` 和 `_EntryList`，用来**保存 ObjectWaiter 对象列表**（每个等待锁的线程都会被封装成 ObjectWaiter 对象），`_owner`**指向持有 ObjectMonitor 的线程**，当**多个线程同时访问同一段代码**时：
      1. **首先会进入 `_EntryList` 列表**，当**线程获取到对象的 Monitor 后**，**进入 `_owner` 区域并把 `_owner` 变量设置为当前线程**，同时**Monitor 中的计数器 `_count` 加 1**。
      2. **若线程调用 `wait()` 方法**，**将释放当前持有的 Monitor**，`_owner`**变量恢复为 `null`**，`_count`**减 1**，同时**该线程进入 `_WaitSet` 集合中等待被唤醒**。
      3. **若当前线程执行完毕**，**也将释放当前持有的 Monitor**，并**复位 `_count` 的值**，**以便其他线程进入获取 Monitor**。
         
         > **因为 `wait()`**、`notify()`**需要借助 Monitor 对象来实现**，**所以必须要在同步方法或同步代码块中使用**。
         
         ![在这里插入图片描述](https://ricear.com/media/202108/2021-08-01_1429370.19590741152196445.png)
   2. 一个更形象的描述如下：![](https://ricear.com/media/202108/2021-08-01_0931150.3235706871602445.png)
      1. 一个线程**通过 1 号门进入 Entry Set**（入口区）：
         1. 如果**入口区没有线程等待**，那么这个线程就会**获取监视器成为监视器的 `Owner`**，然后**执行监视区域的代码**。
         2. 如果在**入口区中有其他线程等待**，那么**新来的线程也会和这些线程一起等待**。
      2. **线程在持有监视器的过程中有两个选择**：
         1. 一个是**正常执行监视区域的代码**，**释放监视器**，**通过 5 号门退出监视器**。
         2. 还有可能**等待某个条件的出现**，于是他会**通过 3 号门到 Wait Set**（等待区）**休息**，**直到相应的条件满足后再通过 4 号门进入**，**重新获得监视器再执行**。
            
            > 需要注意的是：
            > 
            > 1. 当**一个线程释放监视器时**，**在入口区和等待区的等待线程都会去竞争监视器**：
            >    1. 如果入口区的线程赢了，会从 2 号门进入。
            >    2. 如果等待区的线程赢了，会从 4 号门进入。
            > 2. **只有通过 3 号门才能进入等待区**，**在等待区中的线程只有通过 4 号门才能退出等待区**，也就是说，**一个线程只有在持有监视器时才能执行 `wait` 操作**，**处于等待的线程只有再次获得监视器才能退出等待状态**。

## 4 实现原理

1. Java 虚拟机是**通过进入和退出 Monitor 对象来实现代码块同步和方法同步**的：
   1. **代码块同步使用的是 `monitorenter` 和 `monitorexit` 指令实现的**。
   2. **方法同步是通过 `Access flags` 后面的 `ACC_SYNCHRONIZED` 标志来隐式实现的**。
2. 这两种同步方式在**本质上没有区别**，只是**方法的同步是一种隐式的方式来实现的**，**无需通过字节码来完成**，**两个指令的执行是 JVM 通过调用操作系统的互斥原语 `mutex` 来实现**，**被阻塞的线程会被挂起**，**等待重新调度**，**会导致用户态和和心态两个态之间来回切换**，**对性能有较大影响**。

### 4.1 同步代码块

1. 当**一个线程访问同步代码块**时，首先是**需要得到锁才能执行同步代码**，**当退出或者抛出异常时必须要释放锁**，具体的实现如下：
   1. 首先，我们定义一个同步代码块：
      
      ```java
      public class SynchronizedTest3 {
          public void method() {
              synchronized (this) {
                  //  同步块，执行前必须获得 SynchronizedTest 类的锁
              }
          }
      }
      ```
   2. 然后对该方法进行反编译（`javac SynchronizedTest3.java`），接着查看对应的字节码（`javap -v -c -s -l SynchronizedTest3`）：
      
      ![](https://ricear.com/media/202107/2021-07-31_145630.png)
   3. 从上述字节码中可以看到**同步代码块的实现是由 `monitorenter` 和 `monitorexit` 指令完成的**：
      
      1. **`monitorenter`**：
         1. **每个对象都是一个监视器锁**，当 Monitor**被占用时就会处于锁定状态**，**线程执行 `monitorenter` 指令时尝试获取 `monitor` 的所有权**，过程如下：
            1. 如果 `monitor` 的进入数为 0，则**该线程进入 `monitor`**，然后**将进入数设置为 1**，**该线程即为 `monitor` 的所有者**。
            2. 如果**该线程已经占有该 `monitor`**，只是**重新进入**，则**进入 `monitor` 的进入数加 1**。
            3. 如果**其他线程已经占用了 `monitor`**，则**该线程进入阻塞状态**，直到**`monitor` 的进入数为 0**，再**重新尝试获取 `monitor` 的所有权**。
      2. **`monitorexit`**：
         1. **执行 `monitorexit` 的线程必须是对应的 `monitor` 的持有者**。
         2. **指令执行时**，**`monitor` 的进入数减 1**，如果**减 1 后进入数为 0**，则**线程退出 `monitor`**，**不再是这个 `monitor` 的持有者**，**其他被这个 `monitor` 阻塞的线程可以尝试去获取这个 `monitor` 的所有权**。
         3. **`monitorexit` 指令出现了两次**，**第一次为同步正常退出释放锁**，**第二次为发生异常退出释放锁**。

### 4.2 同步方法

1. 首先看方法上锁，我们新**定义一个同步方法**：
   
   ```java
   public class SynchronizedTest2 {
       private int i = 0;
   
       public synchronized void add1() {
           i++;
       }
   }
   ```
2. 对该方法进行**反编译**（`javac java_file`），然后**查看其字节码**（`javap -v -c -s -l class_file`）：
   
   ![](https://ricear.com/media/202107/2021-07-31_143453.png)
3. 从反编译的结果来看，**方法的同步并没有通过指令 `monitorenter` 和 `monitorexit` 来完成**，不过**相对于普通方法**，其**常量池中多了 `ACC_SYNCHRONIZED` 标识符**，**JVM 就是根据该标识符来实现方法的同步的**：
   
   1. 当**方法调用时**，**调用指令将会检查方法的 `ACC_SYNCHRONIZED` 访问标志是否被设置**，**如果设置了**，**执行线程将先获取 `monitor`**，**获取成功之后才能执行方法体**，**方法执行完后再释放 `monitor`**，在**方法执行期间**，**其他任何线程都无法再获得同一个 `monitor` 对象**。

## 5 JVM 对 Synchronized 的优化

### 5.1 为什么要进行优化

1. **JVM 是通过进入和退出 Monitor 对象来实现代码块同步和方法同步的**，而**Monitor 是依靠底层操作系统的 Mutex Lock 来实现**的，**操作系统实现线程之间的切换需要[从用户态转换到核心态](https://ricear.com/project-26/doc-336)**，**这个切换成本比较高**，**对性能影响较大**。

### 5.2 做了哪些优化

1. 从**JDK 1.5 引入了**现代操作系统新增加的**[CAS](https://ricear.com/project-34/doc-529)原子操作**。
2. 从**JDK 1.6**开始，就**对 Synchronized 的实现机制进行了较大调整**，**增加了自适应自旋锁**、**锁消除**、**锁粗化**、**偏向锁**、**轻量级锁这些优化策略**，以此来**减少锁的开销**。
3. 此时**锁主要有四种状态**，依次是**无锁状态**、**偏向锁状态**、**轻量级锁状态**、**重量级锁状态**，**锁可以从偏向锁升级到轻量级锁**，**再升级到重量级锁**，但是**锁的升级是单向的**，**只能从低到高升级**，**不会出现锁的降级**。

#### 5.2.1 自旋锁

自旋锁的相关内容详见[5.1.1 自旋锁](https://ricear.com/project-34/doc-531/#5-1-1-%E8%87%AA%E6%97%8B%E9%94%81)。

#### 5.2.2 适应性自旋锁

适应性自旋锁的相关内容详见[5.1.2 适应性自旋锁](https://ricear.com/project-34/doc-531/#5-1-2-%E9%80%82%E5%BA%94%E6%80%A7%E8%87%AA%E6%97%8B%E9%94%81)。

#### 5.2.3 锁消除

1. **锁消除是 Java 虚拟机在 JIT 编译期间**，**通过对运行上下文的扫描**，**去除不可能存在共享资源竞争的锁**，通过锁消除，可以**减少毫无意义的请求锁的时间**。
2. 比如下面代码的 `method1` 和 `method2` 的执行效率是一样的，因为 `object` 锁是私有变量，不存在锁竞争关系：
   
   ```java
   public class SynchronizedTest4 {
       public void method1() {
           Object object = new Object();
           synchronized (object) {
               //  执行同步代码
               System.out.println("Hello World.");
           }
       }
   
       //  优化后的方法，和上面 method1 的执行效率一样
       public void method2() {
           Object object = new Object();
           System.out.println("Hello World.");
       }
   }
   ```

#### 5.2.4 锁粗化

1. **锁粗化是指将多个连续的加锁**、**解锁操作连接在一起**，**扩展成一个范围更大的锁**。
2. 比如下面的 `method3` 经过锁粗化优化之后就和 `method4` 执行效率一样了：
   
   ```java
   public void method3() {
       for (int i = 0; i < 10000; i++) {
           synchronized (this) {
               System.out.println("Hello World.");
           }
       }
   }
   
   //  锁粗化，和上面一样
   public void method5() {
       synchronized (this) {
           for (int i = 0; i < 10000; i++) {
               System.out.println("Hello World.");
           }
       }
   }
   ```

#### 5.2.5 偏向锁

偏向锁的相关内容详见[6.2.2 偏向锁](https://ricear.com/project-34/doc-531/#6-2-2-%E5%81%8F%E5%90%91%E9%94%81)。

#### 5.2.6 轻量级锁

轻量级锁的相关内容详见[6.2.3 轻量级锁](https://ricear.com/project-34/doc-531/#6-2-3-%E8%BD%BB%E9%87%8F%E7%BA%A7%E9%94%81)。

#### 5.2.7 重量级锁

重量级锁的相关内容详见[6.2.4 重量级锁](https://ricear.com/project-34/doc-531/#6-2-4-%E9%87%8D%E9%87%8F%E7%BA%A7%E9%94%81)。

## 6 Synchronized 与 Lock 的区别

1. **实现层面不一样**：
   1. Synchronized 是**Java 关键字**，在**JVM 层面实现加锁和释放锁**。
   2. Lock 是一个**接口**，在**代码层面实现加锁和释放锁**。
2. **是否自动释放锁**：
   1. Synchronized**在线程代码执行完成或出现异常时自动释放锁**。
   2. Lock**不会自动释放锁**，**需要在 `finally{}` 代码块中显式地释放锁**。
3. **是否一致等待**：
   1. Synchronized 会导致**线程拿不到锁一直等待**。
   2. Lock**可以设置尝试获取锁或者获取锁失败一定时间超时**。
4. **获取锁成功是否可知**：
   1. Synchronized**无法得知是否获取锁成功**。
   2. Lock**可以通过 `tryLock` 获得加锁是否成功**。
5. **功能复杂性**：
   1. Synchronized 加锁[可重入](https://ricear.com/project-34/doc-531/#2-1-1-%E5%8F%AF%E9%87%8D%E5%85%A5%E9%94%81)**、**不可中断**、**[非公平](https://ricear.com/project-34/doc-531/#1-1-2-%E9%9D%9E%E5%85%AC%E5%B9%B3%E9%94%81)。
   2. Lock[可重入](https://ricear.com/project-34/doc-531/#2-1-1-%E5%8F%AF%E9%87%8D%E5%85%A5%E9%94%81)、**可中断**、[可公平](https://ricear.com/project-34/doc-531/#1-1-1-%E5%85%AC%E5%B9%B3%E9%94%81)和[非公平](https://ricear.com/project-34/doc-531/#1-1-2-%E9%9D%9E%E5%85%AC%E5%B9%B3%E9%94%81)，细分[读写锁](https://ricear.com/project-34/doc-531/#4-%E7%8B%AC%E5%8D%A0%E9%94%81%E4%B8%8E%E5%85%B1%E4%BA%AB%E9%94%81)**提高效率**。

## 参考文献

1. [深入分析 Synchronized 原理(阿里面试题)](https://www.cnblogs.com/aspirant/p/11470858.html)。
2. [面试官：请详细说下 synchronized 的实现原理](https://www.nowcoder.com/discuss/668295?channel=-1&source_id=discuss_terminal_discuss_sim_nctrack&ncTraceId=5b8e4b844d334f84b3c3295450624f14.347.16233839156167936)。
3. [深入 Synchronized 底层实现原理【架构师之巅】](https://mp.weixin.qq.com/s?src=11×tamp=1627697648&ver=3223&signature=OPMy-jQGHnffKcqn-pPgsfKWQ1dLwtQ48qHiJglU8y0yDRwaRipWQbGkO0JHUoxtCWuwbtWsiVzPA1yRAz9DZHaw0osn*JBnEZswaBVqPD48UJ4DBrX1D-YvNpiBNezY&new=1)。
4. [深入理解 synchronized 底层原理，一篇文章就够了【北风 IT 之路】](https://mp.weixin.qq.com/s?src=11×tamp=1627697648&ver=3223&signature=RsvgqPsAq-JU6tO3xoOK9LzLQPiTnbNX*C-jFFLTzapqjk-m31sssQJ7Ibg*qJdm3oQuTJKk3t0I7GQjxytzCa2QNEihcwiy9wcjq38Fbkrn0cBeYkSK1agLMxkd4Byw&new=1)。
5. [Java 并发基石——所谓“阻塞”：Object Monitor 和 AQS（1）](https://blog.csdn.net/yinwenjie/article/details/84922958)。
6. [10 行代码理解 Java 锁消除](https://zhuanlan.zhihu.com/p/60532356)。
7. [synchronized 和 Lock 有什么区别？](https://www.javanav.com/interview/39b30d412c764d4bbad93a6f8d591ad1.html)

