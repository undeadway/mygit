#!/bin/bash

# 首先判断是否在 git 工程的文件夹下
[ -e ".git" ]
isGitPrjFolder=$?
if [[ $isGitPrjFolder -ne 0 ]]; then
	pwd=`pwd`
	echo "$pwd 不是一个 git 仓库"
	exit
fi

inputStr="$@ " # 为了正则表达式的正确运行，最后加一个空格
configFile="${HOME}/.mygit.config"

# 获得工程（文件夹）名
getPrjName () {
	pwd=`pwd`
	echo ${pwd##*/} 
}

# 获得从 shell 脚本处获得的参数
getInputPara(){
	paraVal=`expr "$inputStr" : "$1"`
	size=`expr length "$paraVal"`
	cut=`expr $size - $2`
	start=`expr $2 + 1`
	sub=`expr substr "$paraVal" $start $cut`
	echo "$sub"
}

# 执行 pull 操作
doPull () {
	git pull $1 $2
}

# 执行 push 操作
doPush () {
	git add .
	git commit -m "$4"
	if [ $2 = $3 ]; then
		git push "$1" "$3" -u "$5" -p "$6"
	else
		git push "$1" "$2":"$3" -u "$5" -p "$6"
	fi
}

if [ ! -n "$1" ] || [ $1 = '-?' ]; then
	echo 'help'
	exit
elif [ $1 = 'set' ]; then
	[ -e $configFile ]
	confFileExists=$?
	if [[ $confFileExists -ne 0 ]]; then
		touch $configFile
	fi

	# 获得参数信息
	repository=`getInputPara '.*\(\-r [^\-]* \)' 3` # 仓库名
	username=`getInputPara '.*\(\-U [^\-]* \)' 3` # 用户名
	password=`getInputPara '.*\(\-P [^\-]* \)' 3` # 密码
	project=`getInputPara '.*\(\-p [^\-]* \)' 3` # 项目名

	# 至少得有仓库名、用户名、密码
	if [ ! -n "$repository" ]; then
		echo "请输入仓库名（参数 -r）"
		exit
	fi
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
	readLine=''

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
	# 参数至少得包含仓库名
	if [ ! -n "$2" ]; then
		echo "请输入仓库名"
		exit
	fi

	# 获得参数信息
	repository=$2 # 仓库
	project=`getInputPara '.*\(\-p [^\-]* \)' 3` # 项目名
	username=`getInputPara '.*\(\-U [^\-]* \)' 3` # 用户名
	password=`getInputPara '.*\(\-P [^\-]* \)' 3` # 密码 
	lbranch=`getInputPara '.*\(\-lb [^\-]* \)' 4` # 本地分支
	rbranch=`getInputPara '.*\(\-rb [^\-]* \)' 4` # 远程分支
	origin=`getInputPara '.*\(\-o [^\-]* \)' 3` # 远程主机名
	commit=`getInputPara '.*\(\-m [^\-]* \)' 3` # 提交备注
	readExist=false

	if [ ! -n "$project" ]; then
		project=`getPrjName`
	fi

	if [ ! -n "$commit" ]; then
		_date=`date +%Y-%m-%d`
		_time=`date +%H:%M:%S`
		commit="$_date $_time 的提交"
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
			echo $lbranch, ${array[4]}, $rbranch, ${array[5]}
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

	if [ ! -n "$origin" ]; then
		origin='origin'
	fi

	if [ readExist = false ]; then
		echo "仓库：${repository} 、项目：${project} 的配置未定义，请先定义配置。"
		exit
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
