---
sidebar_position: 4
---

## 1 HashSet

### 1.1 简介

1. **HashSet 是 Set 的一个实现类**，其对应的继承关系图如下：
   ![](https://ricear.com/media/202201/2022-01-09_205846_463125.png)
2. HashSet 是**基于 HashMap 来实现**的，操作很简单，更像是对 HashMap 做了一次“封装”，而且**只使用了 HashMap 的 key 来实现各种特性**，然后**构造了一个不可变的对象作为一个假的 value 来用**：
   
   ```java
   public class HashSet<E>
       extends AbstractSet<E>
       implements Set<E>, Cloneable, java.io.Serializable
   {
       private transient HashMap<E,Object> map;
       private static final Object PRESENT = new Object();
   
       public HashSet() {
         map = new HashMap<>();
       }
   }
   ```
3. 其**基本操作也很简单**，**就是调用 HashMap 的相关方法**：
   
   ```java
   public boolean add(E e) {
       return map.put(e, PRESENT)==null;
   }
   
   public boolean contains(Object o) {
       return map.containsKey(o);
   }
   
   public boolean remove(Object o) {
       return map.remove(o)==PRESENT;
   }
   
   public int size() {
       return map.size();
   }
   
   public boolean isEmpty() {
       return map.isEmpty();
   }
   ```
4. HashSet **可以保证基础数据类型的不重复**，这是**因为基础数据类型已经重写了 `hashCode()` 和 `equals()` 方法**，**如果要保证自定义对象的不重复**，**也需要重写对应的 `hashCode()` 和 `equals()` 方法**：
   
   1. 重写 `hashCode()` 和 `equals()` 方法前：
      
      ```java
      public class HashSetExample {
          public static void main(String[] args) {
              HashSet<Person> personSet = new HashSet<>();
              personSet.add(new Person("曹操", "123"));
              personSet.add(new Person("孙权", "123"));
              personSet.add(new Person("曹操", "123"));
              // 循环打印 HashSet 中的所有元素
              personSet.forEach(p -> System.out.println(p));
          }
      }
      
      @ToString
      class Person {
          private String name;
          private String password;
      
          public Person(String name, String password) {
              this.name = name;
              this.password = password;
          }
      }
      ```
      
      ```txt
      Person(name=曹操, password=123)
      Person(name=曹操, password=123)
      Person(name=孙权, password=123)
      ```
      
      从上面的输出结果可以看出有重复的记录。
   2. 重写 `hashCode()` 和 `equals()` 方法后：
      
      ```java
      public class HashSetExample {
          public static void main(String[] args) {
              HashSet<Person> personSet = new HashSet<>();
              personSet.add(new Person("曹操", "123"));
              personSet.add(new Person("孙权", "123"));
              personSet.add(new Person("曹操", "123"));
              // 循环打印 HashSet 中的所有元素
              personSet.forEach(p -> System.out.println(p));
          }
      }
      
      @ToString
      @EqualsAndHashCode
      class Person {
          private String name;
          private String password;
      
          public Person(String name, String password) {
              this.name = name;
              this.password = password;
          }
      }
      ```
      
      ```txt
      Person(name=曹操, password=123)
      Person(name=孙权, password=123)
      ```
      
      从上面的输出结果可以看出重写 `hashCode()` 和 `equals()` 方法之后没有重复记录。

### 1.2 原理

#### 1.2.1 HashSet 如何保证元素不重复

1. **HashSet 中的 add 方法**，**实际调用的是[HashMap](https://ricear.com/project-34/doc-813)中的[put](https://ricear.com/project-34/doc-813/#1-3-2-2-put-%E6%96%B9%E6%B3%95%E7%9A%84%E6%89%A7%E8%A1%8C%E5%8E%9F%E7%90%86)方法**。
2. **当添加的元素有重复时**，**会判断对应的 value 值是否相同**，**如果相同的话会直接返回 false**，**表示添加元素失败**，**而 HashSet 中的 map 对应的 value 为一个不可变的对象**，**因此 HashSet 中的 map 对应的 value 都相等**，**因此当 HashSet 添加重复的元素时会直接返回 false**，**从而保证元素不重复**。

## 2 TreeSet

### 2.1 简介

1. **TreeSet 在保证元素唯一性的基础上**，**还可以对元素进行排序**，**支持两种排序方式**，分别为**自然排序**和**自定义排序**。
2. 和 HashSet 不同的是，**TreeSet 中的元素不需要重写 `hashCode()` 和 `equals()` 方法**，**因为 TreeSet 是通过比较器去重的**，**所有元素都必须实现 Comparable 接口**，**然后重写 `compareTo()` 方法**。
3. TreeSet 是**基于 [TreeMap](https://ricear.com/project-34/doc-813/#3-TreeMap) 来实现**的，操作很简单，更像是对 TreeMap 做了一次“封装”，而且**只使用了 TreeMap 的 key 来实现各种特性**，然后**构造了一个不可变的对象作为一个假的 value 来用**：
   
   ```java
   public class TreeSet<E> extends AbstractSet<E>
       implements NavigableSet<E>, Cloneable, java.io.Serializable
   {
       private transient NavigableMap<E,Object> m;
       private static final Object PRESENT = new Object();
   
       public TreeSet() {
           this(new TreeMap<E,Object>());
       }
   }
   ```
4. 其**基本操作也很简单**，**就是调用 TreeMap 的相关方法**：
   
   ```java
   public int size() {
       return m.size();
   }
   
   public boolean isEmpty() {
       return m.isEmpty();
   }
   
   public boolean contains(Object o) {
       return m.containsKey(o);
   }
   
   public boolean add(E e) {
       return m.put(e, PRESENT)==null;
   }
   
   public boolean remove(Object o) {
       return m.remove(o)==PRESENT;
   }
   
   public void clear() {
       m.clear();
   }
   ```

### 2.2 原理

#### 2.2.1 TreeSet 如何保证元素不重复

1. 具体可参考[HashSet 如何保证元素不重复](#1-2-1-HashSet-如何保证元素不重复)。

#### 2.2.2 TreeSet 如何保证元素有序

1. 因为 TreeSet 是**基于 TreeMap 实现**的，**在向 TreeMap 中[添加元素](https://ricear.com/project-34/doc-813/#3-2-3-put-%E6%96%B9%E6%B3%95)时会按照相应的排序规则进行排序**，因此**TreeSet 中的元素也是有序的**。

## 参考文献

1. [Java 集合中 HashSet 的原理及常用方法](https://mp.weixin.qq.com/s?src=11×tamp=1641019837&ver=3531&signature=CpwjItg08DHJ4mK4OJgd4r8yk9CpNHhapoFF5yI*bx2LICDAcQytuGJO3sbtEfOWe8SwHcFacfL2L7BYw0hy8oqPRBxZ8s2y-cTFe9EjVmFFzH4*OYAbCdKdA8tlF8Iw&new=1)。
2. [面试官：HashSet 是如何保证元素不重复的？](https://mp.weixin.qq.com/s?src=11×tamp=1641019589&ver=3531&signature=QDleVkHGKdsn99TkShz7H1aSOZQ6mww2EyiTlIn3fsIjWKfWt-2DauHjQ*CMEBWpIBgWSPvlAQstK5Ltr1J9sV3OOC0RwTGFDeevEJMD2yh6cc9AtAEn0pj55MbHapQ2&new=1)
3. [Java 集合系列之十：TreeSet 底层原理](https://segmentfault.com/a/1190000021434112)。
4. [Java 集合 --- TreeSet 底层实现和原理（源码解析）](https://www.jianshu.com/p/3b5e2677935d)。
5. [面试官：从源码分析一下 TreeSet（基于 jdk1.8）](https://zhuanlan.zhihu.com/p/84394800)。
6. [java 集合-TreeSet 底层原理](https://juejin.cn/post/6844904071992705037)。

