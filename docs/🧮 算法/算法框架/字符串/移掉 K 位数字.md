---
sidebar_position: 6
---

## 1 题目

给你一个以字符串表示的非负整数 num 和一个整数 k ，移除这个数中的 k 位数字，使得剩下的数字最小。请你以字符串形式返回这个最小的数字。
**示例 1 ：**

```txt
输入：num = "1432219", k = 3
输出："1219"
解释：移除掉三个数字 4, 3, 和 2 形成一个新的最小的数字 1219 。
```

**示例 2 ：**

```txt
输入：num = "10200", k = 1
输出："200"
解释：移掉首位的 1 剩下的数字为 200. 注意输出不能有任何前导零。
```

**示例 3 ：**

```txt
输入：num = "10", k = 2
输出："0"
解释：从原数字移除所有的数字，剩余为空就是 0 。
```

**提示：**

* 1 <= k <= num.length <= 105
* num 仅由若干位数字（0 - 9）组成
* 除了 0 本身之外，num 不含任何前导零

## 2 问题分析

1. 这道题让我们**从一个字符串数字中删除 $k$ 个数字**，**使得剩下的数最小**，其中一个思路是：

   1. **从左到右遍历**。
   2. **对于遍历到的元素**，**我们选择保留**。
   3. **但是我们可以选择性丢弃前面相邻的元素**，**丢弃与否的依据是**：

      1. 对于两个数 123a456 和 123b456，如果 $a \gt b$，那么数字 123a456 大于数字 123b456，否则数字 123a456 小于等于数字 123b456。
      2. 也就是说，两个相同位数的数字大小关系取决于第一个不同的数的大小。
   4. 具体过程如下：

      1. 假如 $num = 1432219$，$k = 3$。
      2. 开始的时候遍历到的元素是 1，由于没有左侧相邻元素，因此没办法丢弃。

         ![](https://notebook.grayson.top/media/202206/2022-06-09_161031_494584.png)
      3. 接下来遍历到的是 4，由于 4 比左侧相邻的 1 大，如果选择丢弃左侧的 1，那么会使得剩下的数字更大，因此我们仍然选择不丢弃。

         ![](https://notebook.grayson.top/media/202206/2022-06-09_161059_488014.png)

         ![](https://notebook.grayson.top/media/202206/2022-06-09_161254_964943.png)
      4. 接下来遍历到的元素是 3，由于 3 比左侧相邻的 4 小，如果选择丢弃左侧的 4，那么会使得剩下的数字更小，因此我们选择丢弃。

      ![](https://notebook.grayson.top/media/202206/2022-06-09_161341_107625.png)

      ![](https://notebook.grayson.top/media/202206/2022-06-09_161349_030894.png)

      ![](https://notebook.grayson.top/media/202206/2022-06-09_161401_918565.png)

      ![](https://notebook.grayson.top/media/202206/2022-06-09_161410_717517.png)
      6. 后面的思路类似，我们就不继续分析了。
   5. 然而需要注意的是，**如果给定的数字是一个单调递增的数字**，**那么我们的算法会永远选择不丢弃**，与题目中要求的永远确保丢弃 $k$ 个相矛盾，一个简单的思路就是：

      1. **每丢弃一次**，$k$**减去 1**，**当 $k$ 减到 0**，**我们可以提前终止遍历**。
      2. **当遍历完成**，**如果 $k$ 仍然大于 0**，**假设最终还剩下 $x$ 个需要丢弃**，**那么我们需要选择删除末尾 $x$ 个元素**。
   6. 上面的思路可行，但是稍显复杂，我们需要把思路逆转过来，**刚才我们的关注点一直是丢弃**，**题目要求我们丢弃 $k$ 个元素**，反过来说，就是**让我们保留 $n - k$ 个元素**，**其中 $n$ 为数字长度**，那么我们只需要**按照上面的方法遍历完成后**，**再截取前 $n - k$ 个元素即可**。
   7. **按照上面的思路**，**我们来选择数据结构**，**由于我们需要保留和丢弃相邻的元素**，**因此使用栈这种在一端进行添加和删除的数据结构**。

   ![](https://notebook.grayson.top/media/202206/2022-06-09_161730_605002.gif)

## 3 参考代码

```java
/**
 * 402. 移掉 K 位数字
 * @param num   字符串表示的非负整数
 * @param k 移除数字的个数
 * @return  移除指定个数后的最小数字
 */
public String removeKdigits(String num, int k) {
    //  存储未移除的数字
    Stack<Integer> stack = new Stack<>();
    //  存储栈中未移除的数字
    StringBuilder sb = new StringBuilder();
    //  最后保留的数字的个数
    int remain = num.length() - k;
    //  最后结果
    String res;

    for (int i = 0; i < num.length(); i++) {
        int item = num.charAt(i) - '0';
        while (k > 0 && stack.size() > 0 && stack.peek() > item) {
            //  将栈中大于当前数字的数字移除
            stack.pop();
            //  k 减 1
            k--;
        }
        stack.push(item);
    }
    //  获取最后结果
    while (stack.size() > 0) {
        sb.append(stack.pop());
    }
    //  replaceFirst("^0*", "") 表示去除数字的前导 0
    res = sb.reverse().substring(0, remain).replaceFirst("^0*", "");

    //  返回最后结果
    return res.equals("") ? "0" : res;
}
```

## 4 相关题目

### 4.1 [去除重复字母](https://leetcode-cn.com/problems/remove-duplicate-letters)

#### 4.1.1 题目

给你一个字符串 s ，请你去除字符串中重复的字母，使得每个字母只出现一次。需保证 返回结果的字典序最小（要求不能打乱其他字符的相对位置）。

**示例 1：**

```txt
输入：s = "bcabc"
输出："abc"
```

**示例 2：**

```txt
输入：s = "cbacdcbc"
输出："acdb"
```

**提示：**

* 1 <= s.length <= 104
* s 由小写英文字母组成

#### 4.1.2 问题分析

1. 与[移掉 K 位数字](#2-问题分析)不同，这道题没有一个全局的删除次数 $k$，而是**对于每一个在字符串 $s$ 中出现的字母 $c$ 都有一个 $k$ 值**，**这个 $k$ 是 $c$ 出现的次数减 1**。
2. 沿用上面的知识，我们要做的就是**计算每一个字符的 $k$**，具体的算法如下：
   1. **建立一个字典**，**其中 $k$ 为字符 $c$**，$value$**为其出现的剩余次数**。
   2. **从左往右遍历字符串**，**每次遍历到一个字符**，**其剩余出现次数减 1**。
   3. **对于每一个字符**，**如果其对应的剩余出现次数大于 1**，**我们可以选择丢弃**，**否则不可以丢弃**。
   4. **是否丢弃的标准和[上面题目](#2-问题分析)类似**，**如果栈中相邻的元素字典序更大**，**那么我们选择丢弃相邻的栈中的元素**。

      ![](https://notebook.grayson.top/media/202206/2022-06-09_174914_549301.gif)

#### 4.1.3 参考代码

```java
/**
 * 316. 去除重复字母
 * @param s 源字符串
 * @return  去除重复字母且返回结果的字典序最小的字符串
 */
public String removeDuplicateLetters(String s) {
    //  字符与其对应出现的剩余次数的映射
    HashMap<Character, Integer> map = new HashMap<>();
    //  字符是否在最后结果中出现
    HashSet<Character> seen = new HashSet<>();
    //  存储临时结果
    Stack<Character> stack = new Stack<>();
    //  存储栈中反转后的结果
    StringBuilder sb = new StringBuilder();
    //  最后结果
    String res;

    //  遍历字符串，获取字符与其对应出现的剩余次数的映射
    for (int i = 0; i < s.length(); i++) {
        char item = s.charAt(i);
        if (!map.containsKey(item)) {map.put(item, 1);}
        else {map.put(item, map.get(item) + 1);}
    }

    for (int i = 0; i < s.length(); i++) {
        char item = s.charAt(i);
        if (!seen.contains(item)) {
            //  当前字符未出现在 stack 中
            while (stack.size() > 0 && stack.peek() > item && map.get(stack.peek()) > 0) {
                //  将栈中剩余出现次数大于 0 且 大于当前字符的元素移除
                char temp = stack.pop();
                seen.remove(temp);
            }
            //  将当前字符添加到 seen 中
            seen.add(item);
            //  将当前字符添加到 stack 中
            stack.push(item);
        }
        //  将当前字符的剩余出现次数减 1
        map.put(item, map.get(item) - 1);
    }

    //  获取最后结果
    while (stack.size() > 0) {
        sb.append(stack.pop());
    }
    res = sb.reverse().toString();

    //  返回最后结果
    return res;
}
```

### 4.2 [拼接最大数](https://leetcode-cn.com/problems/create-maximum-number)

#### 4.2.1 问题分析

1. 和[移掉 K 位数字](#2-问题分析)类似，只不过这一次是**两个数组**，而不是一个，并且是**求最大数**。
2. **最大最小是无关紧要的**，**关键在于是两个数组**，**并且要求从两个数组选取的元素个数加起来一共是 $k$**。
3. 然而**在一个数组中取 $k$ 个数字**，**并保持最小**，我们已经会了，但是如果问题扩展到两个，会有什么变化呢，实际上，问题本质并没有发生变化：
   1. 假设我们从 $nums_1$ 中取了 $k_1$ 个，从 $nums_2$ 中取了 $k_2$ 个，其中 $k_1 + k_2 = k$。
   2. 而 $k_1、k_2$ 这两个子问题我们是会解决的，由于这两个问题是相互独立的，因此我们只需要**分别求解**，**然后将结果合并**即可。
   3. 以题目中的 $nums_1 = [3, 4, 5, 6] \space nums_2 = [9, 1, 2, 5, 8, 3] \space k = 5$ 为例：
      1. 假如我们从 $nums_1$ 中取出 1 个数字，那么就要从 $nums_2$ 中取出 4 个数字。
      2. 运用[移掉 K 位数字](#2-问题分析)中的方法，我们计算出应该取 $nums_1$ 中的 $[6]$，并取 $nums_2$ 中的 $[9, 5, 8, 3]$。
      3. 如何将 $[6]$ 和 $[9, 5, 8, 3]$ 合并，使得数字尽可能大，并且保持相对位置不变呢，实际上这个过程有点类似[归并排序](https://notebook.grayson.top/project-21/doc-872/#7-%E5%BD%92%E5%B9%B6%E6%8E%92%E5%BA%8F)中的治，而上面我们分别计算 $nums_1$ 和 $nums_2$ 的最大数的过程类似[归并排序](https://notebook.grayson.top/project-21/doc-872/#7-%E5%BD%92%E5%B9%B6%E6%8E%92%E5%BA%8F)中的分。

         ![](https://notebook.grayson.top/media/202202/2022-02-07_2219140.1347819552753512.png)

## 参考文献

1. [402. 移掉 K 位数字](https://leetcode-cn.com/problems/remove-k-digits)。
2. [一招吃遍力扣四道题，妈妈再也不用担心我被套路啦 ～](https://leetcode-cn.com/problems/remove-k-digits/solution/yi-zhao-chi-bian-li-kou-si-dao-ti-ma-ma-zai-ye-b-5)。
3. [316. 去除重复字母](https://leetcode-cn.com/problems/remove-duplicate-letters)。
4. [321. 拼接最大数](https://leetcode-cn.com/problems/create-maximum-number)。
