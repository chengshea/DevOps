#!/bin/bash

#arr=(kubernetes node1 node2)  #${arr[@]}
exec=1


start(){
   echo "=============开始启动 $1 ================"
   /usr/bin/VBoxManage   startvm  $1   --type headless
}

stop(){
   echo "=============即将停止 $1 ================"
  /usr/bin/VBoxManage controlvm  $1  poweroff

  echo "=============关闭本机 etcd ================"
  ps -ef | grep etcd | grep -v grep  | awk '{print $2}'  | xargs kill -9
}


status=$(VBoxManage list runningvms)

[ -n "$status" ] || { echo "list:$status没有虚拟机在运行" && exec=0  ;}

run(){
	for i in ${@:2}
	do 
		echo $i
		$1 $i
	done
}


if [ "1" -eq "$exec" ]
then
	 echo "runningvms:started  进行停止操作"
	 run  stop $(/usr/bin/VBoxManage list runningvms | awk '{print $2}')
else
	echo "runningvms:stop 进行启动操作"
	run  start  $(/usr/bin/VBoxManage list vms | awk '{print $2}')
fi



:<<EOF
函数做为参数,接收参数用$@,特别是数组等情况下
${@:2}  从第二个参数起
EOF