---
sidebar_position: 3
---

## 1 定义

1. `Volatile` 可以保证线程的**可见性**、**有序性**，但是**无法保证线程的原子性。**
2. 加入 `Volatile` 关键字时，**会多出一个 `lock` 前缀指令**，该指令实际相当于一个**内存屏障**，他会提供 3 个功能：
   1. 确保指令重排序时**不会把后面的指令排到内存屏障之前的位置，也不会把前面的指令排到内存屏障的后面**，即**在执行到内存屏障这句指令时，在他前面的操作已经全部完成**。
   2. 他会**强制将缓存的修改操作立即写入主内存**。
   3. 如果是**写操作**，他会**导致其他 CPU 中对应的缓存行无效**。

## 2 实现原理

### 2.1 可见性

1. 如果**对声明了 `Volatile` 变量进行写操作**时，**`JVM` 会向处理器发送一条 `Lock` 前缀指令，将这个变量所在的缓存行的数据写回到系统内存**，这一步**确保了如果有其他线程对声明了 `Volatile` 变量进行修改时，则立即更新主内存中的数据**。
2. 但这时候其他处理器的缓存还是旧的，所以在多处理器环境下，**为了保证各个处理器缓存一致，每个处理器会通过嗅探在总线上的传播的数据来检查自己的缓存是否过期，当处理器发现自己缓存行对应的内存地址被修改了，就会将当前处理器的缓存行设置成无效状态，当处理器要对这个数据进行修改操作时，会强制重新从系统内存把数据读到处理器缓存里**，这一步**确保了其他线程获得的声明了 `Volatile` 变量都是从主内存中获取最新的**。

### 2.2 有序性

1. `Lock` 前缀指令实际上相当于一个**内存屏障**，它**确保指令重排序时不会把其后面的指令排到内存屏障之前的位置，也不会把前面的指令排到内存屏障的后面**，即**在执行到内存屏障这句指令时，在他前面的操作已经全部完成**。

## 3 示例

### 3.1 保证可见性

先看一段代码，假如线程 1 先执行，线程 2 后执行：

```java
//线程 1
boolean stop = false;
while(!stop){
    doSomething();
}

//线程 2
stop = true;
```

1. 上述代码的运行不一定完全正确，线程 1 不一定会中断：
   1. 线程 1 在运行的时候，会将 `stop` 变量的值拷贝一份放在自己的**工作内存**当中。
   2. 当线程 2 更改了 `stop` 变量的值之后，但是还没来得及写入**主内存**中，线程 2 转去做其他事情了。
   3. 那么线程 1 由于不知道线程 2 对 `stop` 变量的更改，因此还会一直循环下去。
2. 但是用 `Volatile` 修饰之后就变得不一样了：
   1. 使用 `Volatile` 关键字会**强制将修改的值立即写入主内存**。
   2. 使用 `Volatile` 关键字时的话，**当线程 2 修改 `stop` 变量的值时，会导致线程 1 的工作内存中缓存变量 `stop` 的缓存行无效**。
   3. 由于**线程 1 的工作内存中缓存变量 `stop` 的缓存行无**效，所以**线程 1 再次读取变量 `stop` 的值时会去主内存读取**。

### 3.2 不能保证原子性

```java
package top.ricear.juc.myvolatile;

/**
 * @author peng.wei
 * @version 1.0
 * @date 2021/4/20 14:28
 * @Description Volatile 不能保证原子性测试
 */
public class VolatileAtomTest {
    public volatile int inc = 0;

    public void increase() {
        inc++;
    }

    public static void main(String[] args) {
        final VolatileAtomTest test = new VolatileAtomTest();
        for(int i=0;i<10;i++){
            new Thread(){
                @Override
                public void run() {
                    for(int j=0;j<1000;j++) {
                        test.increase();
                    }
                };
            }.start();
        }

        //  保证前面的线程都执行完
        while(Thread.activeCount()>1) {
            Thread.yield();
        }
        System.out.println(test.inc);
    }
}
```

输出结果：

```txt
9810
```

1. 虽然 `Volatile` 关键子能保证可见性，但可见性只能保证**每次读取的是最新值**，`Volatile` 没法保证对**变量的操作的原子性**。
2. **自增操作不具备原子性**，它包括读取变量的原始值、进行加 1 操作、写入工作内存三步，因此**自增操作的三个子操作可能会分割开执行**，就有可能导致下面这种情况出现：
   1. 假如某个时刻 `inc` 的值为 10，线程 1 对变量进行自增操作，**线程 1 先读取了变量 `inc` 的原始值，然后线程 1 被阻塞了**。
   2. 然后线程 2 对变量进行自增操作，也去读取变量 `inc` 的原始值，**由于线程 1 只是对变量 `inc` 进行读取操作，而没有对变量进行修改操作，所以不会导致线程 2 的工作内存中缓存变量 `inc` 的缓存行无效，所以线程 2 会直接去主内存中读取 `inc` 的值，发现 `inc` 的值是 10，然后进行加 1 操作，并把 11 写入工作内存，最后写入主内存**。
   3. 然后线程 1 接着进行加 1 操作，**由于已经读取了 `inc` 的值，注意此时在线程 1 的工作内存中 `inc` 的值仍然为 10，所以线程 1 对 `inc` 进行加 1 操作后 `inc` 的值为 11，然后将 11 写入工作内存，最后写入主内存**。

把上面的代码改成以下任何一种都可以达到原子性效果。

#### 3.2.1 采用 Synchronized

```java
package top.ricear.juc.myvolatile;

/**
 * @author peng.wei
 * @version 1.0
 * @date 2021/4/20 15:10
 * @Description Synchronized 原子性测试
 */
public class SynchronizedAtomTest {
    public int inc = 0;

    public synchronized void increase() {
        inc++;
    }

    public static void main(String[] args) {
        final SynchronizedAtomTest test = new SynchronizedAtomTest();
        for(int i=0;i<10;i++){
            new Thread(){
                @Override
                public void run() {
                    for(int j=0;j<1000;j++) {
                        test.increase();
                    }
                };
            }.start();
        }

        //  保证前面的线程都执行完
        while(Thread.activeCount()>1) {
            Thread.yield();
        }
        System.out.println(test.inc);
    }
}
```

#### 3.2.2 采用 Lock

```java
package top.ricear.juc.myvolatile;

import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * @author peng.wei
 * @version 1.0
 * @date 2021/4/20 15:10
 * @Description Lock 原子性测试
 */
public class LockAtomTest {
    public int inc = 0;
    Lock lock = new ReentrantLock();

    public void increase() {
        lock.lock();
        try {
            inc++;
        } finally {
            lock.unlock();
        }
    }

    public static void main(String[] args) {
        final LockAtomTest test = new LockAtomTest();
        for (int i = 0; i < 10; i++) {
            new Thread() {
                @Override
                public void run() {
                    for (int j = 0; j < 1000; j++) {
                        test.increase();
                    }
                }

                ;
            }.start();
        }

        //  保证前面的线程都执行完
        while (Thread.activeCount() > 1) {
            Thread.yield();
        }
        System.out.println(test.inc);
    }
}
```

#### 3.2.3 采用 AtomInteger

```java
package top.ricear.juc.myvolatile;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

/**
 * @author peng.wei
 * @version 1.0
 * @date 2021/4/20 15:10
 * @Description AtomInteger 测试
 */
public class AtomIntegerTest {
    public AtomicInteger inc = new AtomicInteger();
    Lock lock = new ReentrantLock();

    public void increase() {
        inc.incrementAndGet();
    }

    public static void main(String[] args) {
        final AtomIntegerTest test = new AtomIntegerTest();
        for (int i = 0; i < 10; i++) {
            new Thread() {
                @Override
                public void run() {
                    for (int j = 0; j < 1000; j++) {
                        test.increase();
                    }
                }

                ;
            }.start();
        }

        //  保证前面的线程都执行完
        while (Thread.activeCount() > 1) {
            Thread.yield();
        }
        System.out.println(test.inc);
    }
}
```

### 3.3 保证有序性

**`Volatile` 关键字能禁止指令重排序，所以 `Volatile` 能在一定程度上保证有序性**，`Volatile` 关键字禁止指令重排序有两层意思：

1. **当程序执行到 `Volatile` 变量的读操作或者写操作时，在其前面的操作的更改肯定全部已经进行，且结果已经对后面的操作可见；在其后面的操作肯定还没有进行。**
2. 再进行**指令优化**时，**不能将 `Volatile` 变量访问的语句放在其后面执行，也不能把 `Volatile` 变量后面的语句放到其前面执行**。

具体的例子如下：

```java
//x、y 为非 volatile 变量
//flag 为 volatile 变量

x = 2;        //语句 1
y = 0;        //语句 2
flag = true;  //语句 3
x = 4;         //语句 4
y = -1;       //语句 5
```

1. 由于 `flag` 变量为 `Volatile` 变量，那么在进行指令重排序的过程中，**不会将语句 3 放到语句 1、语句 2 前面，也不会将语句 3 放到语句 4、语句 5 后面**，但是**语句 1 和语句 2 的顺序、语句 4 和语句 5 的顺序是不作任何保证的**。
2. 并且 `Volatile` 关键字能保证**执行到语句 3 时，语句 1 和语句 2 可能执行完了，且语句 1 和语句 2 的执行结果对语句 3、语句 4、语句 5 是可见的**。

### 3.4 适用场景

#### 3.4.1 使用条件

我们只能在有限的一些情形下使用 `Volatile` 变量代替锁，要使 `Volatile` 变量提供理想的线程安全，必须同时满足下面两个条件：

1. **对变量的写操作不依赖于当前值。**
   
   1. 该条件的限制使 `Volatile` 变量**不能用作线程安全计数器。**
2. **该变量没有包含在具有其他变量的不变式中。**
   
   1. 该条件的限制使 `Volatile` 变量**不能用于约束条件中**，例如下面是一个**非线程安全的数值范围类**，它包含了一个不变式 $\rightarrow$**下界总是小于等于上界**：
      
      ```java
      package top.ricear.juc.myvolatile;
      
      /**
       * @author peng.wei
       * @version 1.0
       * @date 2021/4/20 16:01
       * @Description 非线程安全的数值范围类
       */
      public class NumberRange {
          private int lower, upper;
      
          public int getLower() { return lower; }
          public int getUpper() { return upper; }
      
          public void setLower(int value) {
              if (value > upper) {
                  throw new IllegalArgumentException("...");
              }
              lower = value;
          }
      
          public void setUpper(int value) {
              if (value < lower) {
                  throw new IllegalArgumentException("...");
              }
              upper = value;
          }
      }
      ```
      
      将 `lower` 和 `upper` 字段定义为 `Volatile` 类型不能够充分实现类的线程安全，仍然需要使用 `synchronized` 使 `setLower()` 和 `setUpper()` 操作原子化。
      
      否则，**如果凑巧两个线程在同一时间使用不一致的值执行 `setLower` 和 `setUpper` 的话，就会使范围处于不一致的标志**。例如，如果初始状态是 $(0,5)$，同一时间内，线程 `A` 调用 `setLower(4)` 并且线程 `B` 调用 `setUpper(3)`，显然这两个操作交叉存入的值是不符合条件的，那么这两个线程都会通过用于保护不变式的检查，时的最后的范围是 $(4,3)$，这是一个无效的范围。

#### 3.4.2 适用场景

##### 3.4.2.1 状态标志

也许实现 `Volatile` 变量的规范使用仅仅是使用一个**布尔状态标志**，用于指示发生了一个**重要的一次性事件**，例如**完成初始化**或**请求停机**。

```java
volatile boolean shutdownRequested;
 
...
 
public void shutdown() { 
    shutdownRequested = true; 
}
 
public void doWork() { 
    while (!shutdownRequested) { 
        // do stuff
    }
}
```

1. 线程 1 执行 `doWork()` 的过程中，可能有另外的线程 2 调用了 `shutDown()`，所以 `boolean` 变量必须使 `Volatile`。
2. 而如果使用 `synchronized` 块编写循环要比使用 `Volatile` 状态标志麻烦很多，由于 `Volatile` 简化了编码，并且状态标志并不依赖于程序内任何其他状态，因此此处非常适合使用 `Volatile`。
3. 这种类型的状态标记的一个公共特性是**通常只有一种状态转换**，`shutdownRequested` 标志从 `false` 转换为 `true`，然后程序停止，这种模式可以扩展到来回转换的状态标志，但是**只有在转换周期不被察觉的情况下才能扩展**（从 `false` 到 `true`，再转换到 `false`）。

##### 3.4.2.2 一次性安全发布（One-Time Safe Publication）

```java
public class UnsafeDCLFactory {
  private Singleton instance;

  public Singleton get() {
    if (instance == null) {  // read 1, check 1
      synchronized (this) {
        if (instance == null) { // read 2, check 2
          instance = new Singleton();
        }
      }
    }
    return instance; // read 3
  }
}
```

上面的程序在多线程情况下并不能正常执行：

1. 即使 `check1` 成功执行了，此时 `instance` 可能还没有完全被初始化，这是因为 `Singleton` 的内容仅仅对**构造线程**（Constructing Thread）可见，并不能保证其在其他线程里面也可见，因为其他线程正在和**初始化线程**（Intializer Thread）竞争资源。而且，即使我们得到了一个非空的 `instance`，也不意味着其内部的属性都已经完全实例化，因为在 `JMM` 中，**`Singleton` 的构造函数和其他属性的初始化之间并没有 `happens-before` 关系**。
2. 这样就可能导致某个线程**获得一个未完全初始化的实例**。

可以通过如下方法来改进：

```java
public class SafeDCLFactory {
  private volatile Singleton instance;

  public Singleton get() {
    if (instance == null) {  // check 1
      synchronized(this) {
        if (instance == null) { // check 2
          instance = new Singleton();
        }
      }
    }
    return instance;
  }
}
```

因为当程序执行到 `Volatile` 变量的**读操作或者写操作**时，在其**前面的操作的更改肯定全部已经进行**，且**结果已经对后面的操作可见**，因此可以保证调用 `get()` 的线程将**会得到完全构造的 `instance`。**

##### 3.4.2.3 独立观察（Independent Observation）

1. 安全使用 `Volatile` 的另一种简单模式是**定期发布观察结果供程序内部使用**。
2. 假设有一种环境传感器能够感觉环境温度，一个后台线程可能会每隔几秒读取一次该传感器，并更新当前文档的 `Volatile` 变量，然后其他线程可以读取这个变量，从而随时看到最新的温度值。
3. 使用该模式的另一种应用程序就是**收集程序的统计信息**，下面的程序展示了身份验证机制如何记忆最近一次登录的用户的名字，将反复使用 `lastUser` 引用来发布值，以供程序的其他部分使用。

```java
public class UserManager {
    public volatile String lastUser; //发布的信息
 
    public boolean authenticate(String user, String password) {
        boolean valid = passwordIsValid(user, password);
        if (valid) {
            User u = new User();
            activeUsers.add(u);
            lastUser = user;
        }
        return valid;
    }
}
```

##### 3.4.2.4 Volatile Bean 模式

1. `Volatile Bean` 模式的基本原理是**很多框架为易变数据的持有者（例如 `HttpSession`）提供了容器，但是放入这些容器中的对象必须是线程安全的**。
2. 在 `Volatile Bean` 模式中，**`JavaBean` 的所有数据成员都是 `Volatile` 类型的**，并且 `getter` 和 `setter` 方法必须非常普通，即**不包含约束**。

```java
@ThreadSafe
public class Person {
    private volatile String firstName;
    private volatile String lastName;
    private volatile int age;
 
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public int getAge() { return age; }
 
    public void setFirstName(String firstName) { 
        this.firstName = firstName;
    }
 
    public void setLastName(String lastName) { 
        this.lastName = lastName;
    }
 
    public void setAge(int age) { 
        this.age = age;
    }
}
```

##### 3.4.2.5 开销较低的读-写锁策略

1. 如果**读操作远远超过写操作**，我们可以结合**使用内部锁和 `Volatile` 变量来减少公共代码路径的开销**。
2. 如下显示的是**线程安全**的计数器：
   1. **使用 `synchronized` 确保增量操作是原子的，并使用 `Volatile` 保证当前结果的可见性。**
      1. 使用 `synchronized` 进行**所有变化**的操作，使用 `Volatile` 进行**只读**操作。
      2. `synchronized`**一次只允许一个线程访问值**，`Volatile`**允许多个线程执行读操作**。
   2. 如果更新不频繁的话，该方法可以实现更好的性能，因为**读路径的开销仅涉及 `Volatile` 读操作，这通常要优于一个无竞争的锁获取的开销**。

```java
@ThreadSafe
public class CheesyCounter {
    // Employs the cheap read-write lock trick
    // All mutative operations MUST be done with the 'this' lock held
    @GuardedBy("this") private volatile int value;
 
    //读操作，没有 synchronized，提高性能
    public int getValue() { 
        return value; 
    } 
 
    //写操作，必须 synchronized。因为 x++ 不是原子操作
    public synchronized int increment() {
        return value++;
    }
}
```

## 参考文献

1. [深入分析 Volatile 的实现原理](https://blog.csdn.net/eff666/article/details/67640648)。
2. [【Java 线程】volatile 的适用场景](https://blog.csdn.net/vking_wang/article/details/9982709)。
3. [Safe Publication and Safe Initialization in Java](https://shipilev.net/blog/2014/safe-public-construction)。

