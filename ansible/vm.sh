#!/bin/bash

exec=开启


start(){
   echo "=============开始启动 $1 ================"
   /usr/bin/VBoxManage   startvm  $1   --type headless
}

stop(){
   echo "=============即将停止 $1 ================"
  /usr/bin/VBoxManage controlvm  $1  poweroff
}

run(){
	for i in ${@:2}
	do 
		echo $i
		$1 $i
	done
}

def(){
	if [ "关闭" == "$exec" ]
	then
		 echo "进行停止操作"
		 echo "=============开启本机 etcd ================"
         ps -ef | grep etcd | grep -v grep  | awk '{print $2}'  | xargs kill -9
		 run  stop $(/usr/bin/VBoxManage list runningvms | awk '{print $2}')
	else
		echo "进行启动操作"
		run  start  $(/usr/bin/VBoxManage list vms | awk '{print $2}')
	fi
}


status=$(VBoxManage list runningvms)

echo "检测虚拟机运行状态..."

[ -n "$status" ] || { exec=关闭  ;}

echo -e "运行状态如下:\n$status"

read  -t 6 -n 1 -p "请输入指令o开启,c关闭,目前状态 $exec": val

[ -n "$val" ] || { echo -e "\n没有输入指令,退出" && exit 1 ;}

case $val in
	o|O|0 )
        [ "开启" != "$exec" ] || { echo -e "\n虚拟机是开启状态,退出" && exit 1;}
        echo "runningvms:stop 进行启动操作"
	    run  start  $(/usr/bin/VBoxManage list vms | awk '{print $2}')
		;;
	c|C )
        [ "关闭" != "$exec" ] || { echo -e "\n虚拟机是关闭状态,退出" && exit 1;}
         echo "=============开启本机 etcd ================"
         ps -ef | grep etcd | grep -v grep  | awk '{print $2}'  | xargs kill -9
         echo "runningvms:started  进行停止操作"
	     run  stop $(/usr/bin/VBoxManage list runningvms | awk '{print $2}')
		;;		
	* )
	   echo "执行默认操作；即虚拟机关闭状态将执行停止操作,反之"	
	   def
esac






:<<EOF
函数做为参数,接收参数用$@,特别是数组等情况下
${@:2}  从第二个参数起
EOF