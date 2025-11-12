# Journal

该文件记录了部分设计思路

## Handshake is All You Need
&emsp;&emsp;在流水级间，或者在更抽象的子系统间，使用握手信号进行交互，其目的是将所有与交互相关的信号和操作使用一个逻辑模版进行实现，换言之，将交互实现和流水线或子系统的内部实现解耦。

&emsp;&emsp;以A需要向B发送数据为例，需要两个握手信号和一个数据信号：
- A_valid:&ensp; 表示A当前发送的数据是有效的；
- B_ready:&ensp; 表示B当前准备好接收数据；
- data:&ensp; A当前发送的数据。

&emsp;&emsp;data是一个wire类型的信号，即当A赋值data时，B可以立即"看到"data"的值。但此时B不能使用data进行运算或控制等操作，必须等到**握手成功**，即A_valid和B_ready同时拉高时，才能使用data信号。

&emsp;&emsp;为什么如此呢？考虑如下两个情况：
- (1)&ensp;考虑A对data的赋值不在一个时钟周期内完成，因此发生一次赋值后data信号发生变化，但此时data值并非完整的，如果B使用了此时的值，将发生错误；
- (2)&ensp;考虑B处于阻塞状态，即B需要等待若干个时钟周期之后才能对data进行操作，此时B的寄存器中包含有效数据。而此时A_valid拉高，data将写入B的寄存器，从而导致B中寄存器中原有效数据被覆盖，发生错误。

### 流水级间的握手
&emsp;&emsp;首先我们回顾最基础的握手设计。假设有连续的三个流水级A、B、C。

&emsp;&emsp;**首先，我们需要约定：A和B之间的流水寄存器属于B，即在顶层，所有的流水寄存器名均为B_xxx。**

&emsp;&emsp;在流水级间有如下几个控制信号
```verilog
input in_valid,
input out_ready,
output in_ready,
output reg out_valid
```
&emsp;&emsp;在流水级内部有控制信号
```verilog
wire ready_go;
```
&emsp;&emsp;下面以B为例给出控制信号的具体语义。
- in_ready: in_ready拉高表示当前周期B可以接收上一级的数据。可能此时B中是空泡，或者B在当前周期已经做完了相应任务，将数据发往下一级C。
- out_valid: out_valid拉高表示B当前向C的流水寄存器中输出的数据是有效的。
- in_valid: in_valid拉高表示当前周期内B级内的数据是有效的。通常而言，B_in_valid := A_out_valid，即如果A在上一时钟周期输出的数据有效，则B在当前周期拿到的数据有效。
- out_ready: out_ready拉高表示当前C准备好接收B的数据。通常而言，B_out_ready := C_in_ready。
- ready_go: ready_go是一个内部信号，ready_go拉高表明B在当前流水级已经完成了相应任务。值得注意的是，即使B_ready_go = 1，B也不一定可以将数据发送给C，因为C_in_ready可能为0。此外，当B_in_valid = 0时，B_ready_go也为1，因为空泡是可以直接向下传递的(从语义上的理解是：如果当前没有任务，也可以视为立即完成了任务)。设置ready_go信号的目的是通过ready_go就可以控制所有的阻塞逻辑，该功能将在后文详细阐述。

&emsp;&emsp;**理解握手信号的关键在于：a.理解所有的信号的含义都是基于数据的；b.两个流水级间通过ready和valid进行控制，ready是组合逻辑，valid是时序逻辑**

&emsp;&emsp;在该控制信号设计下，相应信号的赋值可直接采用以下模版
```verilog
wire ready_go = !in_valid || !stall_cond1 && !stall_cond2 && ...;

assign in_ready = ~rst & (~in_valid | ready_go & out_ready);

always @(posedge clk) begin
    if (rst) begin
        out_valid <= 1'b0;
    end
    else if (out_ready) begin
        out_valid <= in_valid & ready_go;
    end
end
```

&emsp;&emsp;下面说明如何仅使用ready_go信号控制阻塞。在五级流水线下，如果ID级判断到了写后读(RAW)需要阻塞，只需要将ready_go置零。即
```verilog
wire ready_go = !in_valid || !load_use_sign;
```
&emsp;&emsp;此时in_ready自然被置零，从而在ID之前的所有流水级全部被阻塞；同时out_valid置零表示发给EX的数据无效，空泡将继续向后流动。

### 模块间的握手
- 举例背景

&emsp;&emsp;对于模块而言，每个模块只能看到自身内部的状态，而不可见其他模块的状态。即，假设有两个独立模块A和B，B的状态A完全不可见，同理A的状态B完全不可见。下面以CPU和乘法器为例，说明模块之间的握手情况。具体而言，CPU采用5级流水：IF, ID, EX, MEM, WB；乘法器采用2级流水：M1, M2。在EX阶段，CPU向M1发送乘法操作码和操作数；在MEM阶段，M2向CPU返回计算结果。

- 设计中的组合逻辑环

&emsp;&emsp;按照前述流水控制，EX_ready_go表示EX级任务是否完成，若EX级握手不成功，则EX级需要被阻塞，因此有
```verilog
// 在EX级内
wire ready_go = to_mul_req_valid && from_mul_req_ready;
wire to_mul_req_valid = in_valid;  // 在M1视角下，该信号为from_cpu_req_valid
```
&emsp;&emsp;由于模块间设计的对称性，在M1级内，ready_go信号也应赋值为握手完成(fire)
```verilog
// 在M1级内
wire ready_go = to_mul_resp_valid && from_mul_resp_ready;
wire from_cpu_req_ready = in_ready;  // 在CPU视角下，该信号为to_mul_req_ready
```
&emsp;&emsp;因此会遇到组合逻辑环(记信号a依赖于信号b为'a <- b')
```plain
M1_ready_go <- from_cpu_req_ready <- M1_in_ready <- M1_ready_go
```
&emsp;&emsp;下面给出两种解决思路。

#### 方案1:将M1_ready_go与握手信号解耦
&emsp;&emsp;该思路放弃CPU和乘法器模块的对称性，将CPU视作主模块，乘法器视作从模块，进而将从模块中所有ready_go信号与握手信号解耦。

&emsp;&emsp;在M1中，如果ready_go不被握手信号控制，为了控制M1的阻塞，M1必须知道M2当前是否有效或握手有无完成，只有当M2握手完成，M1才能将数据传输给M2。

&emsp;&emsp;然而，这样的设计语义不是完善的。首先，交互中的两模块存在主从关系并非通用的方法，两模块中ready_go信号含义不同是不合理的。更重要的是，M1级的阻塞依赖于M1之后流水级与CPU的交互行为。当前情况比较简单，EX与M1完全对应，MEM与M2完全对应，不存在流水级不对齐的情况；同时由于WB级不存在阻塞，可以认为MEM级可立即接受M2的回传数据，因此可以将from_cpu_resp_ready恒置为1，这种特殊的信号设置不能用于通用的握手信号设计。一旦“从模块”流水级数增加，再加入流水级非对齐的情况，对“从模块”阻塞的控制信号将会非常复杂。

#### 方案2:将from_cpu_req_ready与in_ready解耦
&emsp;&emsp;为什么这种思路是合理的呢？我们不妨考虑一种比“从模块”流水线非对齐更复杂的情况。

&emsp;&emsp;对于更复杂的设计，我们应该抛弃“流水线”、“子模块”的概念，将“流水线”仅视作一种优化技术，而将整个设计视作由多个子系统(subsystem)组成。这样的理解，要求我们必须维持子系统中信号的对称性。考虑CPU和内存为两个子系统，CPU和内存哪个作为“从模块”都不合适，二者应当视作彼此独立的子系统。

&emsp;&emsp;作为示例，我们考虑两条独立的流水线，假设EX1向EX2发送信息，MEM1从MEM2接收信息。现在考虑EX2中的in_ready信号，该信号表示EX2是否准备好接收ID2的数据，而握手是EX2级的内部任务，因此我们可以立即发现，to_1_req_ready = in_ready的赋值是不合理的。我们再考虑从EX2向MEM2的数据传输，如果该数据通路被阻塞，则握手成功后EX2接收到的数据将无处可存放。MEM2无法接受数据，意味着EX2的out_ready=0，因此正确的逻辑是to_1_req_ready = out_ready。因为out_ready是后续流水级产生的数据，因此一定不会出现组合逻辑环。

### 总结
&emsp;&emsp;综上所述，本文制定了一套标准的子系统间的握手控制设计，建议在当前项目中所有子系统交互控制均使用文中描述的接口信号和逻辑。上文提到的——a.将设计视作子系统的组合，将流水线仅作为优化技术；b.从子模块到两条流水线的抽象模型明确握手信号的赋值——思路在明确信号语义和赋值过程中起到非常重要的作用。一旦使用子系统模型，得到保持原有ready_go设计，以及使用out_ready作为req_ready的结论自然得令人惊奇。