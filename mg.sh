#!/bin/bash

##########################
###
### 目的：一个在每次命令行操作 git 的时候，不需要重复输入用户名、密码的脚本
### 操作包括 git 的全部操作，以及自定义操作
###
### 注意：
### 1. 该脚本使用前，必须先 cd 到对应的工程目录下
###
###
###
### 自定义操作
### 命令名  参数          参数解释          必须
### set     repository      仓库             Y
###         username      用户名           Y
###         password      密码              Y
###         project        项目              Y
###         lbranch        本地分支          N（默认值：master）
###         rbranch        远程分支          N（默认值：master）
### pull     repository    仓库               Y
###          project        项目              Y
###         -o origin       远程仓库别名      N
###         -rb lbranch     远程仓库         N
### push    repository      仓库             Y
###          project        项目              Y
###         -o origin       远程仓库别名      N
###         -lb lbranch     本地仓库          N
###         -rb lbranch     远程仓库          N
###         -c commit     提交备注           N
###########################

inputStr="$@ " # 为了正则表达式的正确运行，最后加一个空格
configFile="${HOME}/.mygit.config"

getPara(){
	paraVal=`expr "$inputStr" : "$1"`
	size=`expr length "$paraVal"`
	cut=`expr $size - $2`
	start=`expr $2 + 1`
	sub=`expr substr "$paraVal" $start $cut`
	echo "$sub"
}

doPull () {
	git pull $1 $2
}

doPush () {
	git add .
	git commit -m "$4"
	git push $1 $3
}

if [ ! -n "$1" ]; then
	echo "请输入参数"
	exit
fi

if [ $1 = '-?' ];then
	echo 'help'
elif [ $1 = 'set' ]; then
	[ -e $configFile ]
	confFileExists=$?
	if [[ $confFileExists -ne 0 ]]; then
		touch $configFile
	fi

	# 至少得有仓库名、用户名、密码和项目名
	if [ ! -n "$1" ]; then
		echo "请输入仓库名"
		exit
	fi
	if [ ! -n "$2" ]; then
		echo "请输入用户名"
		exit
	fi
	if [ ! -n "$3" ]; then
		echo "请输入密码"
		exit
	fi
	if [ ! -n "$4" ]; then
		echo "请输入项目名"
		exit
	fi

	# 获得配置信息
	repository=$2 # 仓库名
	username=$3 # 用户名
	password=$4 # 密码
	project=$5 # 项目名
	lbranch=$6 # 本地分支
	rbranch=$7 # 远程分支
	readLine=''

	# 在没有输入的时候，设置默认值
	if [ ! -n "$lbranch" ]; then
		lbranch='master'
	fi

	if [ ! -n "$rbranch" ]; then
		rbranch=$lbranch
	fi
	# 先判断 repository 是否存在
	while read line
	do
		if [ "$line" = '' ]; then
			continue
		fi

		array=(${line// / })
		if [ "${array[0]}" = "$repository" ] && [ "${array[3]}" = "$project" ]; then
			readLine=$line
			break
		fi
	done < $configFile

	output="${repository} ${username} ${password} ${project} ${lbranch} ${rbranch}"
	if [ ! -n "$readLine" ]; then
		#不存在则直接添加数据到文件
		echo "$output" >> $configFile
	else
		# 如果存在，则提示是否需要覆盖
		read -p "仓库：${repository} 、项目：${project} 的配置已经存在，是否要覆盖？（y/n）：" input
			case $input in
				[yY]) # 大小写的 Y 都可以
					sed -i "s/$readLine/$output/g" $configFile
					;;
				# y 以外，不管输入什么都当是不要处理
			esac
	fi
else
	# 参数至少得包含仓库名项目名
	if [ ! -n "$2" ]; then
		echo "请输入仓库名"
		exit
	fi
	if [ ! -n "$3" ]; then
		echo "请输入项目名"
		exit
	fi

	# 定义配置
	repository=$2 # 仓库
	project=$3 # 项目
	username='' # 用户名
	password='' # 密码 

	lbranch=`getPara '.*\(\-lb [^\-]* \)' 4` # 本地分支
	rbranch=`getPara '.*\(\-rb [^\-]* \)' 4` # 远程分支
	origin=`getPara '.*\(\-o [^\-]* \)' 3` # 远程仓库别名
	commit=`getPara '.*\(\-m [^\-]* \)' 3` # 提交备注

	readExist=false

	if [ ! -n "$commit" ]; then
		dat=`date +%Y-%m-%d~%H:%M:%S`
		commit="$dat 的提交"
	fi

	while read line
	do
		if [ "$line" = '' ]; then
			continue
		fi

		array=(${line// / })
		if [ "${array[0]}" = "$repository" ] && [ "${array[3]}" = "$project" ]; then
			readExist=true
			username=${array[1]}
			password=${array[2]}

			# 如果没有传入相关参数，则采用默认配置好的值
			if [ ! -n "$lbranch" ]; then
				lbranch=${array[4]}
			fi
			if [ ! -n "$rbranch" ]; then
				rbranch=${array[5]}
			fi
			if [ ! -n "$origin" ]; then
				origin=${array[6]}
			fi
			break
		fi
	done < $configFile

	if [ readExist = false ]; then
		echo "仓库：${repository} 、项目：${project} 的配置未定义，请先定义配置。"
		exit
	fi

	if [ $1 = 'pull' ]; then
		# 采用函数的原因，是也可以获得返回值等方式
		# 且每个处理各自独立，不会产生代码污染
		doPull $origin $rbranch 
	elif [ $1 = 'push' ]; then
		doPush $origin $lbranch $rbranch $commit
	else
		echo '非法的操作'
	fi
fi
