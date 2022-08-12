---
sidebar_position: 5
---

## 1 介绍

从 `JDK 1.2` 版本开始，对象的引用被划分为 4 中级别，从而**使程序能更加灵活地控制对象的生命周期**，这 4 中级别**从高到低**依次为**强引用（`FinalReference`）、软引用（`SoftReference`）、弱引用（`WeakReference`）和虚引用（`PhantomReference`）。**

![](https://notebook.grayson.top/media/202105//1621914616.5661292.png)

## 2 具体划分

### 2.1 强引用（FinalReference）

1. 强引用是使用最普遍的引用，**如果一个对象具有强引用，那么垃圾回收器绝对不会回收他**，如下：
   
   ```java
   Object finalReference = new Object();
   ```
2. **当空间不足时，`Java` 虚拟机宁愿抛出 `OutOfMemoryError` 错误，使程序异常终止，也不会靠随意回收具有强引用的对象来解决内存不足的问题**。
3. 如果**强引用对象不使用时**，**需要弱化从而使 `GC` 能够回收，显示地设置 `finalReference` 为 `null`**，或**让其超出对象的生命周期范围**，则 `GC` 认为**该对象不存在引用**，这时就可以回收这个对象，**具体什么时候回收取决于 `GC` 算法**。
   
   ```
   finalReference = null;
   ```
4. 如果**一个方法内部有一个强引用（局部变量）**，这个**引用保存在 `Java` 栈中，真正的引用内容（`Object`）保存在 `Java` 堆中**，**当这个方法运行完成后，就会退出方法栈**，则**引用对象的引用数就会变为 0**，**这个对象就会被回收**。
   
   ```java
   public void test() {
       Object finalReference = new Object();
       // 省略其他操作
   }
   ```
5. 如果这个变量为**全局变量**时，就需要**在不用这个对象时赋值为 `null`**，因为**强引用不会被垃圾回收**。

### 2.2 软引用（SoftReference）

1. 如果一个对象只具有**软引用**，则**在内存空间充足时，垃圾回收器就不会回收他**；如果**内存空间不足了，就会回收这些对象的内存**。只要垃圾回收器没有回收他，该对象就可以被程序使用。
   
   ```java
   // 强引用
   String strongReference = new String("abc");
   // 软引用
   String str = new String("abc");
   SoftReference<String> softReference = new SoftReference<String>(str);
   ```
2. **软引用可以和一个引用队列（`ReferenceQueue`）联合使用，如果引用队列所引用的对象被垃圾回收，`Java` 虚拟机就会把这个软引用加入到与之关联的引用队列中。**
   
   ```java
   ReferenceQueue<String> referenceQueue = new ReferenceQueue<>();
   String str = new String("abc");
   SoftReference<String> softReference = new SoftReference<>(str, referenceQueue);
   
   str = null;
   // Notify GC
   System.gc();
   
   System.out.println(softReference.get()); // abc
   
   Reference<? extends String> reference = referenceQueue.poll();
   System.out.println(reference); //null
   ```
   
   > 注意：软引用对象是在 **`JVM` 内存不够的时候**才会被回收，我们调用 `System.gc()` 方法只是起通知作用，`JVM` 什么时候扫描回收对象是 `JVM` 自己的状态决定的。就算扫描到软引用对象也不一定回收他，只有内存不够的时候才会回收。
3. 当**内存不足时，`JVM` 首先将软引用对象置为 `null`，然后通知垃圾回收器进行回收**，也就是说，**垃圾回收器会在虚拟机抛出 `OutOfMemoryError` 之前回收软引用对象**，而且虚拟机会尽可能**优先回收长时间闲置不用的软引用对象，对那些刚构建的或刚使用过的较新的软对象会被虚拟机尽可能保留，这就是引入引用队列（`ReferenceQueue`）的原因**。
   
   ```java
   if(JVM 内存不足) {
       // 将软引用中的对象引用置为 null
       str = null;
       // 通知垃圾回收器进行回收
       System.gc();
   }
   ```

### 2.3 弱引用（WeakReference）

1. **弱引用与软引用的区别**在于：**弱引用的对象拥有更短的生命周期**。
2. 在垃圾回收器线程扫描他所管辖的内存区域的过程中，**一旦发现了只具有弱引用的对象**，不管当前内存空间足够与否，**都会回收它的内存**，回收的时候，`JVM` 会首先**将软引用中的对象引用置为 `null`，然后通知垃圾回收器进行回收**。
3. 不过，由于垃圾回收器是一个**优先级很低的线程**，因此他**不一定会很快发现那些只具有弱引用的对象**。
4. **软引用可以和一个引用队列（`ReferenceQueue`）联合使用**，如果**引用队列所引用的对象被垃圾回收**，`Java` 虚拟机就**会把这个软引用加入到与之关联的引用队列中**。
5. 如果一个对象是**偶尔（很少）使用**，并且希望**在使用时随时就能获取到**，但又**不想影响此对象的垃圾收集**，那么我们**可以用弱引用来记住此对象**。
6. 下面的代码会让一个弱引用再次变为一个强引用：
   ```java
   String str = new String("abc");
       WeakReference<String> weakReference = new WeakReference<>(str);
       // 弱引用转强引用
       String strongReference = weakReference.get();
   ```

### 2.4 虚引用（PhantomReference）

#### 2.4.1 特点

1. **无法通过虚引用来获取一个对象的真实引用。**
   
   ```java
   ReferenceQueue queue = new ReferenceQueue();
   PhantomReference<byte[]> reference = new PhantomReference<byte[]>(new byte[1], queue);
   System.out.println(reference.get());
   ```
   
   运行结果：
   
   ```txt
   null
   ```
   
   ![](https://notebook.grayson.top/media/202105//1621914616.5772505.png)
2. **虚引用必须与 `ReferenceQueue` 一起使用，当 `GC` 准备回收一个对象，如果发现他还有虚引用，就会在回收之前，把这个虚引用加入到与之关联的 `ReferenceQueue` 中**，此时**他的实例对象还在内存中**。
   
   ![](https://notebook.grayson.top/media/202105//1621914616.5795465.png)
   
   运行结果：
   
   ![](https://notebook.grayson.top/media/202105//1621914616.5818026.png)
   
   我们简单分析下代码：
   
   1. 第一个线程往集合里面塞数据，随着数据越来越多，肯定会发生 `GC`。
   2. 第二个线程死循环，从 `queue` 里面拿数据，如果拿出来的数据不是 `null`，就打印出来。
   
   从运行结果可以看到，当**发生 `GC` 时，虚引用就会被回收，并且把回收的通知放到 `ReferenceQueue` 中**。

#### 2.4.2 适用场景

##### 2.4.2.1 确定对象从内存中回收的具体时间

虚引用针对一些**内存敏感型**的任务可以**帮助我们确定对象从内存中回收的具体时间**，例如**延迟给新的对象分配内存（例如很大的图片），直到以前的内存被释放**。

##### 2.4.2.2 替代 finalize 方法，保证对象在 finalize 时不会复活（Resurrect）

1. 虚引用可以用来**代替 `finalize` 方法，保证对象在 `finalize` 时不会复活（`Resurrect`）。**
2. **这允许对象在一个周期内完成垃圾回收，而不需要等待下一个垃圾回收期以确保他没有复活。**

![](https://notebook.grayson.top/media/202105//1621914616.5833793.png)

## 3 总结

![](https://notebook.grayson.top/media/202105//1621914616.5863366.png)

## 4 参考文献

1. [理解 Java 的强引用、软引用、弱引用和虚引用](https://juejin.cn/post/6844903665241686029)。
2. [强软弱虚引用，只有体会过了，才能记住](https://www.cnblogs.com/CodeBear/p/12447554.html)。
3. [Phantom References in Java](https://www.baeldung.com/java-phantom-reference).
4. [虚引用](https://zh.wikipedia.org/wiki/%E8%99%9A%E5%BC%95%E7%94%A8)。

