---
sidebar_position: 2
---

## 1 题目

n 皇后问题 研究的是如何将 n 个皇后放置在 n×n 的棋盘上，并且使皇后彼此之间不能相互攻击。

给你一个整数 n ，返回所有不同的 n 皇后问题 的解决方案。

每一种解法包含一个不同的 n 皇后问题 的棋子放置方案，该方案中 'Q' 和 '.' 分别代表了皇后和空位。

**示例 1：**

![](https://ricear.com/media/202106/2021-06-27_194424.png)

```txt
输入：n = 4
输出：[[".Q..","...Q","Q...","..Q."],["..Q.","Q...","...Q",".Q.."]]
解释：如上图所示，4 皇后问题存在两个不同的解法。
```

**示例 2：**

```txt
输入：n = 1
输出：[["Q"]]
```

**提示：**

* 1 <= n <= 9
* 皇后彼此不能相互攻击，也就是说：任何两个皇后都不能处于同一条横行、纵行或斜线上。

## 2 解题思路

### 2.1 回溯算法

#### 2.1.1 问题分析

1. N 皇后的问题本质上跟[全排列](https://ricear.com/project-21/doc-738)问题差不多，决策树的每一层表示棋盘的每一行，每个节点可以做出的选择是在该行的任意一列放置一个皇后。
2. 函数 `backtrack` 依然像个在决策树上游走的指针，通过 `row` 和 `col` 就可以表示函数遍历到的位置，通过 `isValid` 函数可以将不符合条件的情况进行剪枝。![](https://ricear.com/media/202106/2021-06-27_195120.png)

#### 2.1.2 参考代码

```java
/**
 * 将字符数组转化为字符串
 * @param array 字符数组
 * @return  字符数组对应的字符串
 */
public static String charArrayToString(char[] array) {
    return Arrays.toString(array).replaceAll("[\\[\\]\\s,]", "");
}

/**
 * 判断是否可以在 track[row][col] 放置皇后
 *
 * @param track 路径
 * @param row   行
 * @param col   列
 * @return 是否可以在 track[row][col] 放置皇后
 */
private boolean isValid(ArrayList<String> track, int row, int col) {
    int rowLen = track.size();
    char[] rowArr = track.get(row).toCharArray();

    //  检查所在行是否有冲突
    for (int i = 0; i < rowArr.length; i++) {
        if (i != col && rowArr[i] == 'Q') {
            return false;
        }
    }

    //  检查所在列是否有冲突
    for (int i = 0; i < rowLen; i++) {
        if (i != row && track.get(i).charAt(col) == 'Q') {
            return false;
        }
    }

    //  判断左上角所对应的斜线上是否有冲突
    //  左上
    int rowTemp = row, colTemp = col;
    while (rowTemp >= 0 && colTemp >= 0) {
        if (rowTemp != row && colTemp != col && track.get(rowTemp).charAt(colTemp) == 'Q') {
            return false;
        }
        rowTemp--;
        colTemp--;
    }
    //  右下
    rowTemp = row;
    colTemp = col;
    while (rowTemp < rowLen && colTemp < rowLen) {
        if (rowTemp != row && colTemp != col && track.get(rowTemp).charAt(colTemp) == 'Q') {
            return false;
        }
        rowTemp++;
        colTemp++;
    }

    //  判断右上角所对应的斜线上是否有冲突
    //  右上
    rowTemp = row;
    colTemp = col;
    while (rowTemp >= 0 && colTemp < rowLen) {
        if (rowTemp != row && colTemp != col && track.get(rowTemp).charAt(colTemp) == 'Q') {
            return false;
        }
        rowTemp--;
        colTemp++;
    }
    //  左下
    rowTemp = row;
    colTemp = col;
    while (rowTemp < rowLen && colTemp >= 0) {
        if (rowTemp != row && colTemp != col && track.get(rowTemp).charAt(colTemp) == 'Q') {
            return false;
        }
        rowTemp++;
        colTemp--;
    }

    return true;
}

/**
 * 回溯算法
 * 【路径】：track 中小于 row 的那些行都已经成功放置了皇后
 * 【选择列表】：第 row 行的所有列都是放置皇后的选择
 * 【结束条件】：row 超过 track 的最后一行
 *  @param row
 * @param track
 * @param res
 */
public void backtrack(int row, ArrayList<String> track, List<List<String>> res) {
    //  触发结束条件
    if (row == track.size()) {
        ArrayList<String> trackTemp = new ArrayList<>();
        trackTemp.addAll(track);
        res.add(trackTemp);
        return;
    }

    int rowLen = track.get(row).length();
    for (int col = 0; col < rowLen; col++) {
        //  排除不合法选择
        if (!isValid(track, row, col)) {
            continue;
        }
        //  做选择
        char[] array = track.get(row).toCharArray();
        array[col] = 'Q';
        track.set(row, charArrayToString(array));
        //  进入下一行决策
        backtrack(row + 1, track, res);
        //  撤销选择
        array[col] = '.';
        track.set(row, charArrayToString(array));
    }
}

/**
 * 51. N 皇后
 *
 * @param n 皇后个数
 * @return 所有不同的 n 皇后问题 的棋子放置方案
 */
public List<List<String>> solveNQueens(int n) {
    List<List<String>> res = new ArrayList<>();
    //  初始化棋盘，“.”表示空，“Q”表示皇后
    ArrayList<String> track = new ArrayList<>();
    for (int i = 0; i < n; i++) {
        track.add(String.join("", Collections.nCopies(n, ".")));
    }
    backtrack(0, track, res);
    return res;
}
```

## 参考文献

1. [51. N 皇后](https://leetcode-cn.com/problems/n-queens)。
2. [回溯算法解题套路框架](https://labuladong.gitbook.io/algo/mu-lu-ye-3/mu-lu-ye/hui-su-suan-fa-xiang-jie-xiu-ding-ban)。

