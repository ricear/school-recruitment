---
sidebar_position: 6
---

> 欲知其然，必先知其所以然，在介绍 TCP 如何保证传输的可靠性之前，我们先介绍一下可靠传输的工作原理，让大家可以对 TCP 的可靠性传输有一个更为深入而全面的认识。

## 1 可靠传输的工作原理

1. 我们知道，**TCP 发送的报文段是交给 IP 层传送的**，但**IP 层只能提供尽最大努力服务**，也就是说，**TCP 下面的网络所提供的是不可靠的传输**，因此，TCP 必须采用适当的措施才能使得两个传输层之间的通信变得可靠。
2. 理想的传输条件有以下两个特点：

   1. **传输信道不产生差错**。
   2. **不管发送方以多快的速度发送数据**，**接收方总是来得及处理收到的数据**。

   在上面的理想传输条件下，不需要采取任何措施就能够实现可靠传输。
3. 然而实际的网络都不具备以上两个理想条件，但我们可以**使用一些可靠传输协议**，**当出现差错时让发送方重传出现差错的数据**，同时**在接收方来不及处理收到的数据时**，**及时告诉发送方适当降低发送数据的速度**，这样一来，本来不可靠的传输信道就能够实现可靠传输了，可靠传输协议主要有两种，分别为：

   1. **停止等待协议**（Stop and Wait Protocol）。
   2. **滑动窗口协议**（Sliding Window Protocol）。
   3. **连续 ARQ 协议**（Continous Automatic Repeat reQuest Protocol）。

### 1.1 停止等待协议

> 全双工通信的双方既是发送方也是接收方，下面为了讨论问题的方便，我们仅考虑 $A$**发送数据而 $B$ 接收数据并发送确认**，因此 $A$**叫做发送方**，而 $B$**叫做接收方**。

> **传输层传送的协议数据单元叫做报文段**，**网络层传送的协议数据单元叫做 IP 数据报**，但在讨论一般问题时，都可把他们简称为**分组**

> 停止等待就是**每发送完一个分组就停止发送**，**等待对方的确认**，**在收到确认后再发送下一个分组**。

> 在计算机网络发展初期，通信链路不太可靠，因此**在链路层传送数据时都要采用可靠的通信协议**，其中最简单的协议就是这种**停止等待协议**，**在传输层并不使用这种协议**，这里只是**为了引出可靠传输的问题才从最简单的概念讲起**，**在传输层使用可靠传输协议要复杂的多**，后面会进行详细阐述。

1. **无差错情况**
   ![](https://notebook.ricear.com/media/202206/2022-06-16_210554_113489.png)

   1. 停止等待协议可用上图来说明，其中图(a)是最简单的无差错情况，$A$**发送分组**$M_1$，**发完就暂停发送**，**等待 $B$ 的确认**，$B$**收到了 $M_1$ 就向 $A$ 发送确认**，$A$**在收到了对 $M_1$ 的确认后**，**就再发送下一个分组 $M_2$**，同样，**在收到 $B$ 对 $M_2$ 的确认后**，**再发送 $M_3$**。
2. **出现差错**

   1. 上图(b)是分组在传输过程中出现差错的情况，$B$**收到 $M_1$ 时检测出了差错**，**就丢弃 $M_1$**，**其他什么也不做**（不通知 $A$ 收到有差错的分组），也可能是 $M_1$**在传输过程中丢失了**，这时 $B$**当然什么也不知道**，在这两种情况下，$B$**都不会发送任何信息**。
   2. 可靠传输协议是这样设计的：
      1. $A$**只要超过了一段时间仍然没有收到确认**，**就认为刚才发送的分组丢失了**，**因而重传前面发送过的分组**，这就叫[超时重传](#2-超时重传)。
      2. 要实现超时重传，就要**在每发送完一个分组时设置一个超时计时器**，**如果在超时计时器到期之前收到了对方的确认**，**就撤销已设置的超时计时器**。
   3. 可靠传输协议需要注意以下三点：
      1. 第一，$A$**在发送完一个分组后**，**必须暂时保留已发送的分组的副本**（在发生超时重传时使用），**只有在收到相应的确认后才能清除暂时保留的分组副本**。
      2. 第二，**分组和确认分组都必须进行编号**，**这样才能明确是哪一个发送出去的分组收到了确认**，**而哪一个分组还没有收到确认**。
      3. 第三，**超时计时器设置的重传时间应当比数据在分组传输的平均往返时间更长一些**，上图(b)中的一段虚线表示如果 $M_1$ 正确到达 $B$ 同时 $A$ 也正确收到确认的过程，可见重传时间应设定为比平均往返时间更长一些，显然，如果重传时间设定的很长，那么通信的效率就会很低，但如果重传时间设定的太短，以致产生不必要的重传，就浪费了网络资源，然而，在传输层重传时间的准确设定是非常复杂的，这是因为已发出的分组到底会经过哪些网络，以及这些网络将会产生多大的时延（这取决于这些网络当时的拥塞情况），这些都是不确定因素，在上图(b)中把往返时间当做固定的（这并不符合网络的实际情况），只是为了讲述原理的方便，关于重传时间应如何选择，可参考[往返时间测量](#2-1-往返时间测量)。
3. **确认丢失和确认迟到**
   ![](https://notebook.ricear.com/media/202206/2022-06-16_214711_707989.png)

   1. 上图(a)说明的是另一种情况，$B$**所发送的对 $M_1$ 的确认丢失了**，$A$**在设定的超时重传时间内没有收到确认**，**并无法知道是自己发送的分组出错**、**丢失或者是 $B$ 发送的确认丢失了**，因此 $A$**在超时计时器到期后就要重传 $M_1$**。
   2. **假定 $B$ 又收到了重传的分组 $M_1$**，这时应采取两个行动：
      1. 第一，**丢弃这个重复的分组 $M_1$**，**不向上层交付**。
      2. 第二，**向 $A$ 发送确认**，**不能认为已经发送过确认就不再发送**，因为 $A$**之所以重传 $M_1$ 就表示 $A$ 没有收到对 $M_1$ 的确认**。
   3. 上图(b)也是一种可能出现的情况，**传输过程中没有出现差错**，但 $B$**对分组 $M_1$ 的确认迟到了**，**$A$ 会收到重复的确认**，对重复的确认的处理很简单，**收下后就丢弃**，$B$**仍然会收到重复的 $M_1$**，并且同样要**丢弃重复的 $M_1$**，并**重传确认分组**。
   4. 通常 $A$**最终总是可以收到对所有发出的分组的确认**，**如果 $A$ 不断重传分组但总是收不到确认**，**就说明通信线路太差**，**不能进行通信**。
   5. 使用上述的**确认和重传机制**，我们就可以**在不可靠的传输网络上实现可靠的通信**。
   6. 像上述这种可靠传输协议常称为**自动重传请求**（Automatic Repeat reQuest, ARQ），意思是**重传的请求是自动进行的**，**接收方不需要请求发送方重传某个出错的分组**。
4. **信道利用率**

   1. 停止等待协议的优点是简单，但缺点是**信道利用率太低**，我们可以用下图来说明这个问题，为简单起见，**假定在 $A$ 和 $B$ 之间有一条直通的信道来传送分组**。
      ![停止等待协议的信道利用率太低](https://notebook.ricear.com/media/202206/2022-06-17_162145_439843.png)
   2. 假定 $A$**发送分组需要的时间是**$T_D$，显然，$T_D$**等于分组长度除于数据率**，再假定**分组正确到达 $B$ 后**，$B$**处理分组的时间可以忽略不计**，同时**立即发回确认**，假定 $B$**发送确认分组需要时间 $T_A$**，如果 $A$**处理确认分组的时间也可以忽略不计**，那么 $A$**在经过时间 $(T_D + RTT + T_A)$ 后就可以再发送下一个分组**，这里的 $RTT$**是往返时间**，因为仅仅是**在时间 $T_D$ 内采用来传送有用的数据**（包括分组的首部），因此**信道的利用率**$U$ 可用下式计算：

      $$
      U = \frac{T_D}{T_D + RTT + T_A}
      $$
   3. 上式中的**往返时间 $RTT$ 取决于所使用的的信道**，例如，假定 1200km 的信道的往返时间 $RTT = 20ms$，分组长度是 1200bit，发送速率是 1Mbit/s，若忽略处理时间和 $T_A$（$T_A$ 一般都远小于 $T_D$），则可算出信道的利用率 $U = 5.66\%$，若把发送速率提高到 10Bbit/s，则 $U = 5.96 \times 10^{-4}$，**信道在绝大多数时间内都是空闲的**。
   4. 从上图还可以看出，**当往返时间**$RTT$**远大于分组发送时间**$T_D$**时**，**信道的利用率就会非常低**，还应注意的是，上图并没有考虑出现差错后的分组重传，若**出现重传**，则对传送有用的数据信息来说，**信道的利用率还要降低**。

### 1.2 滑动窗口协议

> 连续 ARQ 协议依赖于**滑动窗口协议**（Sliding Window Protocol），因此在介绍连续 ARQ 协议之前先介绍一下滑动窗口协议。

> 为了讲述可靠传输原理的方便，我们**假定数据传输只在一个方向进行**，即 $A$**发送数据**，$B$**给出确认**，这样的好处是**使讨论限于两个窗口**，即**发送方**$A$**的发送窗口**和**接收方**$B$**的接收窗口**，如果再考虑 $B$ 也向 $A$ 发送数据，那么还要增加 $A$ 的接收窗口和 $B$ 的发送窗口，这对讲述可靠传输的原理并没有多少帮助，反而会使问题更加繁琐。

> 在讨论滑动窗口时，还有一个时间坐标，按照习惯，**向前是指向着时间增大的方向**，**向后则是向着时间减少的方向**，**分组发送是按照分组序号从小到大发送的**。

1. TCP 的滑动窗口是**以字节为单位**的，现假定 $A$**收到了**$B$**发来的确认报文段**，其中**窗口是 20 字节**，而**确认号是 31**（这表明 $B$ 期望收到的下一个序号是 31，而序号 30 为止的数据已经收到了），根据这两个数据，$A$ 就构造出自己的发送窗口，如下图所示：
   ![](https://notebook.ricear.com/media/202206/2022-06-17_171841_673640.png)
2. 我们先讨论发送方 $A$ 的发送窗口，发送窗口表示**在没有收到**$B$**的确认的情况下**，$A$**可以连续把窗口内的数据都发送出去**，**凡是已经发送过的数据**，**在未收到确认之前都必须暂时保留**，**以便在超时重传时使用**。
3. **发送窗口里面的序号表示允许发送的序号**，显然，**窗口越大**，**发送方就可以在收到对方确认之前连续发送更多的数据**，因而**可能获得更高的传输效率**，根据[流量控制](https://ricear.com/project-26/doc-303)我们可以知道，**接收方会把自己的接收窗口数值放在窗口字段中发送给对方**，因此，$A$**的发送窗口一定不能超过**$B$**的接收窗口数值**，同时，**发送方窗口的大小还会受到当时**[网络拥塞程度](https://ricear.com/project-26/doc-304)**的制约**，但在目前，我们暂不考虑网络拥塞的影响。
4. **发送窗口后沿的后面部分表示已发送且已收到了确认**，这些数据显然**不需要再保留了**，而**发送窗口前沿的前面部分表示不允许发送的**，因为**接收方都没有为这部分数据保留临时存放的缓存空间**。
5. **发送窗口的位置由窗口前沿和后沿的位置共同确定**：

   1. **发送窗口后沿的变化情况有两种**，即**不动**（没有收到新的确认）和**前移**（收到了新的确认），**发送窗口后沿不可能向后移动**，因为**不能撤销掉已收到的确认**。
   2. **发送窗口前沿通常是不断向前移动**，但**也有可能不动**，这**对应于两种情况**，一是**没有收到新的确认**，**对方通知的窗口大小也不变**；二是**收到了新的确认但对方通知的窗口缩小了**，**使得发送窗口前沿正好不动**，**发送窗口前沿也有可能向后收缩**，这发生在**对方通知的窗口缩小了**，但 TCP 的标准**强烈不赞成这样做**，因为**很可能发送方在收到这个通知以前已经发送了窗口中的许多数据**，**现在又要收缩窗口**，**不让发送这些数据**，**这样就会产生一些错误**。
6. 现在假定 $A$**发送了序号为 31 ~ 41 的数据**，这时，**发送窗口位置并未改变**，但**发送窗口内靠后面有 11 个字节**（灰色小方框表示）**表示已发送但未收到确认**，而**发送窗口内靠前面的 9 个字节**（42 ~50）**是允许发送但尚未发送的**。
   ![](https://notebook.ricear.com/media/202206/2022-06-17_205955_451550.png)
7. 从以上所述可以看出，要**描述一个发送窗口的状态需要三个指针**，分别为 $P_1$、$P_2$ 和 $P_3$，指针都指向字节的序号，这三个指针指向的几个部分的意义如下：

   1. **小于**$P_1$：**已发送并已收到确认**。
   2. $P_1 - P_2$：**已发送但未收到确认**。
   3. $P_2 - P_3$：**允许发送但未发送**（又称为**可用窗口**或**有效窗口**）。
   4. **大于**$P_3$：**不允许发送**。

      > $P_3$ - $P_1$ 又称为 $A$ 的发送窗口。
      >
8. 再看一下 $B$ 的接收窗口，$B$**的接收窗口大小是 20**，**在接收窗口外面**，**到 30 号为止的数据时已经发送过确认**，并且**已经交付主机了**，因此在 $B$ 中**可以不再保留这些数据**，**接收窗口内的序号**（31 ~ 50）**是允许接收的**，在上图中，$B$**收到了序号为 32 和 33 的数据**，这些数据**没有按序到达**，因为**序号为 31 的数据没有收到**（也许丢失了，也许滞留在网络中的某处），因为 $B$**只能对按序收到的数据中的最高序号给出确认**，因此 $B$**发出的确认报文段中的确认号仍然是 31**（即期望收到的序号），而**不能是 32 或 33**。
9. 现在**假定**$B$**收到了序号为 31 的数据**，**并把序号为 31 ~ 33 的数据交付主机**，然后 $B$**删除这些数据**，接着**把接收窗口向前移动 3 个序号**，同时**给 $A$ 发出确认**，其中**窗口值仍为 20**，但**确认号是 34**，这**表明**$B$**已经收到了到序号 33 为止的数据**，我们还注意到，$B$**还收到了序号为 37**、**38**和**40 的数据**，但**这些都没有按序到达**，**只能先暂存在接收窗口中**，$A$**收到**$B$**的确认后**，**就可以把发送窗口向前滑动 3 个序号**，但**指针**$P_2$**不动**，可以看出，现在 $A$**的可用窗口增大了**，**可发送的序号范围是 42 ~ 53**。
   ![](https://notebook.ricear.com/media/202206/2022-06-17_213005_551046.png)
10. $A$**在继续发送完序号 42 ~ 53 的数据后**，**指针**$P_2$**向前移动和**$P_3$**重合**，**发送窗口内的序号都已用完**，但**还没有再收到确认**，由于 $A$**的发送窗口已满**，**可用窗口已减小到零**，因此**必须停止发送**，需要注意的是，存在下面这种可能性，就是**发送窗口内所有的数据都已正确到达**$B$，$B$**也早已发出了确认**，但不幸的是，**所有这些确认都滞留在网络中**，**在没有收到**$B$**的确认时**，$A$**只能认为**$B$**还没有收到这些数据**，于是，$A$**在经过一段时间后**（由超时计时器控制）**就重传这部分数据**，**重新设置重传计时器**，**直到收到**$B$**的确认为止**，如果 $A$**收到确认号落在发送窗口内**，那么 $A$**就可以使发送窗口继续向前滑动**，**并发送新的数据**。
    ![](https://notebook.ricear.com/media/202206/2022-06-17_214149_285267.png)
11. 我们在前面曾经提到过**发送方的应用进程把字节流写入 TCP 的发送缓存**，**接收方的应用进程从 TCP 的接收缓存中读取字节流**，下面我们就进一步讨论**滑动窗口**和**缓存**的关系，下图展示了**发送方维持的发送缓存和发送窗口**以及**接收方维持的接收缓存和接收窗口**：
    ![](https://notebook.ricear.com/media/202206/2022-06-17_214801_676458.png)

    1. 首先我们来看一下**发送方的情况**：
       1. **发送缓存用来存放**：
          1. **发送应用程序传送给发送方 TCP 准备发送的数据**。
          2. **TCP 已发送出但尚未收到确认的数据**。
       2. **发送窗口通常只是缓存的一部分**：
          1. **已被确认的数据应当从发送缓存中删除**，因此**发送缓存和发送窗口的后沿是重合的**。
          2. **发送应用程序最后写入发送缓存的字节减去最后被确认的字节**，就是**还保留在发送缓存中的被写入的字节数**，**发送应用程序必须控制写入缓存的速率**，**不能太快**，**否则发送缓存就会没有存放数据的空间**。
    2. 接下来我们再看一下**接收方的情况**：
       1. **接收缓存用来暂时存放**：
          1. **按序到达的**、但**尚未被接收应用程序读取的数据**。
          2. **未按序到达的数据**。
       2. 如果**收到的分组被检测出有差错**，则要**丢弃**，如果**接收应用程序来不及读取收到的数据**，**接收缓存最终就会被填满**，**使接收窗口减小到零**，反之，如果**接收应用程序能够及时从接收缓存中读取收到的数据**，**接收窗口就可以增大**，但**最大不能超过接收缓存的大小**。
       3. 上图(b)中还指出了**下一个期望接收到的字节号**，这个字节号也就是**接收方给发送方的报文段的首部中的确认号**。
12. 根据以上的讨论，总结如下：

    1. 第一，虽然 $A$ 的发送窗口是根据 $B$ 的接收窗口设置的，但在**同一时刻**，$A$**的发送窗口并不总是和**$B$**的接收窗口一样大**，这是因为**通过网络传送窗口值需要经历一定的时间滞后**，同时还可能**根据网络当时的拥塞情况适当减小自己的发送窗口数值**，具体的计算方式可参考[总结](https://ricear.com/project-26/doc-304/#2-5-%E6%80%BB%E7%BB%93)。
    2. 第二，对于不按序到达的数据应如何处理，TCP 标准并无明确规定，TCP 通常**对不按序到达的数据是先临时存放在接收窗口中**，**等到字节流中所缺少的字节收到后**，**再按序交付上层的应用进程**。
    3. 第三，TCP 要求**接收方必须有累积确认的功能**，即**接收方不必对收到的分组逐个发送确认**，**而是在收到几个分组后**，**对按序到达的最后一个分组发送确认**，**这就表示**，**到这个分组为止的所有分组都已正确收到了**，这样可以**减小传输开销**，接收方可以**在合适的时候发送确认**，也可以**在自己有数据要发送时把确认信息顺便捎带上**，但是需要注意的是：
       1. **接收方不应过分推迟发送确认**，**否则会导致发送方不必要的重传**，**这反而浪费了网络的资源**，TCP 标准规定，**确认推迟的时间不应超过 0.5 秒**，**若收到一连串具有最大长度的报文段**，**则必须每隔一个报文段就发送一个确认**。
       2. **捎带确认实际上并不经常发生**，**因为大多数应用程序很少同时在两个方向上发送数据**。

### 1.3 连续 ARQ 协议

> 滑动窗口协议讲解完了，下面我们来讲解一下连续 ARQ 协议。

1. 针对停止等待协议中存在的**信道利用率低**的问题，引入了一种**流水线传输**的工作方式，发送方可以**不使用低效率的停止等待协议**，而是采用**流水线传输**，即发送方**可连续发送多个组**，**不必每发完一个分组就停顿下来等待对方的确认**，这样可**使信道上一直有数据在不间断地传送**，显然，这种传输方式可以**获得很高的信道利用率**。
   ![](https://notebook.ricear.com/media/202206/2022-06-17_164922_712605.png)
2. 连续 ARQ 协议使用的就是上面提到的**流水线传输方式**，协议中发送和接收的具体方式采用**[滑动窗口协议](#1-2-滑动窗口协议)**来进行，具体可参考上面提到的滑动窗口协议的相关内容。

## 2. TCP 可靠传输的实现

TCP 通过下列方式来提供可靠性：

1. **[数据拆分](#2-1-数据拆分)**。
2. **[超时重传](#2-2-超时重传)**。
3. **[确认机制](#2-3-确认机制)**。
4. **[校验和](#2-4-校验和)**。
5. **[数据报重排序](#2-5-数据报重排序)**。
6. **[流量控制](#2-6-流量控制)**。

### 2.1 数据拆分

1. TCP/IP 协议簇**建立了互联网通信协议的概念模型**，该协议簇的两个主要协议就是 TCP 和 IP 协议，这两个协议**不仅能够保证数据会从源机器的源进程发送到目标机器的目标进程中**，**还能保证数据的不重不漏以及发送的顺序**。
2. 当应用层协议使用 TCP/IP 协议传输数据时，TCP/IP 协议簇可能会**将应用层发送的数据分成多个包依次发送**，而**数据的接收方收到的数据可能是分段的或者是拼接的**，所以他**需要对接收的数据进行拆分或者重组**。
3. 下面将会分别从 IP 协议和 TCP 协议两个角度出发分析为什么应用层写入的数据包会被 TCP/IP 协议拆分发送，首先说一下结论：
   1. **IP 协议会分片传输过大的数据包**（Packet）**避免物理设备的限制**。
   2. **TCP 协议会分段传输过大的数据段**（Segment）**保证传输的性能**。

#### 2.1.1 IP 协议分片

##### 2.1.1.1 为什么要进行分片

1. 在 TCP/IP 协议簇中，**链路层可以为 IP 模块发送和接收 IP 数据报**，TCP/IP 协议支持不同的链路层协议，这取决于网络所使用的硬件，如以太网、令牌环网等，而这些**底层硬件对数据帧的长度都有一个限制**，比如以太网的数据帧长度最大为 1500 字节，802.3 的数据帧长度最大为 1492 字节，**链路层的这个特性称作最大传输单元**（Maximum Transmission Unit, MTU），**不同类型的网络大多数都有一个限制**。
   ![第 1 章 概述_TCP/IP 详解卷 1 协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-28_1148300.050953602887815364.png "TCP/IP 协议簇中不同层次的协议")
   ![第 2 章 链路层_TCP/IP 详解卷 1 协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-28_1151150.4816085587647606.png "IEEE 802.2/802.3（RFC 1042）和以太网的封装格式（RFC 894）")
2. 如果 **IP 层有一个数据报要传**，而且**数据的长度比链路层的 MTU 还大**，那么 **IP 层就要进行分片**，**把数据报分成若干片**，这样**每一片都小于 MTU**。我们会在后面详细介绍 IP 层分片的具体原理。
3. 下图列出了一些典型的 MTU 值，需要注意的是，点对点的链路层（如 SLIP 和 PPP）的 MTU 并非指的是网络媒体的物理特性，相反，他是一个逻辑限制，目的是为交互使用提供足够快的响应时间。
   ![第 1 章 概述_TCP/IP 详解卷 1 协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-28_1156350.7073084618631299.png "几种常见的最大传输单元")
4. 当在同一个网络上的两台主机互相进行通信时，该网络的 MTU 是非常重要的。但是如果**两台主机之间的通信要通过多个网络**，那么**每个网络的链路层就可能有不同的 MTU**。重要的不是两台主机所在网络的 MTU 的值，而是**两台通信主机路径中的最小值**，即**路径 MTU**（Path MTU, PMTU）。
5. 两台主机之间的路径 MTU 不一定是个常数，他取决于当时所选择的路由。而选路不一定是对称的（从 A 到 B 的路由可能与从 B 到 A 的路由不同），因此**路径 MTU 在两个方向上不一定是一致的**。

##### 2.1.1.2 分片的原理

1. 通过上面所述我们可以知道**链路层一般要限制每次发送数据帧的最大长度**。任何时候 **IP 层接收到一份要发送的 IP 数据报时**，他要**判断向本地哪个接口发送数据**，并**查询该接口获得其 MTU**。**IP 把 MTU 与数据报长度进行比较**，**如果需要则进行分片**。**分片可以发生在原始发送端主机上**，**也可以发生在中间路由器上**。
2. 把一份 **IP 数据报分片以后**，**只有到达目的地才进行重新组装**（这里的重新组装与其他网络协议不同，他们要求在下一站进行重新组装，而不是在最终的目的地）。**重新组装由目的端 IP 层来完成**，**其目的是使分片和重新组装过程对传输层**（TCP 和 UDP）**是透明的**，除了某些可能的越级操作外。**已经分片过的数据报有可能会再次进行分片**（可能不止一次）。**IP 首部中包含的数据为分片和重新组装提供了足够的信息**。
3. IP 首部中的这些字段用于分片过程：
   1. 对于发送端发送的**每份 IP 数据报**来说，其**标识字段都包含一个唯一值**，该值**在数据报分片时被复制到每个片中**。标志字段用其中一个比特来表示「**更多的片**」。**除了最后一片外**，**其他每个组成数据报的片都要把该比特置 1**。
   2. **片偏移字段指的是该片偏移原始数据报开始处的位置**，另外，**当数据报被分片后**，**每个片的总长度值要改为该片的长度值**。
   3. 标志字段中有一个比特称作「**不分片**」位。如果**将这一比特置 1**，**IP 将不对数据报进行分片**，如果**路由器收到一份需要分片的数据报**，而**在 IP 首部又设置了不分片的标志比特**，那么**主机将会把数据报丢弃并发送一个 ICMP 差错报文给起始端**。
      > 路径 MTU 机制的实现原理为**通过在发送端所发送的 IP 数据报中的 IP 首部设置不分段标志位**，此时**路径上任何 MTU 小于数据报的设备都会丢弃他**，并**向起始端发送一个 ICMP 差错报文**，因此**源主机可以适当减少发送的数据报大小来观察是否继续收到 ICMP 差错报文**，**重复该过程**，**直到 MTU 小到数据报可以遍历整个路径而不会收到 ICMP 差错报文**。
      > ![第 3 章 IP:网际协议_TCP/IP 详解卷 1 协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-29_1134020.139742301000497.png "IP 数据报格式及首部中的各字段")
      >
4. 当 **IP 数据报被分片后**，**每一片都成为一个分组**，**具有自己的 IP 首部**，并**在选择路由时与其他分组独立**。这样，**当数据报的这些片到达目的端时有可能会失序**，但是在 **IP 首部中有足够的信息让接收端能正确组装这些数据报片**。

##### 2.1.1.3 分片的局限性

1. 由于 **IP 层本身没有超时重传机制**，而是**由更高层来负责超时和重传**（**TCP 有超时和重传机制**，但 **UDP 没有**。**一些 UDP 应用程序本身也执行超时和重传**）。
2. 当**来自 TCP 报文段的某一片丢失后**，**TCP 在超时后会重发整个 TCP 报文段**，**该报文段对应于一份 IP 数据报**。**没有办法只重传数据报中的一个数据报片**。
3. 如果**对数据报分片的是中间路由器**，而**不是起始端系统**，那么**起始端系统就无法知道数据报片是如何被分片的**，因此，需要**尽量避免分片**。

##### 2.1.1.4 分片实例

###### 2.1.1.4.1 UDP 分片实例

1. 使用 UDP 很容易导致 IP 分片，我们可以用 `sock` 程序来增加数据报的长度，直到分片发生。在一个以太网上，数据帧的最大长度是 1500 字节，其中 1472 字节留给数据，假定 IP 首部为 20 字节，UDP 首部为 8 字节，我们分别以数据长度为 1471、1472、1473 和 1474 运行 `sock` 程序，最后两次应该发生分片，运行的命令如下：

   ```shell
   sock -u -i -nl -w1471 svr4 discard
   ```

   ```shell
   sock -u -i -nl -w1472 svr4 discard
   ```

   ```shell
   sock -u -i -nl -w1473 svr4 discard
   ```

   ```shell
   sock -u -i -nl -w1474 svr4 discard
   ```
2. 相应的 `tcpdump` 输出结果如下图所示：
   ![第 11 章 UDP:用户数据报协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-29_1610300.1202024267313998.png)
3. 从上面图中的结果我们可以看出：

   1. 前两份 UDP 数据报（第一行和第二行）能装入以太网数据帧，没有被分片，但是对应于写 1473 字节的 IP 数据报长度为 1501，就必须进行分片（第三行和第四行），同理，写 1474 字节产生的数据报长度为 1502，他也需要进行分片（第 5 行和第 6 行）。
   2. 当 IP 数据报被分片后，`tcdump` 打印出其他的信息，首先，`frag 26304`（第 3 行和第 4 行）和 `frag 26313`（第 5 行和第 6 行）指的是 IP 首部中标识字段的值。
   3. 分片信息中的下一个数字，即第 3 行中位于冒号和 `@` 之间的 1480，是除 IP 首部外的片长，两份数据报第一片的长度均为 1480（UDP 首部占 8 字节，用户数据占 1472 字节），第 1 份数据报的第 2 片（第 4 行）只包含 1 字节数据（剩下的用户数据），第 2 份数据报的第 2 片（第 6 行）包含剩下的 2 字节用户数据。
   4. 在分片时，除最后一片外，其他每一片中的数据部分（除 IP 首部外的其余部分）必须是 8 字节的整数倍，在本例中，1480 是 8 的整数倍。
   5. 位于 `@` 符号后的数字是从数据报开始处计算的偏移值，两份数据报第 1 片的偏移值均为 0（第 3 行和第 5 行），第 2 片的偏移值为 1480（第 4 行和第 6 行），跟在偏移值后面的加号对应于 IP 首部中 3 比特标志字段中的「更多片」比特，设置这一比特的目的是让接收端知道在什么时候完成所有的分片组装。
   6. 最后，注意第 4 行和第 6 行省略了协议名（UDP）、源端口号和目的端口号，协议名是可以打印出来的，因为他在 IP 首部并被复制到各个片中，但是端口号在 UDP 首部，只能在第一片中被发现。
   7. 发送的第 3 份数据报（用户数据为 1473 字节）分片情况如下图所示，需要注意的是，任何运输层首部只出现在第 1 片数据中。
      ![第 11 章 UDP:用户数据报协议_TCP/IP 详解卷 1 协议_即时通讯网(52im.net)](https://notebook.ricear.com/media/202205/2022-05-29_1647180.7275877842219161.png)
   8. 需要注意的是，IP 数据报是指 IP 层端到端的传输单元（在分片之前和重新组装之后），分组是指在 IP 层和链路层之间的数据单元，一个分组可以是一个完整的 IP 数据报，也可以是 IP 数据报的一个分片。

#### 2.1.2 TCP 协议分段

1. **TCP 协议是面向字节流的协议**，**应用交给 TCP 协议的数据并不会以消息为单位向目的主机发送**，而是**可能被拆分成多个数据段**。
2. TCP 协议中引入了**最大分段大小**（Maximum Segment Size, MSS），他**是 TCP 数据段能够携带的数据上限**，在正常情况下，**TCP 连接的 MSS 是 MTU - 40 字节**，即 **1460 字节**，不过**如果通信双方没有指定 MSS 的话**，**在默认情况下 MSS 的大小是 536 字节**。
3. **TCP 协议的 MSS 是操作系统内核层面的限制**，**通信双方会在[三次握手](https://ricear.com/project-26/doc-301)时确定这次连接的 MSS**，**一旦确定了 MSS**，**TCP 协议就会对应用层交给 TCP 协议发送的数据进行拆分**，**构成多个数据段**。
   > 在 TCP 连接的前两次握手中，发送端和接收端会通过 SYN 包中的 MSS 选项，通知对方自己期待接收的 MSS，在最后一次握手中，以双方 SYN 报文中最小的 MSS 作为本次数据传输的 MSS。
   >
4. **为了保证可靠性**，**会通过 IP 协议的 MTU 计算出 MSS 并根据 MSS 分段避免 IP 协议对数据包进行分片**，因为 IP 协议对数据包的分片对上层是透明的，**如果协议不根据 MTU 做一些限制**，**那么 IP 协议的分片会导致部分数据包失去传输层协议头**，**一旦数据包发生丢失就只能丢弃全部数据**。
5. 具体实例如下：
   1. 如下图所示，如果 TCP 连接的 MSS 是 1460 字节，应用层想要通过 TCP 协议传输 2000 字节的数据，那么 TCP 协议会根据 MSS 将 2000 字节的数据拆分到两个数据段中。
      ![](https://notebook.ricear.com/media/202205/2022-05-27_102456_404830.png)
   2. 具体的数据分布如下：
      1. 20 字节 IP 头 + 20 字节 TCP 头 + 1460 字节数据。
      2. 20 字节 IP 头 + 20 字节 TCP 头 + 1460 字节数据。
   3. 如果 TCP 协议中不存在 MSS 的概念，因为每个数据段的大小没有上限，当 TCP 协议交给 IP 层发送两个 1600 字节（包括 IP 和 TCP 协议头）的数据包时，由于物理设备的限制，IP 协议的路径 MTU 为 1500 字节，所以 IP 协议会对数据包分片。
      ![](https://notebook.ricear.com/media/202205/2022-05-27_103001_656451.png)
   4. 四个数据包中只有两个包含 TCP 协议头，即控制位、序列号等信息，剩下的两个数据包中不包含任何信息，当 IP 协议传输丢包时，TCP 协议的接收方没有办法对数据包进行重组，所以整个 TCP 数据段都需要重传，带来了更多的额外重传和重组开销。

#### 2.1.3 总结

1. 数据拆分的根本原因说到底还是物理设备的限制**，不过**每一层协议都受限于下一层协议做出的决定**，并**依赖下层协议重新决定设计和实现的方法**，虽然 TCP/IP 协议在传输数据时都需要对数据进行拆分，但是他们做出拆分数据的设计基于不同的上下文，也有着不同的目的，我们在这里总结一下两个网络协议做出类似决定的原因：
   1. **IP 协议拆分数据是因为物理设备的限制**，**一次能够传输的数据由路径上 MTU 最小的设备决定**，**一旦 IP 协议传输的数据包超过 MTU 的限制就会发生分片**，所以我们**需要通过路径 MTU 发现获取传输路径上的 MTU 限制**。
   2. **TCP 协议拆分数据是为了保证传输的可靠性和顺序**，作为可靠的传输协议，**为了保证数据的传输顺序**，他**需要为每一个数据段增加包含序列号的 TCP 协议头**，**如果数据段大小超过了 IP 协议的 MTU 限制**，**就会带来更多额外的重传和重组开销**，**影响性能**。

### 2.2 超时重传

TCP 提供**可靠的传输层**，其使用的方法之一就是**确认从另一端收到的数据**，但**数据和确认都有可能会丢失**，TCP 通过**在发送时设置一个定时器**来解决这种问题，如果**当定时器溢出时还没有收到确认**，他**就重传该数据**，对于任何实现而言，关键之处就在于**超时**和**重传**的策略，即**怎样决定超时间隔和如何确定重传的频率**。

#### 2.2.1 往返时间测量

1. TCP 超时与重传中最重要的部分就是**对一个给定连接的往返时间**（Round Trip Time, RTT）**的测量**，由于路由器和网络流量均会变化，因此我们认为这个时间可能经常会发生变化，TCP 应该跟踪这些变化并相应地改变其超时时间。
2. 首先 TCP 必须测量**在发送一个带有特别序号的字段和接收到包含该字段的确认之间的 RTT**，我们用 $M$ 表示所测量到的 RTT。
3. 最初的 TCP 规范（[RFC0793](https://link.zhihu.com/?target=https%3A//tools.ietf.org/html/rfc793%23section-2.8)）的计算方式如下：

   1. 使用下面的公式来得到**平滑的 RTT 估计值**，记作 $SRTT$：

      $$
      SRTT \leftarrow \alpha * SRTT + (1 - \alpha) * M
      $$

      整个算法实现的思路就是**利用现存的 $SRTT$ 值和最新测量得到的 $RTT$ 取一个加权平均**。
   2. 有了 $SRTT$，就该设置对应的**重传超时时间**（Retransmission TimeOut, RTO）的值了，[RFC0793](https://link.zhihu.com/?target=https%3A//tools.ietf.org/html/rfc793%23section-2.8)中的计算方式如下：

   $$
   RTO = min(ubound, max(lbound, SRTT * \beta))
   $$

   3. 这里的 $ubound$ 是 $RTO$ 的上边界，$lbound$ 是 $RTO$ 的下边界，$\beta$ 称为时延离散因子，推荐值为 1.3 ~ 2.0，这个公式就是将 $SRTT * \beta$ 的值作为 $RTO$，只不过另外限制了 $RTO$ 的上下限。
   4. 这个计算方法在实际应用起来存在以下两个缺陷：
      1. **当出现数据包重传的情况下**，$RTT$ **的计算就会很麻烦**，如下图所示：
         ![](https://notebook.ricear.com/media/202205/2022-05-30_1622060.7070800430543429.png)
         1. 上图中列了两种情况，这两种情况下计算 RTT 的方法是不一样的（即所谓的**重传二义性**）：
            1. 情况一：$RTT = t_2 - t_0$。
            2. 情况二：$RTT = t_2 - t_1$。
         2. 但对于客户端来说，他不知道发生了哪种情况，选错的结果就是 $RTT$ 偏大或偏小，影响到 $RTO$ 的计算。
      2. 这个算法**假设 $RTT$ 波动比较小**，因为**这个加权平均的算法又叫低通滤波器**，**对突然的网络波动不敏感**，**如果网络时延突然增大导致实际 $RTT$ 值远大于估计值**，**会导致不必要的重传**，**增大网络负担**。
4. 标准方法：

   1. 标准方法的计算公式如下：

      $$
      SRTT \leftarrow (1 - \alpha) * RTT + \alpha * RTT
      $$

      $$
      RTT_{var} \leftarrow (1 - h) * RTT_{var} + h * (|RTT - SRTT|)
      $$

      $$
      RTO = SRTT + 4 * RTT_{var}
      $$
   2. 整个方法的解析过程如下：

      1. 第一个公式跟基本方法一样，用于**求 $SRTT$ 的加权平均**。
      2. 第二个公式用于**计算 $SRTT$ 与真实值的绝对误差**，同样用到了**加权平均**。
      3. 第三个公式用于**计算新估算出来的 $RTO$**，其中 $RTT_{var}$ **的系数 4 是调参调出来的**。
   3. 这个算法的整体思想是**结合平均值和平均偏差来进行估算**，**取得了不错的效果**，**并被许多实现所采用**。
5. **在一个分组重传时会产生这样一个问题**，**假定一个分组被发送**，**当超时发生时**，**会将每次重传时的超时时间增加 1 倍直至 64s**（即**指数退避**），**分组以更长的 RTO 进行重传**，**然后收到一个确认**，**那么这个 ACK 是针对第一个分组的还是针对第二个分组的呢**，即**重传多义性**问题。
6. 针对以上的重传多义性问题，可以采用 **Karn** 算法来解决，**在计算平均往返时间 $RTT$ 时**，**只要报文段重传了**，**就不采用其往返时间样本**，这样**得出的加权平均往返时间 $RTT$ 和超时重传时间 $RTO$ 就较准确**。
7. 但是这样又有了新的问题，**加入报文段的时延突然增大了很多**，这样**在原来得出的重传时间内不会收到确认报文段**，于是就**重传相应的报文段**，但**根据 Karn 算法**，**不考虑重传的报文段的往返时间样本**，这样**超时重传时间就无法更新**，因此需要对原有的 Karn 算法进行修正，修正后的 Karn 算法计算公式如下：

   $$
   RTO_{new} = \gamma * RTO_{old}
   $$

   上面公式中的 $\gamma$ **的典型值是 2**，**这样报文段每重传一次**，**就把超时重传时间 $RTO$ 增大一些**，**当不再发生报文段的重传时**，**才根据报文段的往返时延更新平均往返时延 $RTT$ 和超时重传时间**，实践证明，这种策略较为合理。

#### 2.2.2 重传机制

1. 由于下层网络层（IP）可能出现丢失、重复或失序包的情况，TCP 协议提供可靠数据传输服务，为保证数据传输的正确性，TCP 重传其认为丢失的包，TCP 根据接收端返回至发送端的一系列确认信息来判断是否出现丢包，当数据段或确认信息丢失，TCP 启动重传操作，重传尚未确认的数据。
2. TCP 有两套重传机制：
   1. 一是**基于时间**，TCP 在**发送数据时会设置一个计时器**，若至**计时器超时仍未收到数据确认信息**，则会**引发相应的超时或基于计时器的重传操作**，计时器超时称为**重传超时**。
   2. 另一种是**基于确认信息的构成**，此种方式的重传称为**快速重传**，通常发生**在没有延时的情况下**，若 **TCP 累积确认无法发送新的 ACK**，或者**当 ACK 包含的选择确认信息表明出现失序报文段时**，**快速重传会推断出现丢包**，快速重传有三种，分别为**基本类型的快速重传**、**带选择确认的重传**和**重复带选择确认的重传**。

##### 2.2.2.1 基于计时器的重传

1. 一旦 TCP 发送端得到了基于时间变化的 RTT 测量值，就能据此设置 RTO，发送报文段时应确保重传计时器设置合理。
2. **在设定计时器前**，**需记录被计时的报文段序列号**，**若及时收到了该报文段的 ACK**，**那么计时器被取消**，之后**发送端发送一个新的数据包时**，**需设定一个新的计时器**，并**记录新的序列号**，因此**每一个 TCP 连接的发送端不断地设定和取消一个重传计时器**，如果**数据没有丢失**，则**不会出现计时器超时**。
3. 若**在连接设定的 RTO 内**，**TCP 没有收到被计时报文段的 ACK**，就会**触发超时重传**，当发生这种情况时，TCP 不仅会**重传对应数据段**，还会**降低当前数据发送速率**来对此进行**快速响应**，它有两种实现方法：
   1. 一种方法是**基于[拥塞控制机制](https://ricear.com/project-26/doc-304)减小发送窗口大小**。
   2. 另一种方法是**每当一个重传报文段被再次重传时**，则[**增大 RTO 的退避因子**](#2-1-%E5%BE%80%E8%BF%94%E6%97%B6%E9%97%B4%E6%B5%8B%E9%87%8F)。
4. 超时重传往往会带来许多微秒的问题，比如说：
   1. **当一个报文段丢失时**，**会等待一定的超时周期然后才重传分组**，**增加了端到端的时延**。
   2. **当一个报文段丢失时**，**在其等待超时的过程中**，**可能会出现这种情况**，**其后的报文段已经被接收端接收但却迟迟得不到确认**，**发送端会认为也丢失了**，**从而引起不必要的重传**，**既浪费资源也浪费时间**。

##### 2.2.2.2 快速重传

1. TCP 采用的是**累积确认**机制，即当**接收端收到比期望序号大的报文段**时，便会**重复发送最近一次确认的报文段的确认信号**，称为**冗余 ACK**（Dumplicate ACK）。
2. 如下图所示，报文段 1 成功接收并被确认 ACK 2，接收端的期待序号为 2，当报文段 2 丢失，报文段 3 失序到来，与接收端的期望不匹配，接收端重复发送冗余 ACK 2。
   ![](https://notebook.ricear.com/media/202206/2022-06-01_1933440.29035427711482786.png)
3. 如果在**超时重传定时器溢出之前**，**接收到连续三个重复冗余 ACK**（其实是收到 4 个同样的 ACK，第一个是正常的，后三个才是冗余的），**发送端便知晓哪个报文段在传输过程中丢失了**，于是**重发该报文段**，**不需要等待超时重传计时器溢出**，**大大提高了效率**，这便是**快速重传**（Fast Retransmit）。

   > 快速重传中为什么是三次冗余 ACK？
   >
   > 1. 首先需要明白一点，即使**发送端是按序发送**，由于 **TCP 包是封装在 IP 包内**，**IP 包在传输时乱序**，意味着 **TCP 包到达接收端也是乱序的**，**乱序的话也会造成接收端发送冗余 ACK**，那么**发送冗余 ACK 是由于乱序造成的还是包丢失造成的**，这里便**需要好好权衡一番**，因为**把 3 次冗余 ACK 作为判定丢失的准则其本身就是估计值**。
   > 2. 假定通信双方如下：
   >
   >    1. $A$ 为发送端，$B$ 为接收端。
   >    2. $A$ 的待发送报文段序号为 $N - 1、N、N + 1、N + 2$。
   >    3. 假设报文段 $N - 1$ 成功到达。
   > 3. 报文段 $N$ 可能有两种情况，一种是没有丢失，只是到达顺序不一致；另一种是丢失。具体的报文段发送及 ACK 确认情况如下图所示：
   >
   >    ![](https://notebook.ricear.com/media/202206/2022-06-01_1709220.7318460992745337.png)
   > 4. 从以上罗列的情况可以看出：
   >
   >    1. 在没丢失（$A$）的情况下，有 2 / 5 = 40% 的可能出现 3 次冗余 ACK。
   >    2. 在乱序（$A$）的情况下，必定是 2 次冗余 ACK。
   >    3. 在丢失（$A$）的情况下，必定出现 3 次冗余 ACK。
   > 5. 基于这样的概率，选定 3 次冗余 ACK 作为阈值也算是合理的，在实际的抓包过程中，大多数的快速重传都会在大于 3 次冗余 ACK 后发生。
   >
4. 下面有两张图，第一张图是在某报文段的超时重传定时器溢出前重传丢失报文段，第二张图是对应的接收端缓存队列的窗口移动示意图。
   ![](https://notebook.ricear.com/media/202206/2022-06-01_1937230.6582568592635254.png)
   ![](https://notebook.ricear.com/media/202206/2022-06-01_1938090.4511449929817345.png)

##### 2.2.2.3 带选择确认的重传

1. 快速重传也可能有问题，因为 **ACK 只告诉发送方最大的有序报文段**，但是**到底是哪个报文段丢失了**，以及**到底应该重传多少个包都是不确定的**，比如上面的快速重传例子中，是重传 Seq = 4，还是重传 Seq = 4 - 11 呢，因为发送端并不清楚这三个连续的 ACK = 4 是谁传回来的。
2. 为了解决应该重传多少包的问题，TCP 提供了**带选择确认的重传**（Selective Acknowledgement, SACK），SACK 机制的原理就是**在快速重传的基础上**，**接收方返回最近收到报文段的序列号范围**，**这样发送方就知道接收方哪些数据包是没收到的**，**这样就很清楚应该重传哪些数据包了**。

   > 如果要使用SACK，那么**在建立TCP连接时**，**就要在TCP首部的选项中加上允许SACK的选项**，**原来首部中的确认号字段的用法仍然不变**，**只是以后在TCP报文段的首部中都增加了SACK选项**，**以便报告收到的不连续的字节块的边界**。
   >

   > 由于**首部选项的长度最多只有40字节**，而**指明一个边界就要用掉4字节**（因为序号有32位，需要使用4个字节表示），因此**在选项中最多只能指明4个字节块的边界信息**，这是因为4个字节块共有8个边界，因而需要用**32个字节**来描述，另外还需要**两个字节**，一个字节用来**指明是SACK选项**，另一个字节是**指明这个选项要占用多少字节**，如果要报告五个字节块的边界信息，那么至少需要42个字节，这就超过了选项长度的40字节的上限。
   >
3. 具体实例如下，发送方收到了三次同样的 ACK = 30 的确认报文，于是就会触发快速重传机制，通过 SACK 信息发现只有 30 ~ 39 这段数据丢失，因此重发时就只选择了 30 ~ 39 的 TCP 报文段进行重发。
   ![itqiankun.com.a68780.html47.png](https://notebook.ricear.com/media/202206/2022-06-01_2019230.16935938666390438.png)

##### 2.2.2.4 重复带选择确认的重传

1. **重复带选择确认的重传**（Duplicate SACK, D-SACK）**是在 SACK 的基础上做了一些扩展**，主要用来**告诉发送方有哪些数据包被接收端重复接收了**，其目的是**帮助发送方判断是否发生了包失序**、**ACK 丢失**、**包重复**，**让 TCP 可以更好的做网络流控**，具体来说，D-SACK 具有如下作用：
   1. **让发送方知道**，**是发送的包丢了**，**还是返回的 ACK 包丢了**。
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1648060.8472386668425588.png)
   2. **网络上是否出现了包失序**。
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1647500.6498301969113863.png)
   3. **数据包是否被网络上路由器复制并转发了**。
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1647310.7864654018436411.png)
   4. **是不是自己的 RTO 太小**，**导致了重传**。
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1648200.6230039278219002.png)
2. **D-SACK 使用了 SACK 的第一个段来做标志**，可以采用以下方法来判断 D-SACK：
   1. 如果 **SACK 的第一个段的范围被 ACK 所覆盖**，那么就是 D-SACK。
   2. 如果 **SACK 的第一个段的范围被 SACK 的第二个段的范围覆盖**，那么就是 D-SACK。
3. D-SACK 的规则如下：
   1. **第一个 `block` 将包含重复收到的报文段的序号**。
   2. **跟在 D-SACK 之后的 SACK 将按照 SACK 的方式工作**。
   3. **如果有多个被重复接收的报文段**，**则 D-SACK 只包含其中第一个**。
4. 具体实例如下：
   1. 报告重复报文段：
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1537510.057198173806761066.png)
      1. 上图中由于 ACK 4000 大于[3000, 3500]，因此[4000, SACK = 3000 - 3500]是 D-SACK。
      2. 发送端首先向接收端发送了 3000 - 3499，3500 - 3999 报文，接收端都收到了，但是接收端返回的 ACK 3500 及 4000 都丢失，导致发送端重传了 3000 - 3499 报文。
      3. 接收端收到发送端重新发送的 3000 - 3499 报文，通过[4000, SACK = 3000 - 3500]告知发送端，发送端就知道第一次的 3000 - 3499 报文接收端是收到了，由于当前 ACK 到了 4000，那么 4000 之前的数据也受到了。
   2. 报告失序报文段和重复报文段：
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1618140.28732872641956697.png)
      1. [4000, SACK = 4500 - 5000]不满足 D-SACK 的条件，其是普通的 SACK，而[4000, SACK = 3000 - 3500, 4500 - 5000]是 D-SACK，其含义是 4000 前的数据已收到，3000 - 3500 的数据重复收到，4000 - 4499 的包丢失，4500 - 5000 的包收到。
   3. 报告重复且失序的报文段：
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1622040.18671759779350017.png)
      1. [4000, SACK = 4500 - 5000]及[4000, SACK = 4500 - 5500]都是普通的 SACK，[4000, SACK = 5000 - 5500, 4500 - 5500]是 D-SACK（第二种判断方法），含义是 4000 之前的包都收到，5000 - 5499 包重复收到，4500 - 4499 的包丢失。
   4. 报告一个单独的重复子报文段：
      ![](https://notebook.ricear.com/media/202206/2022-06-03_1629530.5397257460978355.png)
      1. 发送端以 500 字节大小发送报文 500 - 999、1000 - 1499、1500 - 1999、2000 - 2499 的报文，而 1000 - 1499 因为网络延迟而没有及时到达接收端，1500 - 1999 丢失了，接收端通过[1000, SACK = 2000 - 2500]告知发送端 1000 之前的报文及 2000 - 2499 报文已收到，1000 - 1999 的报文没有收到。
      2. 发送端随后以 1000 字节大小重传数据 1000 - 19999，而接收端又收到了 1000 - 1499 的报文，于是接收端通过[1500, SACK = 2000 - 2500]先告知发送端 1500 前的报文及 2000 - 2499 的报文都收到，而 1500 - 1999 的报文没有收到，此时接收端又收到了发送端的 1000 - 2000 报文，于是通过 D-SACK[2500, SACK = 1000 - 1500]告知发送端 2500 前的报文全部收到，1000 - 1500 的报文重复收到。

### 2.3 确认机制

1. TCP 数据报中的序列号（Sequence Number）不是以报文段来进行编号的，而是**将连接生存周期内传输的所有数据当做一个字节流**，**序列号就是整个字节流中每个字节的编号**。
2. 一个 TCP 数据包中包含多个字节流的数据（即[数据段](#1-2-TCP-%E5%8D%8F%E8%AE%AE%E5%88%86%E6%AE%B5)），而且每个 TCP 数据包中的数据大小不一定相同，**在建立 TCP 连接的[三次握手](https://ricear.com/project-26/doc-301)过程中**，**通信双方各自已确定了初始的序号 $x$ 和 $y$**，**TCP 每次传送的报文段中的序号字段值表示所要传送本报文中的第一个字节的序号**。
3. TCP 的报文到达确认，是**对接收到的数据的最高序列号的确认**，并**向发送端返回一个下次接收时期望的 TCP 数据包的序列号**，例如主机 A 发送的当前数据序号是 400，数据长度是 100，则接收端收到后会返回一个确认号是 501 的确认号给主机 A。
4. TCP 提供的确认机制，可以在通信过程中**可以不对每一个 TCP 数据包发出单独的确认包**（即**延迟确认机制**），而是**在传送数据时**，**顺便把确认信息传出**，这样可以**大大提高网络的利用率和传输效率**，同时，TCP 的确认机制，也可以**一次确认多个数据包**，例如接收方收到了 201、301、401 的数据包，则只需要对 401 的数据包进行确认即可，对 401 数据包的确认也意味着 401 之前的所有数据包都已确认，这样也可以提高系统的效率。
5. 若**发送方在规定时间内没有收到接收方的确认信息**，就要**将未被确认的数据包重新发送**，**接收方如果收到一个有差错的报文**，则**丢弃此报文**，并**不向发送方发送确认信息**，因此，TCP 报文的[重传机制](#2-2-重传机制)是由设置的**超时定时器**来决定的，**在定时的时间内没有收到确认信息**，则**进行重传**，这个定时的时间值的设定非常重要，太大会使包重传的延时比较大，太小则可能没有来得及收到对方的确认包发送方就再次重传，会使网络陷入无休止的重传过程中，接收方如果收到了重复的报文，将会丢弃重复的报文，但是必须发回确认信息，否则对方会再次发送。
6. TCP 协议应当保证**数据报按序到达接收方**，如果**接收方收到的数据报文没有错误**，**只是未按序号**，针对这种问题，TCP 协议本身没有规定，而是由 TCP 协议的实现者自己去确定，通常有两种方法进行处理，一是**对没有按序号到达的报文直接丢弃**，二是**将未按序号到达的数据包先放于缓冲区内**，**等待他前面的序号包到达后**，**再将他交给应用进程**，**后一种方法将会提高系统的效率**，例如发送方连续发送了每个报文中 100 个字节的 TCP 数据报，其序号分别是 1、101、201、… 、701，假如其他 7 个数据报都收到了，而 201 这个数据报没有收到，则接收端应当对 1 和 101 这两个数据报进行确认，并将数据递交给相关的应用进程，301 至 701 这 5 个数据报则应当放于缓冲区，等到 201 这个数据报到达后，然后按序将 201 至 701 这些数据报递交给相关应用进程，并对 701 数据报进行确认，确保了应用进程级的 TCP 数据的按序到达。
7. TCP 协议中，接收方成功接收到数据后，会回复一个 ACK 数据包，表示已经确认接收到 ACK 确认号前面的所有数据，**ACK 字段长度为 32 位**，**能表示 $ 0 \sim 2^{32} - 1 $ 之间的值**。
8. **接收方在接收到数据后**，**不是立即会给发送方发送 ACK 的**，**而是延迟一段时间**，这样做有两个目的：
   1. **ACK 是可以合并的**，如果**连续收到两个 TCP 包**，并**不一定需要确认两次**，**只需要回复最终的 ACK 就可以了**，可以**降低网络流量**。
   2. 如果**接收方有数据要发送**，那么就会**在发送数据的 TCP 数据包里**，**带上 ACK 信息**，这样做可以**避免大量的 ACK 以一个单独的 TCP 包发送**，**减少了网络流量**。

### 2.4 校验和

1. TCP 校验和是一个**端到端的校验和**，**由发送端计算**，然后**由接收端验证**，其**目的是为了发现 TCP 首部和数据在发送端到接收端之间发生的任何改动**，**如果接收方检测到校验和有差错**，**则 TCP 段会被直接丢弃**。
2. **TCP 校验和覆盖 TCP 首部和 TCP 数据**，而**IP 首部中的校验和只覆盖 IP 的首部**，**不覆盖 IP 数据报中的任何数据**，TCP 校验和、IP 校验和的**计算方法是基本上一致的**，除了**计算的范围不同**。
3. **TCP 的校验和是必需的**，而**UDP 的校验和是可选的**，TCP 和 UDP**计算校验和时**，都**要加上一个 12 字节的伪首部**。
4. **伪首部的数据都是从 IP 数据报头获取的**，其**目的是让 TCP 检查数据是否已经正确到达目的地**，只是**单纯为了做校验用的**，其数据结构如下图所示：
   ![](https://notebook.ricear.com/media/202206/2022-06-04_201702_388188.png)

   ```c++
   struct {
       unsigned long saddr;    //  源地址
       unsigned long daddr;    //  目的地址
       char mbz;   //  强制置空
       char ptcl;  //  协议类型
       unsigned short tcpl;    //  TCP 长度
   } psd_header;
   ```

   1. 伪首部共有**12 字节**（前 96bits），包含**源 IP 地址**、**目的 IP 地址**、**保留字节**（置 0）、**传输层协议号**（TCP 是 6）和**TCP 报文长度**（报头 + 数据）。
   2. 伪首部是为了**增加 TCP 校验和的检错能力**，如**检查 TCP 报文是否收错了地方**（目的 IP 地址）、**传输层协议是否选对了**（传输层协议号等）。
   3. **TCP 的校验和计算方式与 UDP 一样**，但是**伪首部的结构和 UDP 不太一样**，应该把伪首部的第 4 个字段中的 17 改为 6（TCP 的协议号是 6），第 5 个字段中的 UDP 长度改为 TCP 长度。

### 2.5 数据报重排序

1. **TCP 报文段是通过 IP 协议进行传输的**，**IP 数据报在传输过程中可能被[分片](#1-1-IP-协议分片)**，并**可能以乱序方式到达接收方**，因此**TCP 报文段的到达也可能会失序**，如果必要，**TCP 将对收到的数据进行重新排序**，**将收到的数据以正确的顺序交给应用层**。
2. 这种**接收有序号的**、**乱序到达的数据包**，**并重建源数据流的过程叫做重组**，**只有将数据包重组以后**，**才能还原一次完整的 TCP 会话**，TCP 会话在重组的过程中可能会遇到**乱序**、**重传**、**数据重叠**的问题。
3. TCP/IP 协议栈的重组采用**缓存法**，**他将分片缓存并拼接到适当位置**，**在全部分片到达之后**，**构建重组的数据包以供下一步处理**。
4. **序列号是为了保证 TCP 数据包的按顺序传输来设计的**，**可以有效的实现 TCP 数据的完整传输**，**特别是在数据传输过程中出现错误的时候可以有效的进行错误修正**，**在 TCP 会话的重新组合过程中我们需要按照数据包的序列号对接收到的数据包进行排序**。
5. 下面将以[伯克利套接字](https://zh.wikipedia.org/wiki/Berkeley%E5%A5%97%E6%8E%A5%E5%AD%97)（Berkeley sockets, BSD sockets）为例对 TCP 会话重组的原理进行详细阐述：

   > 伯克利套接字是一种应用程序接口，允许不同主机或者同一个计算机上的不同进程之间的通信，他支持多种 I/O 设备和驱动，但是具体的实现依赖于具体的操作系统，这种接口对于 TCP/IP 是必不可少的，所以是互联网的基础技术之一，他最初是由加州伯克利大学为 Unix 系统开发出来的，所有现代操作系统都实现了伯克利套接字接口，现在已经是连接互联网的标准接口了。
   >

   1. 实现里面主要设计两个队列，其中队列 1 存放顺序到来的数据包，队列 2 存放失序到来的数据包。
   2. 假设队列 1 里最后一个数据包 `seq = 100, len = 100`，则下一个数据包可能有以下多种情况：
      ![](https://notebook.ricear.com/media/202206/2022-06-06_173254_724726.png)
      1. 顺序到来的数据包：
         1. 数据包 ② 的 `seq2 = seq1 + len1`，因此这个报文是 ① 报文的预期后续报文，将此报文追加到正常报文队列即可。
      2. 重复数据包：
         1. ③④⑤ 都包含在 ① 之中，应该被丢弃。
      3. 重叠数据包：
         1. ⑥ 的前部分 150 ~ 199 与 ① 重叠，而后部分 200 ~ 249 则是新数据，此时应该对这个报文作如下处理：
            1. 计算重复字节数，`seq1 + len1 - seq2 = 100 + 100 - 150 = 50`，即这个报文段前 50 个字节是重复的，这部分需要丢弃。
            2. 截取报文段新数据，即只保留字节序号段 200 ~ 249。
            3. 重新设置这个报文段 `seq2 = 200, len2 = 50`。
            4. 将重新设置后的报文段加入顺序队列。
      4. 提前到达的报文：
         1. 数据包 `seq2 > seq1 + len1`，是提前到来的报文，此时应该将这个报文放置到失序报文段队列存储起来，以备后续重组使用。
   3. 这样直到 TCP 断开这个 socket 的连接，此时将正常报文队列和失序报文队列中的数据合并起来，完成重组，即取出正常报文队列最后一个报文的 `seq` 和 `len`，然后在失序报文队列中查找属于他的后续报文，至于说该报文是否可以作为正常报文队列的后续报文，处理过程和前面的步骤一样。

### 2.6 流量控制

流量控制相关的内容详见[1.1.3 流量控制](https://ricear.com/project-26/doc-303)。

## 参考文献

1. 《TCP/IP 详解 卷 1：协议》。
2. [为什么 TCP/IP 协议会拆分数据](https://draveness.me/whys-the-design-tcp-segment-ip-packet)。
3. [一线互联网大厂面试关于 TCP 连接的相关问题](https://zhuanlan.zhihu.com/p/166344464)。
4. [TCP 三次握手](http://timd.cn/network/tcp)。
5. [详解 TCP 超时与重传机制](https://zhuanlan.zhihu.com/p/101702312)。
6. [浅谈 TCP 协议（一）](https://hanblog.fun/2020/06/24/2020-6-24-tcp)。
7. [TCP/IP 卷一:71---TCP 超时与重传之（超时与重传总体概述、系统超时重传阀值、一个简单的超时与重传案例）](https://blog.csdn.net/qq_41453285/article/details/104082482)。
8. [TCP/IP 卷一:73---TCP 超时与重传之（基于计时器的重传）](https://blog.csdn.net/qq_41453285/article/details/104092415)。
9. [TCP 的快速重传机制](https://www.jianshu.com/p/62940de97ca5)。
10. [TCP 的重传机制](https://www.itqiankun.com/article/1630566929059)。
11. [TCP 的那些事 | D-SACK](https://blog.csdn.net/u014023993/article/details/85041321)。
12. [TCP 报文送达确认 ACK](https://www.cnblogs.com/alifpga/p/7686742.html)。
13. [TCP 校验和（Checksum）的原理和实现_造梦先森 Kai 的专栏-程序员宅基地](https://www.cxyzjd.com/article/qq_15437629/79183076)。
14. [TCP 报文重组方式](https://onestraw.github.io/cprogram/tcp-packet-reassemble)。
15. [TCP 重组原理及实现](https://www.cnblogs.com/realjimmy/p/12933690.html)。
16. [伯克利套接字（BSD Socket）](https://blog.csdn.net/blueman2012/article/details/6693605)。
17. 《计算机网络-第 7 版-谢希仁》。
