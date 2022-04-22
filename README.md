# 目的

一个在每次命令行操作 git 的时候，不需要重复输入用户名、密码的脚本 
操作包括 git 的全部操作，以及自定义操作

# 注意

 1. 该脚本使用前，必须先 cd 到对应的工程目录下

# 操作

| 命令名 | 参数 | 参数解释 | 必须 |
| -- | -- | -- | -- |
| set | repository | 仓库 | | Y |
| | username | 用户名 | Y |
| | password | 密码 | Y |
| | project | 项目 | Y |
| | lbranch | | 本地分支 | N（默认值：master） |
| | rbranch | 远程分支 | N（默认值：master） |
| pull | repository | 仓库 | Y |
| | project | 项目 | Y |
| | -o origin | 远程仓库别名 | N |
| | -rb lbranch | 远程仓库 | N |
| push | repository | 仓库 | Y |
| | project | 项目 | | Y |
| | -o origin | 远程仓库别名 | N |
| | -lb lbranch | 本地仓库 | N |
| | -rb lbranch | 远程仓库 | N |
| | -c commit | 提交备注 | N |