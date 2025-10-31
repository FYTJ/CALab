# 接口规范

## 通用接口说明
- 时钟信号命名均采用clk或clock
- 复位信号命名均采用rst或reset，**高电平有效**
```verilog
input clk,
input rst
```

## 访存接口说明
- 与store指令相关的接口含义如下：
    - data_sram_we: 按字节写，定义方式与risc-v的Write_Strb相同
    - **data_sram_wdata: 需要将数据移动到待写入位置处，其余位置补0**

## 流水级间接口说明
- 所有子系统流水级间均应采用该接口规范
```verilog
input in_valid,
input out_ready,
output in_ready,
output reg out_valid
```
- 所有子系统流水级内应包含信号**ready_go**，表示当前流水级是否完成任务
    - 所有阻塞逻辑均通过ready_go实现
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

## 乘除法器接口说明
- 乘除法器之间的数据传输握手均使用以下信号，乘除法器在接口命名上略有差异：
```verilog
wire from_mul/div_req_ready;
wire to_mul/div_req_valid;
wire to_mul/div_resp_ready;
wire from_mul/div_resp_valid;
```
### 乘法器
- mul_op: 乘法器操作码
- x: 乘法器输入操作数1
- y: 乘法器输入操作数2
- result: 乘法器输出结果(64 bits)

### 除法器
- io_in_bits_divOp: 除法器操作码
- io_in_bits_dividend: 被除数
- io_in_bits_divisor: 除数
- io_out_bits_quotient: 商
- io_out_bits_remainder: 余数

## 控制状态寄存器(CSR)接口说明
- csr_re: CSR读取使能信号
- csr_addr: CSR地址
- csr_rvalue: CSR读取数据
- csr_we: CSR写入使能信号
- csr_wmask: 32位写入掩码，每个bit对应一个字节，为1时表示该字节需要写入
- csr_wvalue: CSR写入数据
- wb_ex: 异常提交信号
- wb_ecode: 异常类型一级编码
- wb_esubcode: 异常类型二级编码
- wb_pc: 异常发生时的PC值以及ADEF异常发生时的错误PC值
- wb_addr: ALE异常发生时的错误地址
- etrn_flush: 异常返回时流水线冲刷信号
- ex_entry: 异常处理入口地址
- has_int: 是否有中断请求
