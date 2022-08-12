---
sidebar_position: 1
---

> 记得自己以前一直在[Leetcode](https://leetcode-cn.com)上刷题，只需要自己写方法的具体逻辑，不用考虑输入输出的问题，直到第一次面试字节的时候才知道原来有的面试是使用的一块白板，程序的输入、输出，甚至导包都需要自己来写，因此结果可想而知 😭，因此决定对[牛客网](https://www.nowcoder.com)上常见的输入输出进行总结，避免在面试的时候再次踩雷 💣，让自己可以更加专注于具体的逻辑，提升自己面试通过的概率 😉。

> 大家在熟悉了下面的输入输出模板后可以使用[OJ 在线编程常见输入输出练习场](https://ac.nowcoder.com/acm/contest/5652)来进行练习。

## 1 典型实例

### 1.1 输入是已知大小的数组

> 第一行是一个整数 $n$，表示二维数组有 $n$ 行 $n$ 列。

**Java**：

```java
import java.util.Scanner;

Scanner scan = new Scanner(System.in);
int n = scan.nextInt();
int[][] arr = new int[n][n];
for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
        arr[i][j] = scan.nextInt();
    }
}
```

### 1.2 输入的每组测试数据有多行的情况

> 第一行是一个正整数 $m$，表示有 $m$ 组测试数据，之后每组数据有三行，第一行为 $n$（$ 1 \le n \le 10000 $），第二行有 $n$ 个正整数，第三行也有 $n$ 个正整数，都在整数范围内。

> 示例：
> 3
> 3
> 1 2 3
> 1 2 3
> 4
> 4 3 2 1
> 1 1 1 1
> 2
> 1 2
> 10 20

```java
import java.util.Arrays;
import java.util.Scanner;

Scanner scan = new Scanner(System.in);
int m = scan.nextInt();
while (m > 0) {
    m--;
    int n = scan.nextInt();;
    int[] a = new int[n];
    int[] b = new int[n];
    for (int i = 0; i < n; i++) {
        a[i] = scan.nextInt();
    }
    for (int i = 0; i < n; i++) {
        b[i] = scan.nextInt();
    }
    System.out.println(Arrays.toString(a));
    System.out.println(Arrays.toString(b));
}
```

### 1.3 每行测试数据的数量在该行开头给出

> 第一行是一个正整数 $m$，表示有 $m$ 组测试数据，之后每组数据第一个数为 $n$（$ 1 \le n \le 10000 $），紧接着有 $n$ 个正整数（注意在一行）。

> 示例：
> 2
> 3123
> 41234

```java
import java.util.Arrays;
import java.util.Scanner;

Scanner scan = new Scanner(System.in);
int m = scan.nextInt();
while (m > 0) {
    m--;
    String s = scan.next();
    int n = s.charAt(0) - '0';
    int[] arr = new int[n];
    for (int i = 0; i < n; i++) {
        arr[i] = s.charAt(i + 1) - '0';
    }
    System.out.println(Arrays.toString(arr));
}
```

### 1.4 测试数据组数未知

> 输入数据有多组，每行表示一组输入数据，每行不定有 $n$ 个整数，用空格隔开。

```java
import java.util.Scanner;

Scanner scan = new Scanner(System.in);
while (scan.hasNextLine()) {
    String s = scan.nextLine();
    String[] arr = s.split(" ");
    int sum = 0;
    for (int i = 0; i < arr.length; i++) {
        sum += Integer.parseInt(arr[i]);
    }
    System.out.println(sum);
}
```

## 2 注意事项

### 2.1 Java 中 next()、nextInt()和 nextLine()的用法及区别

1. `next()`、`nextInt()` 和 `nextLine()` 都是 Scanner 内置的方法，他们的区别主要在于对于**空格的处理方式**及**返回值**的不同：
   1. **空格的处理方式**：
      1. `next()` 和 `nextInt()`**遇到空格时会停止读取**，返回的结果为**空格前读取的部分**。
      2. `nextLine()`**从指针的当前位置开始读取**，**遇到换行符时会停止读取**，返回**换行符前读取的部分**。
   2. **返回值**：
      1. `next()` 和 `nextLine()` 的返回值为 `String` 类型。
      2. `nextInt()` 的返回值为 `int` 类型。

## 参考文献

1. [牛客网编程 OJ 的典型输入 Java 模板](https://www.cnblogs.com/treasury/p/13285997.html)
2. [java 中 next()，nextInt()，nextLine()的用法及区别](https://blog.csdn.net/qq_45445841/article/details/104824176)
