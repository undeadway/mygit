#!/bin/bash

version='0.0.1'
inputStr=" $@ " # 为了正则表达式的正确运行，前后都加一个空格
configFile="${HOME}/.mygit.config"

# 获得工程（文件夹）名
getPrjName () {
	str=`pwd`
	echo ${str##*/} 
}

# 获得从 shell 脚本处获得的参数
getInputPara(){
	paraVal=`expr "$inputStr" : "$1"`
	size=`expr length "$paraVal"`
	cut=`expr $size - $2`
	start=`expr $2 + 1`
	sub=`expr substr "$paraVal" $start $cut`
	sub=`echo $sub | xargs` # 去除字符串两端的空白
	echo "$sub"
}

# 执行 pull 操作
doPull () {
	git pull $1 $2
}

# 执行 push 操作
doPush () {
	# 判断 git 的状态，如果已经是最新的，直接提交
	status=`git status | grep "git add <"`
	if  [[ $status != '' ]]; then
		git add .
		git commit -m "$4"
	fi

	if [ $2 = $3 ]; then
		git push "$1" "$3"
	else
		git push "$1" "$2":"$3"
	fi

	# 如果需要的话，输入密码
	# TODO
}

# 一些预处理
# 获得帮助
if [ ! -n "$1" ] || [ $1 = '-?' ]  || [ $1 = '-h' ] || [ $1 = '--help' ]; then
	echo 'help'
	exit
fi
# 获得版本号
if [ $1 = '-v' ] || [ $1 = '--version' ]; then
	echo $version
	exit
fi

# 首先判断是否在 git 工程的文件夹下
[ -e ".git" ]
isGitPrjFolder=$?
if [[ $isGitPrjFolder -ne 0 ]]; then
	str=`pwd`
	echo "$str 不是一个 git 仓库"
	exit
fi

if [ $1 = 'status' ]; then
	git status
elif [ $1 = 'set' ]; then
	[ -e $configFile ]
	confFileExists=$?
	if [[ $confFileExists -ne 0 ]]; then
		touch $configFile
	fi

	# 获得参数信息
	username=`getInputPara '.*\(\-U [^\-]* \)' 3` # 用户名
	password=`getInputPara '.*\(\-P [^\-]* \)' 3` # 密码

	# 必须得有用户名、密码
	if [ ! -n "$username" ]; then
		echo "请输入用户名（参数 -U）"
		exit
	fi
	if [ ! -n "$password" ]; then
		echo "请输入密码（参数 -P）"
		exit
	fi

	lbranch=`getInputPara '.*\(\-lb [^\-]* \)' 4` # 本地分支
	rbranch=`getInputPara '.*\(\-rb [^\-]* \)' 4` # 远程分支
	origin=`getInputPara '.*\(\-o [^\-]* \)' 3` # 远程主机名

	# 在没有输入的时候，设置默认值
	if [ ! -n "$project" ]; then
		project=`getPrjName`
	fi
	
	if [ ! -n "$lbranch" ]; then
		lbranch='master'
	fi

	if [ ! -n "$rbranch" ]; then
		rbranch=$lbranch
	fi

	if [ ! -n "$origin" ]; then
		origin="origin"
	fi

	# 先判断 repository 是否存在
	readLine=`cat "$configFile" | grep -E "$repository .* $project"`
	output="${project} ${username} ${password} ${lbranch} ${rbranch} ${origin}"
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
	# 获得参数信息
	project=`getPrjName` # 项目名
	username=`getInputPara '.*\(\-U [^\-]* \)' 3` # 用户名
	password=`getInputPara '.*\(\-P [^\-]* \)' 3` # 密码 
	lbranch=`getInputPara '.*\(\-lb [^\-]* \)' 4` # 本地分支
	rbranch=`getInputPara '.*\(\-rb [^\-]* \)' 4` # 远程分支
	origin=`getInputPara '.*\(\-o [^\-]* \)' 3` # 远程主机名
	commit=`getInputPara '.*\(\-m [^\-]* \)' 3` # 提交备注

	if [ ! -n "$commit" ]; then
		_date=`date +%Y-%m-%d`
		_time=`date +%H:%M:%S`
		commit="$_date $_time 的提交"
	fi

	readLine=`cat "$configFile" | grep -E "$project"`
	if [ ! -n "$readLine" ]; then
		echo "项目：${project} 的配置未定义，请先定义配置。"
		exit
	fi

	array=(${readLine// / })

	# 配置顺序：project username password lbranch rbranch origin
	username=${array[1]}
	password=${array[2]}

	# 如果没有传入相关参数，则采用默认配置好的值
	if [ ! -n "$lbranch" ]; then
		lbranch=${array[3]}
	fi
	if [ ! -n "$rbranch" ]; then
		rbranch=${array[4]}
	fi
	if [ ! -n "$origin" ]; then
		if [ ! -n  "${array[5]}" ]; then
			origin='origin' # 在没有参数输入和配置的情况下，origin 采用默认值
		else
			origin=${array[5]}
		fi
	fi

	# 采用函数的原因，是也可以获得返回值等方式
	# 且每个处理各自独立，不会产生代码污染
	if [ $1 = 'pull' ]; then
		doPull "$origin" "$rbranch" 
	elif [ $1 = 'push' ]; then
		# 检查是否处于最新，如果是，则不提交
		doPush "$origin" "$lbranch" "$rbranch" "$commit" "$username" "$passwor"
	else
		echo '非法的操作'
	fi
fi
