---
sidebar_position: 13
---

## 题目

> 题目来源：[69. x 的平方根](https://leetcode-cn.com/problems/sqrtx)。

实现 int sqrt(int x) 函数。

计算并返回 x 的平方根，其中 x 是非负整数。

由于返回类型是整数，结果只保留整数的部分，小数部分将被舍去。

**示例 1:**

```txt
输入: 4
输出: 2
```

**示例 2:**

```txt
输入: 8
输出: 2
说明: 8 的平方根是 2.82842...,
     由于返回类型是整数，小数部分将被舍去。
```

## 解题思路

### 二分查找法

#### 问题分析

1. 题目实际上是找到一个数 $num$ 使得：
   
   $$
   num * num \le x
   $$
   
   并且
   
   $$
   (num + 1) * (num + 1) \gt x
   $$
   
   而这个数一定不大于 $\frac12 x$。
2. 因此题目实际上可以看做查找一个 $num \in [1, \frac12 x]$ 符合上述条件，因此可以采用二分法来进行查找。

#### 参考代码

```java
/**
 * 69. x 的平方根
 * @param x 待求整数
 * @return  x 的平方根的整数部分
 */
public int sqrt(int x) {
    if (x == 1) {return 1;}
    int left = 1, right = x / 2, res = 0;
    while(left <= right) {
        int mid = left + (right - left) / 2;
        if ((long)mid * mid <= x) {
            res = mid;
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }
    return  res;
}
```

### 牛顿迭代法

#### 问题分析

1. 牛顿迭代法是一种可以用来快速求解函数零点的方法。
2. 为了叙述方便，我们用 $C$ 表示待求出平方根的那个整数，显然，$C$ 的平方根就是函数
   
   $$
   y = f(x) = x^2 - C
   $$
   
   的零点。
3. 牛顿迭代法的本质是借助泰勒级数，从初始值快速向零点逼近：
   
   1. 我们任取一个 $x_0$ 作为初始值，在每一步的迭代中，我们找到函数图像上的点 $(x_i, f(x_i))$，过该点做一条斜率为该点导数 $f^{'}(x_i)$ 的直线，与横轴的交点记为 $x_{i + 1}$，$x_{i + 1}$ 相较于 $x_i$ 而言距离零点更近。
   2. 在经过多次迭代后，我们就可以得到一个距离零点非常接近的交点，下图给出了从 $x_0$ 开始迭代两次，得到 $x_1$ 和 $x_2$ 的过程。
      
      ![fig1](https://notebook.ricear.com/media/202107/2021-07-11_1944290.35472416583845645.png)
4. 我们选择 $x_0 = C$ 作为初始值，在每一步迭代中，我们通过当前交点 $x_i$，找到图像上的点 $(x_i, x_i^2 - C)$，作一条斜率为 $f^{'}(x_i) = 2x_i$ 的直线，直线的方程为
   
   $$
   y - (x_i^2 - C) = 2x_i(x - x_i)
   $$
   
   化简后得
   
   $$
   y = 2x_ix - (x_i^2 + C)
   $$
   
   与横轴的交点为方程
   
   $$
   2x_ix - (x_i^2 + C) = 0
   $$
   
   的解，即为新的迭代结果 $x_{i + 1}$：
   
   $$
   x_{i + 1} = \frac12 (x_i + \frac{C}{x_i})
   $$
   
   在进行 $k$ 次迭代后，$x_k$ 的值与真实的零点 $\sqrt C$ 足够接近，即可作为答案。

> 🤔 为什么选择 $ x_0 = C $ 作为初始值？
> 因为 $y = x^2 - C$ 有两个零点 $-\sqrt C$ 和 $\sqrt C$，如果我们取得初始值较小，可能会迭代到 $-\sqrt C$ 这个零点，而我们希望找到的是 $\sqrt C$ 这个零点，因此选择 $x_0 = C$ 作为初始值，每次迭代均有 $x_{i + 1} < x_i$，零点 $\sqrt C$ 在其左侧，所以我们一定会迭代到这个零点。

> 🤔 迭代到何时才算结束？
> 每一次迭代后，我们都会距离零点更进一步，所以当相邻两次迭代得到的交点非常接近时，我们就可以断定，此时的结果已经足够我们得到答案了，一般来说，可以判断相邻两次迭代的结果的差值是否小于一个极小的非负数 $\varepsilon$，其中 $\varepsilon$ 一般可以取 $ 10^{-6} $ 或 $ 10^{-7} $。

> 💁 牛队迭代法也适用于 『精确到多少位小数』或者『误差不小于 0.001』的情况。

#### 参考代码

```java
/**
 * 69. x 的平方根（版本 4：牛顿迭代法）
 * @param x 待求整数
 * @return  x 的平方根的整数部分
 */
public int sqrt(int x) {
    if (x == 0) {return 0;}
    double x0 = (double)x, x1;
    while (true) {
        x1 = 0.5 * (x0 + x / x0);
        if (x0 - x1 <= 1e-7) {break;}
        x0 = x1;
    }
    return (int)x1;
}
```

## 参考文献

1. [x 的平方根](https://leetcode-cn.com/problems/sqrtx/solution/x-de-ping-fang-gen-by-leetcode-solution)。

