1.创建工程。
1.1 新建vivado工程
1.2 导出目标工程的bd文件。
cd [get_property directory [current_project]]
write_bd_tcl -no_ip_version -force ../src/bd/system.tcl
1.3 复制对应的system.tcl和ip文件到新工程。
1.4 恢复bd文件。
cd [get_property directory [current_project]]
source ../src/bd/system.tcl
1.5 添加管脚映射文件.xdc。
1.6 编译工程。

2.导出工程上传。

cd [get_property directory [current_project]]
write_bd_tcl -no_ip_version -force ../src/bd/system.tcl
write_project_tcl -use_bd_files -force ../project.tcl

3.导出dcp网表
disable掉xdc文件。
-flatten_hierarchy full
-mode out_of_context
执行Run Synthesis完成后打开Open Synthesis Design
cd [get_property directory [current_project]]
write_checkpoint ../src/dcp/isp_top.dcp
