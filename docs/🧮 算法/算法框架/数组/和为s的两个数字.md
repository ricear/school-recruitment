---
sidebar_position: 7
---

## 1 题目

输入一个递增排序的数组和一个数字 s，在数组中查找两个数，使得它们的和正好是 s。如果有多对数字的和等于 s，则输出任意一对即可。

**示例 1：**

```txt
输入：nums = [2,7,11,15], target = 9
输出：[2,7] 或者 [7,2]
```

**示例 2：**

```txt
输入：nums = [10,26,30,31,47,60], target = 40
输出：[10,30] 或者 [30,10]
```

**限制：**

* 1 <= nums.length <= 10^5
* 1 <= nums[i] <= 10^6

## 2 问题分析

1. 本题**利用 `HashMap` 可以通过遍历数组找到数字组合**，**时间和空间复杂度均为 $O(N)$**，因为**本题的 $nums$ 是排序数组**，**因此可使用双指针法将空间复杂度降低至 $O(1)$**。
2. 具体的算法流程如下：
   1. **初始化**：

      1. **双指针 $i, j$ 分别指向数组 $nums$ 的左右两端**。
   2. **循环搜索**：

      1. **计算和 $s = nums[i] + nums[j]$**。
      2. **比较 $s$ 和 $target$ 的值**：
         1. **若 $s \lt target$**，**则指针 $i$ 向右移动**，**即 $i++$**。
         2. **若 $s \gt target$**，**则指针 $j$ 向左移动**，**即 $j--$**。
         3. **若 $s = target$**，**则返回数组 $[nums[i], nums[j]]$**。
      3. **返回空数组**，**代表无和为 $target$ 的数字组合**。

      ![](https://notebook.grayson.top/media/202206/2022-06-03_151853_433534.png)

## 3 参考代码

```java
/**
 * 剑指 Offer 57. 和为 s 的两个数字
 * @param nums  递增排序树组
 * @param target    目标和
 * @return  和为 target 的两个数字
 */
public int[] twoSum(int[] nums, int target) {
    int i = 0, j = nums.length - 1;
    while (i < j) {
        int s = nums[i] + nums[j];
        if (s < target) {i++;}
        else if (s > target) {j--;}
        else if (s == target) {return new int[]{nums[i], nums[j]};}
    }
    return new int[]{};
}
```

## 4 扩展题目

### 4.1 [和为 s 的连续正数序列](https://leetcode-cn.com/problems/he-wei-sde-lian-xu-zheng-shu-xu-lie-lcof)

#### 4.1.1 问题分析

1. **滑动窗口可以看成数组中框起来的一部分**，**在一些数组类题目中**，**我们可以用滑动窗口来观察可能的候选结果**，**当滑动窗口从数组的左边滑到了右边**，**我们就可以从所有的候选结果中找到最优的结果**。
2. **对于这道题来说**，**数组就是正整数序列**$[1, 2, 3,..., n]$，**我们设滑动窗口的左边界为 $i$**，**右边界为 $j$**，**则滑动窗口框起来的是一个左闭右闭区间 $[i, j]$**：
   1. **在一开始**，$i = 1, j = 1$，**滑动窗口位于序列的最左侧**，**窗口大小为 0**。
   2. **然后比较滑动窗口中所有数的和 $sum$ 和目标和 $sum$ 的大小**：
      1. **如果 $sum \lt target$**，**滑动窗口的右边界向右移动**，**即 $j++$**，**此时窗口中多了一个数字 $j$**，**窗口的和 $sum$ 也要加上 $j$**。
      2. **如果 $sum \gt target$**，**滑动窗口的左边界向右移动**，**即 $i++$**，**此时窗口中少了一个数字 $i$**，**窗口的和 $sum$ 也要减去 $i$**。
      3. **如果 $sum = target$**，**我们需要记录此时的结果**，**然后将窗口的右边界向右移动**。

         ![](https://notebook.grayson.top/media/202206/2022-06-03_151942_977167.png)

#### 4.1.2 参考代码

```java
/**
 * 剑指 Offer 57 - II. 和为 s 的连续正数序列
 * @param target    目标和
 * @return  所有和为 target 的连续正整数序列
 */
public int[][] findContinuousSequence(int target) {
    //  滑动窗口的左右边界及滑动窗口内的元素和
    int i = 1, j = 1, sum = 1;
    List<int[]> res = new ArrayList<>();

    while (i <= target / 2) {
        if (sum < target) {
            //  如果滑动窗口内的元素和小于目标和，则将右边界向右滑动，同时将滑动窗口内的元素和加上新添加的右边界元素
            j++;
            sum += j;
        }
        else if (sum > target) {
            //  如果滑动窗口内的元素和大于目标和，则将滑动窗口内的元素和减去要移除的左边界元素，同时将左边界向右滑动
            sum -= i;
            i++;
        }
        else if (sum == target) {
            //  如果滑动窗口内的元素和等于目标和，则将滑动窗口内的元素放到数组中，然后合并到最终结果中
            int[] tmp = new int[j - i + 1];
            for (int k = i; k <= j; k++) {
                tmp[k - i] = k;
            }
            res.add(tmp);
            j++;
            sum += j;
        }
    }

    //  将最终结果变换后返回
    return res.toArray(new int[res.size()][]);
}
```

## 参考文献

1. [剑指 Offer 57. 和为 s 的两个数字](https://leetcode-cn.com/problems/he-wei-sde-liang-ge-shu-zi-lcof)。
2. [面试题 57. 和为 s 的两个数字（双指针 + 证明，清晰图解）](https://leetcode-cn.com/problems/he-wei-sde-liang-ge-shu-zi-lcof/solution/mian-shi-ti-57-he-wei-s-de-liang-ge-shu-zi-shuang-)。
3. [剑指 Offer 57 - II. 和为 s 的连续正数序列](https://leetcode-cn.com/problems/he-wei-sde-lian-xu-zheng-shu-xu-lie-lcof)。
4. [什么是滑动窗口，以及如何用滑动窗口解这道题（C++/Java/Python）](https://leetcode-cn.com/problems/he-wei-sde-lian-xu-zheng-shu-xu-lie-lcof/solution/shi-yao-shi-hua-dong-chuang-kou-yi-ji-ru-he-yong-h)。
