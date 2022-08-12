---
sidebar_position: 4
---

## 1 题目

给你一个字符串表达式 s ，请你实现一个基本计算器来计算并返回它的值。

整数除法仅保留整数部分。

**示例 1：**

```txt
输入：s = "3+2*2"
输出：7
```

**示例 2：**

```txt
输入：s = " 3/2 "
输出：1
```

**示例 3：**

```txt
输入：s = " 3+5 / 2 "
输出：5
```

**提示：**

* 1 <= s.length <= 3 * 105
* s 由整数和算符 ('+', '-', '*', '/') 组成，中间由一些空格隔开
* s 表示一个 有效表达式
* 表达式中的所有整数都是非负整数，且在范围 [0, 231 - 1] 内
* 题目数据保证答案是一个 32-bit 整数
* 通过次数 90,862 提交次数 207,522

> 类似的题目还有：
>
> 1. [224. 基本计算器](https://leetcode-cn.com/problems/basic-calculator)。

## 2 问题分析

1. 对于【任何表达式】而言，我们**都使用两个栈** `nums`**和 `ops`**：
   1. `nums`：**存放所有的数字**。
   2. `ops`：**存放所有的数字以外的操作**。
2. 然后**从前往后做**，**对遍历到的字符做分情况讨论**：
   1. **空格**：**跳过**。
   2. `(`：**直接加入 `ops` 中**，**等待与之匹配的 `)`**。
   3. `)`：**使用现有的 `nums` 和 `ops` 进行计算**，**直到遇到左边最近的一个左括号为止**，**计算结果放到 `nums`**。
   4. **数字**：**从当前位置开始继续往后取**，**将一个连续数字整体取出**，**加入 `nums`**。
   5. `+ - * / ^ %`：**需要将操作放入 `ops` 中**，**在放入之前先把栈内可以算的都算掉**（**只有【栈内运算符】比【当前运算符】优先级高/同等**，**才进行运算**），**使用现有的 `nums` 和 `ops` 进行计算**，**直到没有操作或者遇到左括号**，**计算结果放到 `nums`**。
3. 【栈内运算符】比【当前运算符】优先级高/同等，才进行运算的含义：
   1. 因为我们是**从前往后做的**，假设我们**当前已经扫描到 `2 + 1` 了**，此时**栈内的操作为 `+`**：
      1. **如果后面出现的 `+ 2` 或者 `- 1` 的话**，**满足【栈内运算符】比【当前运算符】优先级高/同等**，**可以将 `2 + 1` 算掉**，**把结果放到 `nums` 中**。
      2. **如果后面出现的是 `* 2` 或者 `/ 1` 的话**，**不满足【栈内运算符】比【当前运算符】优先级高/同等**，**这时候不能计算 `2 + 1`**。
4. 一些细节：
   1. **由于第一个数可能是负数**，**为了减少边界判断**，**一个小技巧是先往 `nums` 添加一个 0**。
   2. **为防止 `()` 内出现的首个字符为运算符**，**将所有的空格去掉**，**并将 `(-` 替换为 `(0-`**，`(+`**替换为 `(0+`**。
   3. **从理论上分析**，`nums`**最好存放的是 `long`**，**而不是 `int`**，**因为可能存在 `大数 + 大数 + 大数 + ... - 大数 - 大数` 的表达式导致中间结果溢出**，**最终答案不溢出的情况**。

## 3 参考代码

```java
Map<Character, Integer> map = new HashMap() {{
        put('+', 1);
        put('-', 1);
        put('*', 2);
        put('/', 2);
        put('%', 2);
        put('^', 3);
    }};

    /**
     * 227. 基本计算器 II
     * @param s 字符串
     * @return  字符串表达式计算后返回的值
     */
    public int calculate(String s) {
        //  将所有的空格去掉
        s = s.replaceAll(" ", "");
        char[] cs = s.toCharArray();
        int n = s.length();
        //  存放所有的数字
        Deque<Integer> nums = new ArrayDeque<>();
        //  为了防止第一个数为负数，先往 nums 加个 0
        nums.addLast(0);
        //  存放所有【非数字以外】的操作
        Deque<Character> ops = new ArrayDeque<>();

        for (int i = 0; i < n; i++) {
            char c = cs[i];
            if (c == '(') {ops.addLast(c);}
            else if (c == ')') {
                while (!ops.isEmpty()) {
                    if (ops.peekLast() != '(') {calc(nums, ops);}
                    else {
                        ops.pollLast();
                        break;
                    }
                }
            } else {
                if (isNumber(c)) {
                    int u = 0, j = i;
                    //  将从 i 开始后面的连续数字整体取出，加入 nums
                    while (j < n && isNumber(cs[j])) {u = u * 10 + (cs[j++] - '0');}
                    nums.addLast(u);
                    i = j - 1;
                } else {
                    if (i > 0 && (cs[i - 1] == '(' || cs[i - 1] == '+' || cs[i - 1] == '-')) {nums.addLast(0);}
                    //  有一个新操作要入栈时，先把栈内可以算的都算了
                    //  只有满足【栈内运算符】比【当前运算符】优先级高/同等，才进行运算
                    while (!ops.isEmpty() && ops.peekLast() != '(') {
                        char prev = ops.peekLast();
                        if (map.get(prev) >= map.get(c)) {calc(nums, ops);}
                        else {break;}
                    }
                    ops.addLast(c);
                }
            }
        }

        //  将剩余的计算完
        while (!ops.isEmpty()) {calc(nums, ops);}

        //  返回最后的计算结果
        return nums.peekLast();
    }

    /**
     * 模拟计算器计算
     * @param nums  数值队列
     * @param ops   操作队列
     */
    void calc(Deque<Integer> nums, Deque<Character> ops) {
        if (nums.isEmpty() || nums.size() < 2) {return;}
        if (ops.isEmpty()) {return;}
        int b = nums.pollLast(), a = nums.pollLast();
        char op = ops.pollLast();
        int ans = 0;

        if (op == '+') {ans = a + b;}
        else if (op == '-') {ans = a - b;}
        else if (op == '*') {ans = a * b;}
        else if (op == '/') {ans = a / b;}
        else if (op == '%') {ans = a % b;}
        else if (op == '^') {ans = (int) Math.pow(a, b);}

        nums.addLast(ans);
    }

    /**
     * 判断一个字符是否是数字
     * @param c 字符
     * @return  字符是否是数字
     */
    boolean isNumber(char c) {return Character.isDigit(c);}
```

## 参考文献

1. [227. 基本计算器 II](https://leetcode-cn.com/problems/basic-calculator-ii)。
2. [【宫水三叶】使用「双栈」解决「究极表达式计算」问题](https://leetcode-cn.com/problems/basic-calculator-ii/solution/shi-yong-shuang-zhan-jie-jue-jiu-ji-biao-c65k)。
3. [224. 基本计算器](https://leetcode-cn.com/problems/basic-calculator)。
