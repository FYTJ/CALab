# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2025-10-17
### Added
- 新增除法器模块
    - **除0在LoongArch指令集中是未定义行为，在该除法器中采用了和risc-v相同的处理：商为0xFFFF_FFFF，余数与被除数相同**

## [Unreleased] - 2025-10-16
### Fixed
- 修复部分译码错误
- 修复写内存数据错误
    - **注意:** 读写内存接口含义如下：
        - data_sram_we: 按字节写，定义方式与risc-v的Write_Strb相同
        - **data_sram_wdata: 需要将数据移动到待写入位置处，其余位置补0**

## [Unreleased] - 2025-10-15
### Added
- 新增alu运算、乘除法指令译码
    - 新增乘法器操作码: mul_op = {inst_mulh_wu, inst_mulh_w, inst_mul_w}
    - 新增除法器操作码: div_op = {inst_mod_wu, inst_mod_w, inst_div_wu, inst_div_w}
- 新增跳转、访存指令译码
    - 新增访存操作码: load_op = {inst_st_w, inst_st_h, inst_st_b, inst_ld_hu, inst_ld_bu, inst_ld_w, inst_ld_h, inst_ld_b}
- 新增简单乘除法器和完整数据通路
    - **注意：简单乘除法器的接口和要求不一致**

## [exp9] - 2025-10-14
### Added
- 初始版本发布
- 实现基于LoongArch的五级流水线CPU