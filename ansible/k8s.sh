#!/bin/sh


etcd=/opt/kubernetes/script
base=/opt/ansible

KUBE_APISERVER=https://192.168.56.107:6443

checkStatus(){
	num=$(VBoxManage list runningvms | wc -l)
    [ "$num" -ge 4 ] || { echo "虚拟机运行数目:$num ,退出脚本" && exit 1;}
	arr=$(kubectl get nodes)
	str=$(echo $arr | awk '{print $2}' )
	[ "$str" = "STATUS" ] || { echo "获取不到status,返回异常如下:" && echo $arr && exit 1;}
	echo $arr | awk  '{len=split($0,a," ");for(i=1;i<=len;i=i+5) print a[i]"\t"a[i+1]"\t"a[i+2]"\t"a[i+3]"\t"a[i+4] }'
	echo "========获取到STATUS,退出脚本=========="
	exit 1;
}


checkCon(){
   code=`curl -k  --connect-timeout 1 -s -w "%{http_code}" -o temp ${KUBE_APISERVER}`  
   [ "000" -ne "$code" ] || { echo "返回状态码:$code,服务不可以访问" && rm -rf temp && return;}
   echo "返回状态码:$code,服务可以访问"
   checkStatus
}



jude(){
	strs=$(ansible "$1"  -m ping  | grep \| )
	count=$(echo $strs | grep -o  "=>" | wc -l)
	suc=$(echo $strs | grep -o  SUCCESS | wc -l)
	[ "$count" -eq "$suc" ] || { echo "$1节点不通,总机器$count台,成功$suc台" && exit 1;}
	echo "$1节点相通..,"
}


boot(){
	 # echo $1 /opt/ansible/yaml/k8s-node.yaml
	file=$1
	# echo $file | sed  "s/\(.*\)-\(.*\)\.\(.*\)/\2/g"
	name=$(echo $file | grep -Eo "[^\-]+(\w+)[^\.yaml]"  | tail -1)
	[ -f "$file" ] || { echo "没有找到k8s-$name文件" && exit 1; }
	echo "===== 检查$name节点========"
    jude $name
	echo "======开始启动k8s $name节点========"
	ansible-playbook   $file  --vault-password-file  $2
	echo  "执行完$name-playbook..."
}



start(){
    pwd_file=$base/a_password_file
	[ -f "$pwd_file" ] || { echo "没有找到a_password_file文件" && exit 1; }
	echo "======检查是否启动etcd========"
	pid=$(ps -ef | grep etcd | grep -v grep  | awk '{print $2}')
	[ -n "$pid" ] || { echo "开始启动....." &&  sh $etcd/etcd-master.sh ;}
	echo "本机etcd已启动..."
    #远程执行文件
    arr=(k8s-node.yaml  k8s-master.yaml)
    for i in ${arr[@]}; do
         boot $base/yaml/$i   $pwd_file
    done

}




countTime(){
    seconds_left=$1
    echo "请等待${seconds_left}秒……"
    while [ $seconds_left -gt 0 ];do
      sleep 1
      seconds_left=$(($seconds_left - 1))
      echo -n $seconds_left
      echo  "" #"\r  \r "
    done	
}



echo "=========获取k8s启动状态============="
checkCon

echo "==========准备执行================"
start

countTime 6
checkStatus