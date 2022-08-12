---
sidebar_position: 9
---

## 1 含义

1. AQS 全称是**AbstractQueuedSynchronizer**，即**抽象对象同步器**。
2. AQS 定义了两种资源共享模式：
   1. **独占式**：
      1. **只能有一个线程占有锁资源**，**其他竞争资源的线程**，**在竞争失败后都会进入到等待队列中**，**等待占有锁资源的线程释放锁**，**然后再重新被唤醒竞争资源**，例如 `ReentrantLock` 实现的就是独占式的锁资源。
   2. **共享式**：
      1. **允许多个线程同时获取锁**，**并发访问共享资源**，`ReentrantWriteLock` 和 `CountDownLatch` 等就是实现的这种模式。
3. AQS 内部维护了一个[volatile](https://notebook.grayson.top/project-34/doc-528)的 `state` 变量和一个 FIFO（先进先出）的队列：
   1. `state`：
      
      1. **代表的是竞争资源的标识**。
      2. AQS 中提供了三种操作 `state` 的方法：
         ```java
         protected final int getState() {
             return state;
         }
         
         protected final void setState(int newState) {
             state = newState;
         }
         
         protected final boolean compareAndSetState(int expect, int update) {
             // See below for intrinsics setup to support this
             return unsafe.compareAndSwapInt(this, stateOffset, expect, update);
         }
         ```
   2. **FIFO 队列**：
      
      1. **代表的是竞争资源失败的线程排队时存放的容器**。
      
      ```java
      /**
       * 竞争资源标识
       */
      private volatile int state;
      
      /**
       * FIFO 队列，代表的是竞争资源失败的线程排队时存放的容器
       */
      static final class Node {}
      ```
4. 因为 `AbstractQueuedSynchronizer`**是一个抽象类**，**采用模板方法的设计模式**，**规定了独占模式和共享模式需要实现的方法**，并且**将一些通用的功能已经进行了实现**，所以**不同模式的使用方式**，**只需要自己定义好实现共享资源的获取与释放即可**，至于**具体线程在等待队列中的维护**（获取资源入队列、唤醒出队列等），**AQS 已经实现好了**，所以根据共享资源的模式一般实现的方法有如下几个：
   1. `boolean isHeldExclusively()`：**是否为独占模式**，**只有使用到了 `Condition` 的**，**才需要去实现他**，例如 `ReentrantLock`。
   2. `boolean tryAcquire(int arg)`：**独占模式**，**尝试获取资源**，**成功返回 `true`**，**失败返回 `false`**。
   3. `boolean tryRelease(int arg)`：**独占模式**，**尝试释放资源**，**成功返回 `true`**，**失败返回 `false`**。
   4. `int tryAcquireShared(int arg)`：**共享模式**，**尝试获取资源**，**负数表示失败**，**0 表示成功**，**但是没有剩余可用资源了**，**整数表示成功**，且**有剩余可用资源**。
   5. `boolean tryReleaseShared(int arg)`：**共享模式**，**尝试释放资源**，**若资源释放后允许唤醒后续等待节点返回 `true`**，**否则返回 `false`**。
      上面的这几个方法在 `AbstractQueuedSynchronizer` 抽象类中都没有被定义为 `abstract`，说明这些方法都是可以按需实现的，共享概念股模式下可以只实现共享模式的方法（例如 `CountDownLatch`），独占模式下可以只实现独占模式的方法（例如 `ReentrantLock`），也支持两种都实现，两种模式都使用（例如 `ReentrantReadWriteLock`）。

## 2 源码分析

我们先简单介绍 AQS 的两种模式的实现类的代表 `ReentrantLock`（独占模式）和 `CountDownLatch`（共享模式），是如何来共享资源的一个过程，然后再详细通过 AQS 的源码来分析整个实现过程：

1. `ReentrantLock`：
   1. 在**初始化的时候 `state = 0`**，**表示资源未被锁定**，**当 $A$ 线程执行 `lock()` 方法时**，**会调用 `tryAcquire()` 方法**，**将 AQS 中队列的模式设置为独占**，**并将独占线程设置为线程 $A$**，以及**将 `state + 1`**。
   2. **这样在线程 $A$ 没有释放锁前**，**其他线程来竞争锁**，**调用 `tryAcquire()` 方法时都会失败**，**然后竞争锁失败的线程就会进入到队列中**。
   3. **当线程 $A$ 调用执行 `unlock()` 方法将 `state = 0` 后**，**其他线程才有机会获取锁**（注意 `ReentrantLock` 是可重入的，同一线程多次获取锁时 `state` 的值会进行累加的，在释放锁的时候也要释放相应的次数才算完全释放了锁）。
2. `CountDownLatch`：
   1. **`CountDownLatch` 会将任务分成 $N$ 个子线程去执行**，`state`**的初始值也是 $N$**（`state` 与子线程数量一致），$N$**个子线程是并行执行的**，**每个子线程执行完成后 `countDown()` 一次**，`state`**会通过[CAS](https://notebook.grayson.top/project-34/doc-529)方式减 1**，**直到所有子线程执行完成后**（`state = 0`），**会通过 `unpark()` 方法唤醒主线程**，**然后主线程就会从 `await()` 方法返回**，**继续后续操作**。

### 2.1 独占模式

#### 2.1.1 Node

1. 在 `AbstractQueuedSynchronizer` 的类里面，有一个静态内部类 `Node`，他代表的是**队列中的每一个节点**，其中 `Node` 节点有如下几个属性：
   
   ```java
   volatile int waitStatus;    /*节点的状态*/
   volatile Node prev; /*当前节点的前一个节点*/
   volatile Node next; /*当前节点的后一个节点*/
   volatile Thread thread; /*当前节点中所包含的线程对象*/
   Node nextWaiter;    /*等待队列中的下一个节点*/
   ```
   
   1. `waitStatus`：
      
      1. 代表的是**节点的状态**，**默认为 0**。
      2. 该变量对应的值有以下几种：
         
         ```java
         static final int CANCELLED =  1;
         static final int SIGNAL    = -1;
         static final int CONDITION = -2;
         static final int PROPAGATE = -3;
         ```
         
         1. `CANCELLED =  1`：
            1. 代表的是**当前节点从同步队列中取消**。
            2. **当 timeout 或被中断**（响应中断的情况下），**会触发变更为此状态**，**进入该状态后的节点将不会再变化**。
         2. `SIGNAL = -1`：
            1. 代表**后继节点处于等待状态**。
            2. **后继节点入队时**，**会将前继节点的状态更新为 SIGNAL**。
         3. `CONDITION = -2`：
            1. **节点在等待队列中**，**节点线程等待在 Condition 上**。
            2. **当其他线程对 Condition 调用了 `signal()` 方法后**，**该节点将会从等待队列中转移到同步队列中**，**加入到对同步状态的获取中**。
         4. `PROPAGATE = -3`：
            1. 表示**在共享模式下**，**前继节点在释放资源后会唤醒后继节点**，**并将这种共享模式传播下去**。
      3. 节点状态中通常**负数值表示节点处于有效的等待状态**，而**正数值代表节点已经被取消了**，源码中有很多地方**通过节点状态的正负来判断队列中的节点是否正常**。
   2. `prev`：
      
      1. 代表的是**当前节点的前一个节点**。
   3. `next`：
      
      1. 代表的是**当前节点的后一个节点**。
   4. `thread`：
      
      1. 代表的是**当前节点中所包含的线程对象**。
   5. `nextWaiter`：
      
      1. 代表的是**等待队列中的下一个节点**。

#### 2.1.2 ReentrantLock

`ReentrantLock`**默认是非公平锁**，就是说，**线程在竞争锁的时候并不是按照先来后到的顺序来获取锁的**，但是 `ReentrantLock` 也是支持公平锁的，在创建的时候传入一个参数值即可，如无特殊说明，下面对 ReentrantLock 加锁和解锁过程的分析是以 `ReentrantLock` 默认情况为基础。

##### 2.1.2.1 加锁过程

1. `ReentrantLock` 并**没有直接继承 AQS 类**，而是**通过内部类来继承 AQS 类**的。
2. 我们在用 `ReentrantLock` 加锁的时候都是调用 `lock()` 方法，在默认非公平锁下，`lock()` 的源码如下：
   
   ```java
   /**
    * Sync object for non-fair locks
    */
   static final class NonfairSync extends Sync {
       private static final long serialVersionUID = 7316153563782823691L;
   
       /**
        * Performs lock.  Try immediate barge, backing up to normal
        * acquire on failure.
        */
       final void lock() {
           if (compareAndSetState(0, 1))
               setExclusiveOwnerThread(Thread.currentThread());
           else
               acquire(1);
       }
   
       protected final boolean tryAcquire(int acquires) {
           return nonfairTryAcquire(acquires);
       }
   }
   ```
3. 通过源码我们可以看到 `lock()` 方法首先是**通过 CAS 的方式抢占锁**，**如果抢占成功**，**则将 `state` 的值设为 1**，**然后将对象独占线程设置为当前线程**：
   
   ```java
   protected final void setExclusiveOwnerThread(Thread thread) {
       exclusiveOwnerThread = thread;
   }
   ```
4. **如果抢占锁失败**，**就会调用 `acquire()` 方法**，**这个 `acquire()` 方法的实现就是在 AQS 类中**，**说明具体抢占锁失败后的逻辑**，**AQS 已经规定好了模板**：
   
   ```java
   public final void acquire(int arg) {
       if (!tryAcquire(arg) &&
           acquireQueued(addWaiter(Node.EXCLUSIVE), arg))
           selfInterrupt();
   }
   ```
5. 上面已经介绍了，独占模式是需要实现 `tryAcquire()` 方法的，这里首先就是通过 `tryAcquire()` 方法抢占锁，如果成功返回 `true`，失败返回 `false`，`tryAcquire()` 方法的具体实现，是在 `ReentrantLock` 里面的，AQS 类中默认是直接抛出异常的，`tryAcquire()` 方法的逻辑如下：
   
   1. 首先**获取 `state` 值**，**如果 `state` 值为 0**，说明**无锁**，那么**通过 CAS 尝试加锁**，**成功后**，**将独占线程设置为当前线程**。
   2. **如果 `state` 值不为 0**，**并且当前的独占线程和当前线程为同一线程**，那么 `state`**重入次数加 1**。
   3. **如果 `state` 值不为 0**，**并且当前线程不是独占线程**，**直接返回 `false`**。
      
      ```java
      /**
       * Performs non-fair tryLock.  tryAcquire is implemented in
       * subclasses, but both need nonfair try for trylock method.
       */
      final boolean nonfairTryAcquire(int acquires) {
          final Thread current = Thread.currentThread();
          //  获取 state 值
          int c = getState();
          if (c == 0) {
              //  如果 state 值为 0，说明无锁，那么通过 CAS 尝试加锁，成功后，将独占线程设置为当前线程
              if (compareAndSetState(0, acquires)) {
                  setExclusiveOwnerThread(current);
                  return true;
              }
          }
          else if (current == getExclusiveOwnerThread()) {
              //  如果是同一个线程再次来获取锁，那么就将 state 的值进行加 1 处理（可重入锁的重入次数）
              int nextc = c + acquires;
              if (nextc < 0) // overflow
                  throw new Error("Maximum lock count exceeded");
              setState(nextc);
              return true;
          }
          //  state 值不为 0，并且当前线程不是独占线程，直接返回 false
          return false;
      }
      ```
6. 我们继续来看 `acquire()` 方法，在**执行完 `tryAcquire()` 方法后**，**如果加锁失败那么就会执行 `addWaiter()` 方法和 `acquireQueued()` 方法**，这两个方法的作用是**将竞争锁失败的线程放入到等待队列中**：
   
   1. `addWaiter()`：
      1. 该方法主要做了三件事：
         1. **将当前线程封装成 `Node`**。
         2. **判断队列中尾部节点是否为空**，**若不为空**，**则将当前线程的 `Node` 节点通过 CAS 插入到尾部**。
         3. **如果尾部节点为空或 CAS 插入失败**，**则通过 `enq()` 方法插入到队列中**。
            
            ```java
            private Node addWaiter(Node mode) {
                //  1. 将当前线程封装成 Node
                Node node = new Node(Thread.currentThread(), mode);
                //  2. 判断队列中尾部节点是否为空，若不为空，则将当前线程的 Node 节点通过 CAS 插入到尾部
                Node pred = tail;
                if (pred != null) {
                    node.prev = pred;
                    if (compareAndSetTail(pred, node)) {
                        pred.next = node;
                        return node;
                    }
                }
                //  3. 如果尾部节点为空或 CAS 插入失败，则通过 enq() 方法插入到队列中
                enq(node);
                return node;
            }
            ```
      2. `enq()` 方法主要就是**通过自旋将数据插入到队列中**：
         1. **当队列为空时**，**将当前节点设置为头结点和尾节点**。
         2. **进入二次循环后**，**将 `node` 添加到尾部**。
            
            ```java
            /**
             * Inserts node into queue, initializing if necessary. See picture above.
             * @param node the node to insert
             * @return node's predecessor
             */
            private Node enq(final Node node) {
                //  看到死循环，就明白是通过自选咯
                for (;;) {
                    //  当 tail 节点为空时，直接将当前节点设置成尾部节点，并插入到队列中，以及设置他为 head 节点
                    Node t = tail;
                    if (t == null) {
                        if (compareAndSetHead(new Node()))
                            tail = head;
                    } else {
                        //  若是因为在 addWaiter() 方法中插入失败或第二次进入循环，那么将当前线程的前级节点指向尾部节点，并通过 CAS 方式将尾部节点指向当前线程的节点
                        node.prev = t;
                        if (compareAndSetTail(t, node)) {
                            t.next = node;
                            return t;
                        }
                    }
                }
            }
            ```
      3. 这样 `addWaiter()` 方法就构造了一个队列，并将当前线程添加到了队列中了。
   2. `acquireQueued()`：
      1. 该方法主要做了以下几件事：
         1. 首先**获取节点的前级节点**。
         2. **如果当前节点的前级节点是 `head`**，那么**就可以去抢占锁了**。
         3. **抢占成功后就将新节点设置为 `head`**，**原来的 `head` 置为空**。
         4. **如果抢占锁失败**，**则根据 `waitStatus` 值决定是否挂起线程**。
         5. 最后，**通过 `cancelAcquire()` 取消获取锁操作**。
            
            ```java
            /**
             * Acquires in exclusive uninterruptible mode for thread already in
             * queue. Used by condition wait methods as well as acquire.
             *
             * @param node the node
             * @param arg the acquire argument
             * @return {@code true} if interrupted while waiting
             */
            final boolean acquireQueued(final Node node, int arg) {
                boolean failed = true;
                try {
                    boolean interrupted = false;
                    for (;;) {
                        //  1. 获取前级节点，如果为 null，则抛出异常
                        final Node p = node.predecessor();
                        if (p == head && tryAcquire(arg)) {
                            //  2. 如果前级节点为 head，并且执行抢占锁成功，则
                            //      1. 将当前节点设置为新的 head 节点。
                            //      2. 将原来的 head 节点指向 null，方便进行垃圾回收
                            setHead(node);
                            p.next = null; // help GC
                            failed = false;
                            return interrupted;
                        }
                        //  3. 如果当前节点不为 head，或者抢占锁失败，就根据节点的状态决定是否需要挂起线程
                        if (shouldParkAfterFailedAcquire(p, node) &&
                            parkAndCheckInterrupt())
                            interrupted = true;
                    }
                } finally {
                    if (failed)
                        //  4. 如果获取锁失败，则取消获取锁操作
                        cancelAcquire(node);
                }
            }
            ```
            
            ```java
            /**
             * Returns previous node, or throws NullPointerException if null.
             * Use when predecessor cannot be null.  The null check could
             * be elided, but is present to help the VM.
             *
             * @return the predecessor of this node
             */
            final Node predecessor() throws NullPointerException {
                Node p = prev;
                if (p == null)
                    throw new NullPointerException();
                else
                    return p;
            }
            ```
      2. 下面看一下 `shouldParkAfterFailedAcquire()` 和 `parkAndCheckInterrupt()` 这两个方法是如何挂起线程的：
         1. `shouldParkAfterFailedAcquire()`：
            1. 首先**获取前级节点的** `waitStatus`。
            2. **如果前级节点的 `waitStatus` 值为 `SIGNAL(-1)`**，**说明当前节点也已经在等待唤醒了**，**直接返回 `true`**。
            3. **如果前级节点的 `waitStatus` 大于 0**，**说明前级节点已经取消了**，**那么会继续向前找**，**直到找到的节点不是取消状态**（`waitStatus > 0`），**然后将其设置为当前节点的前级节点**。
            4. **如果前级节点为 0 或者其他不为-1 的小于 0 的值**，**则将当前节点的前级节点设置为 `SIGNAL(-1)`**。
               
               ```java
               /**
                * Checks and updates status for a node that failed to acquire.
                * Returns true if thread should block. This is the main signal
                * control in all acquire loops.  Requires that pred == node.prev.
                *
                * @param pred node's predecessor holding status
                * @param node the node
                * @return {@code true} if thread should block
                */
               private static boolean shouldParkAfterFailedAcquire(Node pred, Node node) {
                   //  获取前级节点的 waitStatus
                   int ws = pred.waitStatus;
                   if (ws == Node.SIGNAL)
                       //  如果前级节点的 waitStatus 值为 SIGNAL(-1)，说明当前节点也已经在等待唤醒了，直接返回 true
                       return true;
                   if (ws > 0) {
                       //  如果前级节点的 waitStatus 大于 0，说明前级节点已经取消了，那么会继续向前找，直到找到的节点不是取消状态（waitStatus > 0），然后将其设置为当前节点的前级节点
                       do {
                           node.prev = pred = pred.prev;
                       } while (pred.waitStatus > 0);
                       pred.next = node;
                   } else {
                       //  如果前级节点为 0 或者其他不为 -1 的小于 0 的值，则将当前节点的前级节点设置为 SIGNAL(-1)
                       compareAndSetWaitStatus(pred, ws, Node.SIGNAL);
                   }
                   return false;
               }
               ```
         2. `parkAndCheckInterrupt()`：
            1. 该方法的作用就是**挂起线程**。
            2. **如果 `shouldParkAfterFailedAcquire()` 方法执行成功**，**会执行 `parkAndCheckInterrupt()` 方法**，**他通过 `LockSupport.park()` 方法**，**将当前线程挂起**（`WAITING`），**然后需要 `LockSupport.unpark()` 方法唤醒他**，**通过这样一种 FIFO 机制的等待**，**来实现 `Lock` 操作**。
               
               ```java
               /**
                * Convenience method to park and then check if interrupted
                *
                * @return {@code true} if interrupted
                */
               private final boolean parkAndCheckInterrupt() {
                   LockSupport.park(this);
                   return Thread.interrupted();
               }
               ```
            3. `LockSupport` 是 JDK 从 1.6 开始提供的一个线程同步源语工具类，在这里主要用到了他的两个方法，分别是**挂起线程**和**唤醒线程**：
               
               ```java
               public static void park(Object blocker) {
                   Thread t = Thread.currentThread();
                   setBlocker(t, blocker);
                   UNSAFE.park(false, 0L);
                   setBlocker(t, null);
               }
               ```
               
               ```java
               public static void unpark(Thread thread) {
                   if (thread != null)
                       UNSAFE.unpark(thread);
               }
               ```
            4. `LockSupport` 的**挂起和唤醒线程都是不可重入的**，他**有一个许可标志**，当**调用 `park()` 时**，**会将许可设置为 0**，**挂起线程**，如果**再调用一次 `park()`**，**会阻塞线程**，当**调用 `unpark()` 时才会将许可标志设置成 1**。

##### 2.1.2.2 释放锁过程

1. `ReentrantLock` 释放锁的过程主要有两个阶段：
   
   1. **释放锁**。
   2. **唤醒挂起的线程**。
2. `unlock()` 方法的源码如下：
   
   ```java
   public void unlock() {
       sync.release(1);
   }
   ```
3. 释放锁的方法是写在父类 `AbstractQueuedSynchronizer` 中的，主要包括如下过程：
   
   1. **尝试释放资源**：
      1. **释放成功后**，**判断头结点的状态是否为无锁状态，如果不为无锁状态，就将头结点中的线程唤醒**。
      2. **释放资源失败，直接返回 `false`**。
         
         ```java
         public final boolean release(int arg) {
             //  尝试释放资源
             if (tryRelease(arg)) {
                 Node h = head;
                 //  释放成功后，判断头结点的状态是否为无锁状态，如果不为无锁状态，就将头结点中的线程唤醒
                 if (h != null && h.waitStatus != 0)
                     unparkSuccessor(h);
                 return true;
             }
             //  释放资源失败，直接返回 false
             return false;
         }
         ```
4. 释放资源的过程如下：
   
   1. **从 `state` 中减去传入参数的相应值**（一般为 1）。
   2. **判断释放资源的线程与独占锁现有线程是否一致**，**如果不一致**，**则为非法线程释放**，**直接抛出异常**。
   3. **因为可重入机制**，**所以每次重入 `state` 值都加 1**，**所以在释放的时候也要相应的减 1**，**直到 `state` 的值为 0 才算完全的释放锁资源**，**完全释放锁资源后**，**将独占线程设置为 `null`**，**这样后面的竞争线程才有可能抢占**。
   4. **最后对 `state` 重新赋值**。
      
      ```java
      protected final boolean tryRelease(int releases) {
          //  从 state 中减去传入参数的相应值（一般为 1）
          int c = getState() - releases;
          if (Thread.currentThread() != getExclusiveOwnerThread())
              //  当释放资源的线程与独占锁现有线程不一致时，为非法线程释放，直接抛出异常
              throw new IllegalMonitorStateException();
          boolean free = false;
          //  这里是处理重入锁的机制，因为可重入机制，所以每次重入 state 值都加 1
          //  所以在释放的时候也要相应的减 1，直到 state 的值为 0 才算完全的释放锁资源
          if (c == 0) {
              free = true;
              //  完全释放资源后，将独占线程设置为 null，这样后面的竞争线程才有可能抢占
              setExclusiveOwnerThread(null);
          }
          //  重新赋值 state
          setState(c);
          return free;
      }
      ```
5. 释放了资源后，我们再看唤醒挂起线程时的过程，这个过程就在 `unparkSuccessor()` 方法中，主要过程如下：
   
   1. 首先**获取当前节点的等待状态**，**一般是头结点**，**占有锁的节点是在头结点上**，**如果该节点没有处于取消状态**，那么**将当前节点的线程的状态值设为 0**，**成为无锁状态**。
   2. 然后**获取下一个需要唤醒的节点线程**，**如果获取到的节点线程为空或已经取消**，**就从队列的后面向前找**，**直到找到一个未取消的节点**。
      
      > 在寻找可以唤醒的节点时，为什么要从后向前找？
      > 线程唤醒的时候，通常是从当前线程的下个节点线程开始寻找，但是下个节点有可能已经取消了或者为 `null` 了，所以从后想起按找，直到找到一个非取消状态的节点线程。
   3. 最后**如果我们获得的下一个可以唤醒的节点线程不为空**，**那么就唤醒他**。
      
      ```java
      /**
       * Wakes up node's successor, if one exists.
       *
       * @param node the node
       */
      private void unparkSuccessor(Node node) {
          //  获取当前节点的等待状态，一般是头结点，占有锁的节点是在头结点上
          int ws = node.waitStatus;
          if (ws < 0)
              //  将当前节点的线程的状态值设为 0，成为无锁状态
              compareAndSetWaitStatus(node, ws, 0);
      
          //  获取下一个需要唤醒的节点线程
          Node s = node.next;
          if (s == null || s.waitStatus > 0) {
              //  如果获取到的节点线程为空或已经取消，就从队列的后面向前找，直到找到一个未取消的节点
              s = null;
              for (Node t = tail; t != null && t != node; t = t.prev)
                  if (t.waitStatus <= 0)
                      s = t;
          }
          if (s != null)
              //  如果获得的下一个可以唤醒的节点线程不为空，那么就唤醒他
              LockSupport.unpark(s.thread);
      }
      ```

### 2.2 共享模式

#### 2.2.1 CountDownLatch

##### 2.2.1.1 获取资源

1. 在使用 `CountDownLatch` 时，是**先创建 `CountDownLatch` 对象**，**然后在每次执行完一个任务后**，**就执行一次 `countDown()` 方法**，**直到通过 `getCount()` 获取到的值为 0 时才算执行完**，**如果 `count` 值不为 0**，**可通过 `await()` 方法让主线程进行等待**，**直到所有任务都执行完成**，`count`**的值被设为 0**。
2. 我们先来看创建 `CountDownLatch` 的方法：
   
   ```java
   public CountDownLatch(int count) {
       if (count < 0) throw new IllegalArgumentException("count < 0");
       this.sync = new Sync(count);
   }
   ```
   
   ```
   Sync(int count) {
       setState(count);
   }
   ```
   
   我们看到创建 `CountDownLatch` 的过程，其实就是**将** `count` **值赋值给** `state` **的过程**。
3. 再来看 `await()` 方法的源码：
   
   ```java
   public void await() throws InterruptedException {
       //  可中断的获取共享资源的方法
       sync.acquireSharedInterruptibly(1);
   }
   ```
   
   ```java
   public final void acquireSharedInterruptibly(int arg)
           throws InterruptedException {
       if (Thread.interrupted())
           //  如果线程已经中断，直接抛出异常结束
           throw new InterruptedException();
       if (tryAcquireShared(arg) < 0)
           //  尝试获取共享资源，获取失败后，自旋入队列
           doAcquireSharedInterruptibly(arg);
   }
   ```
   
   整个 `await()` 的等待过程是**先尝试获取共享资源**，**获取成功则执行任务**，**获取失败**，则**调用方法自旋式进入队列**。
4. 最初在介绍 AQS 的时候就说过，**共享模式下是需要自己去实现 `tryAcquireShared()` 方法来获取共享资源的**，那么我们看看 `CountDownLatch` 是如何实现共享资源的：
   
   ```java
   protected int tryAcquireShared(int acquires) {
       return (getState() == 0) ? 1 : -1;
   }
   ```
   
   简单易懂，就一行代码，**直接获取 `state` 值**，**等于 0 就是成功**，**不等于 0 就失败**。
5. 那么获取资源失败后，`doAcquireSharedInterruptibly()` 方法是如何执行的呢，源码如下：
   
   ```java
   private void doAcquireSharedInterruptibly(int arg)
       throws InterruptedException {
       //  addWaiter() 方法已经总结过了，这一步操作的目的就是将当前线程封装成节点加入队尾，并设置成共享模式
       final Node node = addWaiter(Node.SHARED);
       boolean failed = true;
       try {
           for (;;) {
               //  获取前级节点
               final Node p = node.predecessor();
               if (p == head) {
                   //  如果前级节点是头结点，直接尝试获取共享资源
                   int r = tryAcquireShared(arg);
                   if (r >= 0) {
                       //  如果获取共享资源成功，将 head 节点指向自己
                       setHeadAndPropagate(node, r);
                       //  将原 head 节点指向空，方便垃圾回收
                       p.next = null;
                       failed = false;
                       return;
                   }
               }
               //  如果前级节点不是 head 节点，就根据前级节点状态，判断是否需要挂起线程
               if (shouldParkAfterFailedAcquire(p, node) &&
                   parkAndCheckInterrupt())
                   throw new InterruptedException();
           }
       } finally {
           if (failed)
               //  如果执行失败，取消获取共享资源的操作
               cancelAcquire(node);
       }
   }
   ```
   
   这里的方法**和独占模式下 `acquireQueued()` 方法很像**，**只是在设置头结点唤醒新线程的时候有所不同**，在 `setHeadAndPropagate()` 方法里面：
   
   ```java
   private void setHeadAndPropagate(Node node, int propagate) {
       Node h = head; // Record old head for check below
       setHead(node);
       //  如果在唤醒完下一个节点后，资源还有剩余，并且新唤醒的节点不为无效状态，就继续唤醒队列中的后面节点里的线程
       if (propagate > 0 || h == null || h.waitStatus < 0 ||
           (h = head) == null || h.waitStatus < 0) {
           Node s = node.next;
           if (s == null || s.isShared())
               doReleaseShared();
       }
   }
   ```
   
   `setHeadAndPropagate()` 这个方法名称翻译成中文是「**设置头结点并传播**」，其实就是**在获取共享锁资源的时候**，**如果资源除了用于唤醒下一个节点后**，**还有剩余**，**就会用于唤醒后面的节点**，**直到资源被用完**，**充分体现了共享模式的「共享」**。

##### 2.2.1.2 释放资源

1. 我们再来看 `countDown()` 方法是如何释放资源的，源码如下：
   
   ```java
   public void countDown() {
       sync.releaseShared(1);
   }
   ```
2. `CountDownLatch` 中内部类 `Sync` 的 `releaseShared()`**方法**，**是使用的 AQS 的 `releaseShared()` 方法**：
   
   ```java
   public final boolean releaseShared(int arg) {
       if (tryReleaseShared(arg)) {
           //  尝试释放资源，如果释放资源成功，则唤醒节点
           doReleaseShared();
           return true;
       }
       return false;
   }
   ```
3. **尝试释放资源方法 `tryReleaseShared()` 是 AQS 规定需要自己来实现的**，`CountDownLatch` 的实现如下：
   
   ```java
   protected boolean tryReleaseShared(int releases) {
       // Decrement count; signal when transition to zero
       for (;;) {
           int c = getState();
           if (c == 0)
               //  如果 state 为 0，说明已经不需要释放资源了，直接返回 false
               return false;
           int nextc = c-1;
           if (compareAndSetState(c, nextc))
               //  真正的释放资源，是通过 CAS 的方式将 state 的值减 1
               return nextc == 0;
       }
   }
   ```
4. **释放资源成功后**，**就到了唤醒节点的过程了**，**在 `doReleaseShared()` 方法中**：
   
   ```java
   private void doReleaseShared() {
       for (;;) {
           Node h = head;
           if (h != null && h != tail) {   //  当头结点不为空，并且不等于尾节点时，从头开始唤醒
               int ws = h.waitStatus;  //  获取头结点的等待状态
               if (ws == Node.SIGNAL) {    //  如果头结点状态为等待唤醒，那么将头结点的状态设置为无锁状态，若 CAS 设置节点状态失败，就自旋
                   if (!compareAndSetWaitStatus(h, Node.SIGNAL, 0))
                       continue;            // loop to recheck cases
                   unparkSuccessor(h); //  唤醒头结点
               }   //  如果 head 节点的状态已经为无锁状态了，那么将 head 节点状态设置为可以向下传播唤醒的状态（PROPAGATE）
               else if (ws == 0 &&
                        !compareAndSetWaitStatus(h, 0, Node.PROPAGATE))
                   continue;                // loop on failed CAS
           }
           //  若在执行过程中 head 节点发生变化，直接跳出循环
           if (h == head)                   // loop if head changed
               break;
       }
   }
   ```

## 参考文献

1. [你来讲讲 AQS 是什么吧？都是怎么用的？](https://www.cnblogs.com/jimoer/p/13747291.html)

