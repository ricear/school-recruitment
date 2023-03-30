---
sidebar_position: 4
---

## 1 CAS 含义

1. CAS 全称是 Compare and Swap，即比较并交换。
2. 它是一种**无锁原子**算法，同时也是一种**乐观**机制。
3. CAS 映射到操作系统就是一条 CPU 原子指令，实现方式是基于硬件平台的汇编指令，在 Intel 的 CPU 中，使用的是 `cmpxchg` 指令，就是说 CAS 是靠硬件实现的，从而在硬件层面提升效率。
4. CAS 包含 3 个参数 `V`、`E`、`N`：
   
   1. **V：** Value，即要更新的值。
   2. **E：** Expect，即预期值。
   3. **N**：New，即新值。
   
   只有当 `V` 值等于 `E` 值时，才会将 `V` 的值设为 `N`，如果 `V` 值和 `E` 值不同，则说明已经有其他线程完成更新，则当前线程什么都不做，最后 CAS 返回当前 `V` 的真实值。
5. 当多个线程同时使用 CAS 操作一个变量时，最多只会有一个会胜出，并成功更新，其余均会失败。失败的线程不会挂起，仅是被告知失败，并且允许再次尝试（自旋），当然也允许实现的线程放弃操作。基于这样的原理，CAS 操作即使没有锁，也可以避免其他线程对当前线程的干扰。
6. 与锁相比，使用 CAS 会使程序看起来更加复杂一些，但是使用无锁的方式**完全没有锁竞争带来的线程间频繁调度的开销和阻塞**，他**对死锁问题天生免疫**，因此他要比基于锁的方式拥有**更好的性能**。
7. 简单的说，**CAS 需要我们额外给出一个期望值**，也就是我们认为这个变量现在应该是什么样子，**如果变量不是我们想象的那样，说明他已经被别人修改过了，我们就需要重新拉取，再次尝试修改就好了**。

## 2 CAS 底层原理

### 2.1 AtomicInteger.getAndIncrement()实现原理

`AtomicInteger.getAndIncrement()` 源码如下所示：

```java
/**
 * Atomically increments by one the current value.
 *
 * @return the previous value
 */
public final int getAndIncrement() {
    return unsafe.getAndAddInt(this, valueOffset, 1);
}
```

可知该方法最终调用了 `Unsafe` 类的 `unsafe.getAndAddInt()` 方法，该方法的具体定义如下：

```java
/**
 * Atomically adds the given value to the current value of a field
 * or array element within the given object {@code o}
 * at the given {@code offset}.
 *
 * @param o object/array to update the field/element in
 * @param offset field/element offset
 * @param delta the value to add
 * @return the previous value
 * @since 1.8
 */
// @HotSpotIntrinsicCandidate
public final int getAndAddInt(Object o, long offset, int delta) {
    int v;
    do {
        v = getIntVolatile(o, offset);
    } while (!compareAndSwapInt(o, offset, v, v + delta));
    return v;
}
```

而 `unsafe.getAndAddInt()` 方法最终调用了 `compareAndSwapInt()` 方法，该方法的具体定义如下：

```java
/**
 * Performs a compare-and-set operation on an <code>int</code>
 * field within the given object.
 *
 * @param obj non-null; object containing the field
 * @param offset offset to the field within <code>obj</code>
 * @param expectedValue expected value of the field
 * @param newValue new value to store in the field if the contents are
 * as expected
 * @return <code>true</code> if the new value was in fact stored, and
 * <code>false</code> if not
 */
public native boolean compareAndSwapInt(Object obj, long offset,
        int expectedValue, int newValue);
```

该方法是一个 `native` 方法，含有 `obj`、`offset`、`expectedValue`、`newValue`，每个参数的具体含义如下：

* **obj：** 包含要更新的**字段**的对象。
* **offset：**该字段的**内存偏移地址**。
* **expectedValue：** 期望更新的值。
* **newValue：** 要更新的最新值。

**如果原子变量中该字段的值等于 `expectedValue`，则使用 `newValue` 值更新该值并返回 `true`，否则返回 `false`。**

假设线程 A 和线程 B 两个线程同时执行 `getAndAddInt` 操作（分别在不同的 CPU 上）：

1. `AtomicInteger` 里面的 `value` 原始值为 3，即主内存中 `AtomicInteger` 的 `value` 为 3，根据 `JMM` 模型，线程 `A` 和线程 `B` 各自持有一份值为 3 的 `value` 副本分别到各自的工作内存。
2. 线程 `A` 通过 `getIntVolatile(o, offset)` 拿到 `value` 值为 3，这时线程 `A` 被挂起。
3. 线程 `B` 也通过 `getIntVolatile(o, offset)` 拿到 `value` 值为 3，**刚好线程 `B` 没有被挂起并执行 `compareAndSwapInt` 方法**，比较内存中的值也为 3，成功修改内存值为 4，线程 `B` 执行完毕。
4. 这时线程 `A` 恢复，执行 `compareAndSwapInt` 方法比较，发现自己工作内存中的 `value` 值（3）和主内存中的值（4）不一样，说明**该值已经被其他线程抢先一步修改过了，线程 `A` 本次修改失败，只能重新读取再来一遍了**。
5. 线程 `A` 重新获取 `value` 值，因为**变量 `value` 被 `volatile` 修饰，所以其他线程对它的修改，线程 `A` 总能看到**，线程 `A` 继续执行 `compareAndSwapInt` 进行比较替换，直到成功。

### 2.2 Unsafe 应用解析

#### 2.2.1 Unsafe 介绍

1. `Unsafe` 是位于 `sun.misc` 包下的一个类，主要提供一些用于执行**低级别**、**不安全**操作的方法，如**直接访问系统内存资源**、**自主管理内存资源**等。这些方法在**提升 `Java` 运行效率、增强 `Java` 语言底层资源操作能力**方面起到了很大的作用。
2. 但由于 `Unsafe` 类使 `Java` 语言拥有了类似 `C` 语言指针一样操作内存空间的能力，这也增加了程序发生相关指针问题的风险，在程序中过度、不正确使用 `Unsafe` 类会使得程序出错的概率变大，因此对 `Unsafe` 的使用一定要慎重。

#### 2.2.2 Unsafe 源码解析

`Unsafe` 源码如下所示：

```java
/**
 * A collection of methods for performing low-level, unsafe operations.
 * Although the class and all methods are public, use of this class is
 * limited because only trusted code can obtain instances of it.
 *
 * @author John R. Rose
 * @see #getUnsafe
 */

public final class Unsafe {

    private static native void registerNatives();
    static {
        registerNatives();
        sun.reflect.Reflection.registerMethodsToFilter(Unsafe.class, "getUnsafe");
    }

    private Unsafe() {}

    private static final Unsafe theUnsafe = new Unsafe();

    /**
     * Provides the caller with the capability of performing unsafe
     * operations.
     *
     * <p> The returned <code>Unsafe</code> object should be carefully guarded
     * by the caller, since it can be used to read and write data at arbitrary
     * memory addresses.  It must never be passed to untrusted code.
     *
     * <p> Most methods in this class are very low-level, and correspond to a
     * small number of hardware instructions (on typical machines).  Compilers
     * are encouraged to optimize these methods accordingly.
     *
     * <p> Here is a suggested idiom for using unsafe operations:
     *
     * <blockquote><pre>
     * class MyTrustedClass {
     *   private static final Unsafe unsafe = Unsafe.getUnsafe();
     *   ...
     *   private long myCountAddress = ...;
     *   public int getCount() { return unsafe.getByte(myCountAddress); }
     * }
     * </pre></blockquote>
     *
     * (It may assist compilers to make the local variable be
     * <code>final</code>.)
     *
     * @exception  SecurityException  if a security manager exists and its
     *             <code>checkPropertiesAccess</code> method doesn't allow
     *             access to the system properties.
     */
    @CallerSensitive
    public static Unsafe getUnsafe() {
        Class<?> caller = Reflection.getCallerClass();
        if (!VM.isSystemDomainLoader(caller.getClassLoader()))
            throw new SecurityException("Unsafe");
        return theUnsafe;
    }
}
```

1. `Unsafe` 类为一单例实现，提供静态方法 `getUnsafe()` 获取 `Unsafe` 实例。
2. 当且仅当 `getUnsafe()` 方法的类为引导类加载器所加载时才合法，否则会抛出 `SecurityException` 异常。
3. 如果我们想使用这个类，可以通过如下方法获取其实例：
   1. 从 `getUnsafe()` 方法的使用限制条件出发，通过 `Java` 命令行命令 `-Xbootclasspath/a` 把调用 `Unsafe` 相关方法的类 `A` 所在 `jar` 包路径追加到默认的 `bootstrap` 路径中，使得 `A` 被引导类加载器加载，从而通过 `Unsafe.getUnsafe()` 方法安全的获取 `Unsafe` 实例，具体命令如下：
      
      ```java
      java -Xbootclasspath/a: ${path}   // 其中 path 为调用 Unsafe 相关方法的类所在 jar 包路径
      ```
   2. 通过反射获取单例对象 `theUnsafe`：
      
      ```java
      private static Unsafe reflectGetUnsafe() {
          try {
            Field field = Unsafe.class.getDeclaredField("theUnsafe");
            field.setAccessible(true);
            return (Unsafe) field.get(null);
          } catch (Exception e) {
            log.error(e.getMessage(), e);
            return null;
          }
      }
      ```

#### 2.2.3 功能介绍

![](https://ricear.com/media/202105//1621914601.7660275.png)

如上图所示，`Unsafe` 提供的 `API` 大致可分为**内存操作**、**CAS**、**Class 相关**、**对象操作**、**线程调度**、**系统信息获取**、**内存屏障**、**数组操作**等几类。

##### 2.2.3.1 内存操作

###### 2.2.3.1.1 特点

```java
//分配内存, 相当于 C++ 的 malloc 函数
public native long allocateMemory(long bytes);
//扩充内存
public native long reallocateMemory(long address, long bytes);
//释放内存
public native void freeMemory(long address);
//在给定的内存块中设置值
public native void setMemory(Object o, long offset, long bytes, byte value);
//内存拷贝
public native void copyMemory(Object srcBase, long srcOffset, Object destBase, long destOffset, long bytes);
//获取给定地址值，忽略修饰限定符的访问限制。与此类似操作还有: getInt，getDouble，getLong，getChar 等
public native Object getObject(Object o, long offset);
//为给定地址设置值，忽略修饰限定符的访问限制，与此类似操作还有: putInt,putDouble，putLong，putChar 等
public native void putObject(Object o, long offset, Object x);
//获取给定地址的 byte 类型的值（当且仅当该内存地址为 allocateMemory 分配时，此方法结果为确定的）
public native byte getByte(long address);
//为给定地址设置 byte 类型的值（当且仅当该内存地址为 allocateMemory 分配时，此方法结果才是确定的）
public native void putByte(long address, byte x);
```

1. 这部分主要包含**堆外内存的分配、拷贝、释放、给定地址值操作**等方法。
2. 通常，我们在 `Java` 中创建的对象都处于堆内内存（heap）中，**堆内内存是由 `JVM` 所管控的 `Java` 进程内存，并且他们遵循 `JVM` 的内存管理机制，`JVM` 会采用垃圾回收机制统一管理内存**。
3. 与之相对的是堆外内存，存在于 `JVM` 管控之外的内存区域，**`Java` 中对堆外内存的操作，依赖于 `Unsafe` 提供的操作堆外内存的 `native` 方法**。

###### 2.2.3.1.2 使用堆外内存的原因

1. **对垃圾回收停顿的改善：** 由于堆外内存是直接受操作系统管理而不是 `JVM`，所以当我们使用堆外内存时即可**保持较小的堆内内存的规模**，从而在 `GC` 时**减少回收停顿对于应用的影响**。
2. **提升程序或 `I/O` 操作的性能：** 通常**在 `I/O` 通信过程**中，会**存在堆内内存到堆外内存的拷贝操**作，对于需要**频繁进行内存间数据拷贝**且**生命周期较短的暂存数据**，都**建议存储到堆外内存**。

###### 2.2.3.1.3 典型应用

1. `DirectByteBuffer` 是 `Java` 实现堆外内存的一个重要类，**通常用在通信过程中做缓冲池**，如在 `Netty`、`MINA` 等 `NIO` 框架中应用广泛。
2. `DirectByteBuffer` 对于堆外内存的创建、使用、销毁等逻辑均由 `Unsafe` 提供的堆外内存 `API` 来实现。
3. 下图为 `DirectByteBuffer` 构造函数：
   1. 创建 `DirectBuffer` 的时候，通过 `Unsafe.allocateMemory()` 分配内存、`Unsafe.setMemory()` 进行内存初始化。
   2. 而后构建 `Cleaner` 对象用于跟踪 `DirectByteBuffer` 对象的垃圾回收，以实现 `DirectByteBuffer` 被垃圾回收时，分配的堆外内存一起被释放。

![](https://ricear.com/media/202105//1621914601.7709806.png)

> 如何通过构建垃圾回收追踪对象 `Cleaner` 实现堆外内存释放呢？
> 
> 1. `Cleaner` 继承自 `Java` 四大引用类型之一的**虚引用**（`PhantomReference`）（众所周知，无法通过虚引用获取与之关联的对象实例，且当对象仅被虚引用引用时，在任何发生 `GC` 的时候，其均可被回收），通常 `PhantomReference` 与引用队列 `ReferenceQueue` 结合使用，可以实现虚引用关联对象被垃圾回收时能够进行系统通知、资源清理等功能。
> 2. 如下图所示，当某个被 `Cleaner` 引用的对象回收时，`JVM` 垃圾收集器会将此对象的引用放入到对象引用的 `pending` 链表中，等待 `ReferenceHandler` 进行相关处理。
> 3. 其中 `ReferenceHandler` 为一个拥有最高优先级的守护线程，会循环不断的处理 `pending` 链表中的对象引用，执行 `Cleaner` 的 `clean` 方法进行相关清理工作。
> 4. 所以当 `DirectByteBuffer` 仅被 `Cleaner` 引用（虚引用）时，其可以在任意 `GC` 时段被回收。当 `DirectByteBuffer` 实例对象被回收时，在 `ReferenceHandler` 线程操作中，会调用 `Cleaner` 的 `clean` 方法根据创建 `Cleaner` 时传入的 `Deallocator` 来进行堆外内存的释放。

![](https://ricear.com/media/202105//1621914601.7754323.png)

![](https://ricear.com/media/202105//1621914601.7804196.png)

![](https://ricear.com/media/202105//1621914601.782398.png)

![](https://ricear.com/media/202105//1621914601.7853792.png)

##### 2.2.3.2 CAS

###### 2.2.3.2.1 特点

```java
/**
 * Performs a compare-and-set operation on an <code>int</code>
 * field within the given object.
 *
 * @param obj non-null; object containing the field
 * @param offset offset to the field within <code>obj</code>
 * @param expectedValue expected value of the field
 * @param newValue new value to store in the field if the contents are
 * as expected
 * @return <code>true</code> if the new value was in fact stored, and
 * <code>false</code> if not
 */
public native boolean compareAndSwapInt(Object obj, long offset,
        int expectedValue, int newValue);

public native boolean compareAndSwapLong(Object obj, long offset,
        long expectedValue, long newValue);

public native boolean compareAndSwapObject(Object obj, long offset,
        Object expectedValue, Object newValue);
```

上述部分主要为 `CAS` 相关操作，其底层实现即为 `CPU` 指令 `cmpxchg`。

###### 2.2.3.2.2 典型应用

1. 如下图所示，在 `AtomicInteger` 的实现中，静态字段 `valueOffset` 即为字段 `value` 的内存偏移地址，`valueOffset` 的值在 `AtomicInteger` 初始化时，在静态代码块中通过 `Unsafe` 的 `objectFieldOffset()` 方法获取。
2. 在 `AtomicInteger` 中提供的线程安全方法中，通过字段 `valueOffset` 的值可以定位到 `AtomicInteger` 对象中 `value` 的内存地址，从而可以根据 `CAS` 实现对 `value` 字段的原子操作。

下面以 `AtomicInteger` 中的 `incrementAndGet()` 方法具体分析一下其执行过程。

1. 根据 `Unsafe` 的 `objectFieldOffset()` 方法获取 `value` 的偏移地址 `valueOffset`。

![](https://ricear.com/media/202105//1621914601.7890062.png)

2. 调用 `unsafe.getAndAddInt()` 方法，获取**被更新的值**，然后加 1，返回**更新后的值**。

![](https://ricear.com/media/202105//1621914601.7920382.png)

3. `unsafe.getAndAddInt()` 方法中根据 `value` 的偏移量 `valueOffset` 获取获取 `value` 的值，然后通过 `CAS` 方法获取**被更新的值**。

![](https://ricear.com/media/202105//1621914601.7939737.png)

下图为某个 `AtomInteger` 对象自增操作前后的内存示意图：

1. 对象的基地址 `baseAddress="0x110000"`。
2. 通过 `baseAddress + valueOffset` 得到 `value` 的内存地址 `valueAddress = "0x11000c"`。
3. 然后通过 `CAS` 进行原子性的更新操作，成功则返回，否则继续重试，直到更新成功为止。

![](https://ricear.com/media/202105//1621914601.7995265.png)

##### 2.2.3.3 线程调度

###### 2.2.3.3.1 特点

```java
//取消阻塞线程
public native void unpark(Object thread);
//阻塞线程
public native void park(boolean isAbsolute, long time);
//获得对象锁（可重入锁）
@Deprecated
public native void monitorEnter(Object o);
//释放对象锁
@Deprecated
public native void monitorExit(Object o);
//尝试获取对象锁
@Deprecated
public native boolean tryMonitorEnter(Object o);
```

1. 这部分，主要包括线程**挂起、恢复、锁机制**等方法。
2. 方法 `park()` 和 `unpark()` 即可实现**线程的挂起和恢复**：
   1. 将一个线程进行挂起是通过 `park()` 方法实现的，调用 `park()` 方法后，线程将**一直阻塞直到超时或者中断条件出现**。
   2. `unpark()` 方法可以**终止一个挂起的线程，使其恢复正常**。

###### 2.2.3.3.2 典型应用

`Java` 锁和同步器框架的核心类 `AbstractQueuedSynchronizer`，就是通过调用 `LockSupport.park()` 和 `LockSupport.unpark()` 实现线程的阻塞和唤醒的，而 `LockSupport` 的 `park()` 和 `unpark()` 方法实际上是调用 `Unsafe` 的 `park()` 和 `unpark()` 方式来实现的。

##### 2.2.3.4 Class 相关

###### 2.2.3.4.1 特点

```java
//获取给定静态字段的内存地址偏移量，这个值对于给定的字段是唯一且固定不变的
public native long staticFieldOffset(Field f);
//获取一个静态类中给定字段的对象指针
public native Object staticFieldBase(Field f);
//判断是否需要初始化一个类，通常在获取一个类的静态属性的时候（因为一个类如果没初始化，它的静态属性也不会初始化）使用。 当且仅当 ensureClassInitialized 方法不生效时返回 false。
public native boolean shouldBeInitialized(Class<?> c);
//检测给定的类是否已经初始化。通常在获取一个类的静态属性的时候（因为一个类如果没初始化，它的静态属性也不会初始化）使用。
public native void ensureClassInitialized(Class<?> c);
//定义一个类，此方法会跳过 JVM 的所有安全检查，默认情况下，ClassLoader（类加载器）和 ProtectionDomain（保护域）实例来源于调用者
public native Class<?> defineClass(String name, byte[] b, int off, int len, ClassLoader loader, ProtectionDomain protectionDomain);
//定义一个匿名类
public native Class<?> defineAnonymousClass(Class<?> hostClass, byte[] data, Object[] cpPatches);
```

这部分主要提供 `Class` 和他的静态字段的操作相关方法，包含**静态字段内存定位、定义类、定义匿名类、检验&确保初始化等**。

###### 2.2.3.4.2 典型应用

1. 从 `Java 8` 开始，`JDK` 使用 `invokDynamic` 及 `VM Anonymous Class` 结合来实现 `Java` 语言层面上的 `Lambda` 表达式：
   1. `invokdynamic`：`invokdynamic` 是 `Java 7`**为了实现在 `JVM` 上运行动态语言而引入的一条新的虚拟机指令**，他可以实现**在运行期动态解析出调用点限定符所引用的方法**，然后再**执行该方法**，`invokedynamic` 指令的分派逻辑是由用户设定的引导方法决定。
   2. `VM Anonymous Class`：
      1. 可以看作是一种**模板机制**，针对于程序**生成很多结构相同、仅若干常量不同的类**时，可以**先创建包含常量占位符的模板类**，然后通过 `Unsafe.defineAnonymousClass()` 方法**定义具体类时填充模板的占位符并生成具体的匿名类**。
      2. 生成的匿名类不显式挂在任何 `Class Loader` 下面，**只有当该类没有实例对象、且没有强引用来引用该类的 `Class` 对象时，该类就会被 `GC` 回收**。
      3. 因此 `VM Anonymous Class` 相比于 `Java` 语言层面的匿名内部类**无需通过 `ClassClassLoader` 进行类加载且更容易回收**。
2. `Lambda` 表达式的实现主要包括以下几个步骤：
   1. 通过 `invokedynamic` 指令**调用引导方法生成调用点**，在此过程中，**会通过 `ASM` 动态生成字节码**。
   2. 然后利用 `Unsafe` 的 `defineAnonymousClass` 方法定义**实现相应的函数式接口的匿名类**。
   3. 接着**实例化此匿名类**，并返回**与此匿名类中函函数式方法的方法句柄关联的调用点**。
   4. 最后**通过此调用点实现相应 `Lambda` 表达式定义逻辑的功能**。

##### 2.2.3.4 对象操作

###### 2.2.3.4.1 特点

```java
//返回对象成员属性在内存地址相对于此对象的内存地址的偏移量
public native long objectFieldOffset(Field f);
//获得给定对象的指定地址偏移量的值，与此类似操作还有：getInt，getDouble，getLong，getChar 等
public native Object getObject(Object o, long offset);
//给定对象的指定地址偏移量设值，与此类似操作还有：putInt，putDouble，putLong，putChar 等
public native void putObject(Object o, long offset, Object x);
//从对象的指定偏移量处获取变量的引用，使用 volatile 的加载语义
public native Object getObjectVolatile(Object o, long offset);
//存储变量的引用到对象的指定的偏移量处，使用 volatile 的存储语义
public native void putObjectVolatile(Object o, long offset, Object x);
//有序、延迟版本的 putObjectVolatile 方法，不保证值的改变被其他线程立即看到。只有在 field 被 volatile 修饰符修饰时有效
public native void putOrderedObject(Object o, long offset, Object x);
//绕过构造方法、初始化代码来创建对象
public native Object allocateInstance(Class<?> cls) throws InstantiationException;
```

此部分主要包含**对象成员属性相关操作**及**非常规的对象实例化等相关方法**。

###### 2.2.3.4.2 典型应用

* **常规对象实例化方式**：
  1. 我们通常所用到的创建对象的方式，从本质上讲，都是通过 `new`**机制来实现对象的创建**。
  2. 但是，`new` 机制有个特点就是**当类只提供有参的构造函数且无显示声明无参构造函数时，则必须使用有参构造函数进行对象构造，而使用有参构造函数时，必须传递相应个数的参数才能完成对象实例化**。
* **非常规的实例化方式**：
  1. `Unsafe` 中提供 `allocateInstance` 方法，**仅通过 `Class` 对象就可以创建此类的实例对象，而不需要调用其构造函数、初始化代码、`JVM` 安全检查等等**。
  2. 他**抑制修饰符检测**，也就是即使构造器是 `private` 修饰的也能通过此方法实例化，只需提供类对象即可创建相应对象。
  3. 由于这种特性，`allocateInstance` 在 `java.lang.invoke`、`Objenesis`（提供绕过类构造器的对象生成方式）、`Gson`（反序列化时用到）中都有相应应用。

如下图所示，在 `Gson` 反序列化时，如果类有**默认构造函数**，则**通过反射调用默认构造函数创建实例**，否则通过 `UnsafeAllocator` 来实现对象实例的构造。`UnsafeAllocator` 通过调用 `Unsafe` 的 `allocateInstance()` 实现对象的实例化，**保证在目标类无默认构造函数时，反序列化不受影响**。

![](https://ricear.com/media/202105//1621914601.804864.png)

##### 2.2.3.5 数组相关

###### 2.2.3.5.1 特点

```java
//返回数组中第一个元素的偏移地址
public native int arrayBaseOffset(Class<?> arrayClass);
//返回数组中一个元素占用的大小
public native int arrayIndexScale(Class<?> arrayClass);
```

这部分与数组相关的方法主要有 `arrayBaseOffset` 和 `arrayIndexScale` 两个方法，二者配合起来使用，即可**定位数组中每个元素在内存中的位置**。

###### 2.2.3.5.2 典型应用

1. 这两个与数据操作相关的方法，在 `java.util.concurrent.atomic` 包下的 `AtomicIntegerArray`（可以实现对 `Integer` 数组中每个元素的原子性操作）中有典型的应用。
2. 如下图 `AtomicIntegerArray` 源码所示，通过 `Unsafe` 的 `arrayBaseOffset`、`arrayIndexScale` 分别获取**数组首元素的偏移地址**`base` 及**单个元素大小因子**`scale`。
3. 后续相关原子性操作，均依赖于这两个值进行数组中元素的定位，如下图所示的 `getAndAdd` 方法即通过 `checkedByteOffset` 方法**获取某数组元素的偏移地址**，而后**通过 `CAS` 实现原子性操作**。

![](https://ricear.com/media/202105//1621914601.8112657.png)

##### 2.2.3.6 内存屏障

###### 2.2.3.6.1 特点

```java
//内存屏障，禁止 load 操作重排序。屏障前的 load 操作不能被重排序到屏障后，屏障后的 load 操作不能被重排序到屏障前
public native void loadFence();
//内存屏障，禁止 store 操作重排序。屏障前的 store 操作不能被重排序到屏障后，屏障后的 store 操作不能被重排序到屏障前
public native void storeFence();
//内存屏障，禁止 load、store 操作重排序
public native void fullFence();
```

这部分与**内存屏障**相关的主要包括**禁止 `load` 操作重排序、禁止 `store` 操作重排序、禁止 `load` 和 `store` 重排序**。

###### 2.2.3.6.2 典型应用

1. 在 `Java 8` 中引入了一种锁的新机制-`StampedLock`，他可以看成是读写锁的一个改进版本。
2. `StampedLock` 提供了一种**乐观读锁**的实现，这种乐观读锁**类似于无锁的操作**，**完全不会阻塞写线程获取写锁**，从而**缓解读多写少时写线程“饥饿”现象**。
3. 由于 `StampedLock` 提供的乐观读锁**不阻塞写线程获取读锁**，当线程共享变量从**主内存 `load` 到线程工作内存**时，**会存在数据不一致的问题**。
4. 所以，当使用 `StampedLock` 的乐观读锁时，需要遵从如下图用例中使用的模式来确保数据的一致性：
   1. 在方法 `distanceFromOrigin` 中，首先，**通过 `tryOptimisticRead` 方法获取乐观读标记**。
   2. 然后**从主内存中加载点的坐标值 `(x, y)`**。
   3. 然后**通过 `StampedLock` 的 `validate` 方法校验锁的状态**，判断坐标点 `(x, y)`**从主内存加载到线程工作内存过程中，主内存的值是否已经通过其他线程通过 `move` 方法修改**：
      1. 如果 `validate` 返回值为 `true`，证明 `(x, y)` 的值**未被修改，可参与后续计算**。
      2. 否则，需**加悲观读锁，再次从主内存加载 `(x, y)` 的最新值，然后再进行距离计算**。
   4. 其中，**校验锁状态这步操作至关重要，需要判断锁状态是否发生改变，从而判断之前 `copy` 到线程工作内存中的值是否与主内存的值存在不一致**。
   5. `StampedLock.validate` 方法**通过锁标记与相关常量进行位运算、比较来校验锁状态**，在校验逻辑之前，或通过 `Unsafe.loadFence` 方法注入一个 `load` 内存屏障，目的是**避免步骤 2**和 `StampedLock.validate`**中锁状态校验运算发生重排序导致锁状态校验不准确的问题**。

![](https://ricear.com/media/202105//1621914601.817298.png)

![](https://ricear.com/media/202105//1621914601.82153.png)

##### 2.2.3.7 系统相关

###### 2.2.3.7.1 特点

```java
//返回系统指针的大小。返回值为 4（32 位系统）或 8（64 位系统）。
public native int addressSize();  
//内存页的大小，此值为 2 的幂次方。
public native int pageSize();
```

这部分包含两个**获取系统相关信息**的方法。

###### 2.2.3.7.2 典型应用

`java.nio` 下的工具类 `Bits` 中**计算待申请内存所需内存页数量**的静态方法，其依赖于 `Unsafe` 中 `pageSize` 方法**获取系统内存页大小实现后续计算逻辑**。

![](https://ricear.com/media/202105//1621914601.826645.png)

#### 2.2.4 总结

`Unsafe` 提供了很多便捷、有趣的 `API` 方法，同时对于 `Unsafe` 中所包含的大量的**自主操作内存的方法**，如果使用不当，会对程序带来许多不可控的灾难，因此对它的使用我们需要慎之又慎。

## 3 CAS 缺点

### 3.1 自旋问题

![](https://ricear.com/media/202105//1621914601.8287833.png)

1. 从源码可以看出所谓的自选无非就是操作结果失败后继续循环操作，这种操作也称为**自旋锁**，是一种**乐观锁**机制，一般来说**都会给一个限定的自选次数，防止进入死循环**。
2. 自旋锁的优点是**不需要休眠当前线程**，因为**自旋锁使用者一般保持锁时间非常短**，因此**选择自旋而不是休眠当前线程是提高并发性能的关键点**，这是因为**减少了很多不必要的线程上下文切换开销**。
3. 但是，**如果 `CAS` 一致操作不成功，会造成长时间原地自旋，会给 `CPU` 带来非常大的执行开销**。

### 3.2 只能保证一个共享变量的原子性

1. 因为**`Java` 中的 `CAS` 操作只是对 `CPU` 的 `cmpxchgq` 指令的一层封装**，它的功能就是**一次只原子地修改一个变量**。
2. 因此当**对一个共享变量执行操作时**，我们可以使用循环 `CAS` 的方式来保证原子操作。
3. 但是，**对多个共享变量操作时**，循环 `CAS` 就无法保证操作的原子性，这个时候就**需要用锁来保证原子性**了。

### 3.3 ABA 问题

#### 3.3.1 简介

在多线程场景下会出现 `ABA` 问题，具体如下：

1. 假如有 2 个线程同时对同一个值（初始值为 `A`）进行 `CAS` 操作，这三个线程如下：
   1. **线程 1**：期望值为 `A`，欲更新的值为 `B`。
   2. **线程 2：** 期望值为 `A`，欲更新的值为 `B`。
2. **线程 1 抢先获得时间片**，而**线程 2 因为其他原因阻塞了**。
3. 线程 1 取值与期望的 `A` 值比较，发现相等然后将值更新为 `B`。
4. 这个时候出现了**线程 3，期望值为 `B`，欲更新的值为 `A`**，线程 3 取值与期望的 `B` 值比较，发现相等则**将值更新为 `A`**。
5. 此时**线程 2 从阻塞中恢复**，并且**获得了 `CPU` 时间片**，这时候线程 2 取值与期望的值 `A` 比较，发现相等则**将值更新为 `B`**，**虽然线程 2 也完成了操作，但是线程 2 并不知道值已经经过了**$A \rightarrow B \rightarrow A$ 的变化过程。

#### 3.3.2 带来的危害

1. 小明在提款机，提取了 50 元，因为提款机问题，**有两个线程，同时把余额从 100 变成 50**：
   1. **线程 1（提款机）：** 获取当前值 100，期望更新为 50。
   2. **线程 2（提款机）：** 获取当前值 100，期望更新为 50.
2. **线程 1 成功执行，线程 2 因为某种原因 `block` 了**，这时，某人给小明汇款 50：
   1. **线程 3（提款机）：** 获取当前值 50，期望更新为 100。
3. 这个时候**线程 3 成功执行，余额变为 100**。
4. **线程 2 从 `block` 中恢复，获取到的也是 100，`compare` 之后，继续更新余额为 50**。
5. 此时可以看到，**实际余额应该为 100**，但是**实际上变为了 50**，这就是**ABA**问题带来的成功提交。

#### 3.3.3 解决方法

**在变量前面加上版本号**，每次变量更新的时候**变量的版本号都加 1**，即 $A \rightarrow B \rightarrow A$ 变成了 $1A \rightarrow 2B \rightarrow 3A$。

在 `Java` 中，`AtomicStampedReference` 也实现了这个处理方式，具体如下：

1. `AtomicStampedReference` 的内部类 `Pair`：

![](https://ricear.com/media/202105//1621914601.833229.png)

其中：

* **`reference`：维护对象的引用。**
* **`stamp`：维护修改的版本号。**

2. `compareAndSet` 方法：

![](https://ricear.com/media/202105//1621914601.841988.png)

从 `compareAndSet` 方法得知，**如果要修改内存中的值，不仅要值相同，还要版本号相同**。

## 4 参考文献

1. [一文彻底搞懂 CAS 实现原理](https://zhuanlan.zhihu.com/p/94762520#:~:text=3CAS%E5%8E%9F%E7%90%86%E5%89%96%E6%9E%90,%E5%AF%B9%E5%BA%94%E7%9A%84%E6%98%AF%E6%82%B2%E8%A7%82%E9%94%81%E3%80%82&text=%E5%BD%93%E5%A4%9A%E4%B8%AA%E7%BA%BF%E7%A8%8B%E6%93%8D%E4%BD%9C,%E9%94%81%EF%BC%8C%E4%B9%9F%E5%8F%AF%E4%BB%A5%E7%9B%B4%E6%8E%A5%E9%80%80%E5%87%BA%E3%80%82)。
2. [搞定 CAS 的原理，看这一篇就够了！](https://blog.csdn.net/qq_42370146/article/details/105559575)
3. [Java 并发之 CAS 原理分析](https://objcoding.com/2018/11/29/cas)。
4. [Java 魔法类：Unsafe 应用解析](https://tech.meituan.com/2019/02/14/talk-about-java-magic-class-unsafe.html)。
5. [Atomic 实现原子性源码分析：CAS（比较并交换）、Unsafe 类](https://www.cnblogs.com/MWCloud/p/11460186.html)。
6. [为什么 CAS 只能保证一个共享变量的原子操作？](https://www.zhihu.com/question/266359785/answer/306691309)
7. [CAS 原理分析及 ABA 问题详解](https://juejin.cn/post/6844903796129136647)。

