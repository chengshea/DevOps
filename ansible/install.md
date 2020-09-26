# 安装

### 准备

下载地址

https://github.com/ansible/ansible/releases

设置源

cs@debian:~$ cat  ~/.pip/pip.conf 
[global]
trusted-host=mirrors.aliyun.com
index-url=http://mirrors.aliyun.com/pypi/simple/

### 开始

cd   ansible-2.10.0

#### 安装依赖

pip install --user -r ./requirements.txt

#### 正式安装

python setup.py install



ansible --version

> pkg_resources.DistributionNotFound: The 'jinja2'
>
> pip list 查看，执行用户没有安装该模板



# 使用





- [Control node](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#control-node)
- [Managed nodes](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#managed-nodes)
- [Inventory](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#inventory)
- [Modules](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#modules)
- [Tasks](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#tasks)
- [Playbooks](https://docs.ansible.com/ansible/latest/user_guide/basic_concepts.html#playbooks)



#### 示例

**使用root用户执行命令**

- -m  模块
- -a  命令

- –become 或 -b
- –become-method    [ sudo | su | pbrun | pfexec | doas | dzdo | ksu | runas | machinectl ]
- –become-user
- –ask-become-pass 或 -K
- 

```shell
ansible  node  -m shell -a "cat /etc/docker/key.json"    -b --become-method su --become-user root  -K
```

> BECOME password: 输入密码



##### 加密文件

对密码等保密信息进行加密



###### [创建加密文件 ](#create_yaml)

设置文件密码,调用vi 编辑器,写入保密信息

```shell
ansible-vault create  node-pass.yaml
```

>cs@debian:/opt/ansible$ cat node-pass.yaml 
>$ANSIBLE_VAULT;1.1;AES256
>39336263626462323665333364313465343437613332656562383532366436363036373662336630
>6666313066386532663833623237633833356235633765660a666631396236636136656239613062
>62363333373961363239333735343061656638366537323332353335353861623137666232393037
>3164633166613864360a383833386538343337326335636135323435313532346665336562356464
>31363663633930653434633564656231663566303538393066346236363731386132

###### 解密 已加密文件

```shell
ansible-vault decrypt  node-pass.yaml
```

>cs@debian:/opt/ansible$ cat node-pass.yaml 
\---
password: 123456

###### 加密 解密后的文件

```shell
ansible-vault encrypt  node-pass.yaml
```

>cs@debian:/opt/ansible$ ansible-vault encrypt  node-pass.yaml 
>New Vault password: 
>Confirm New Vault password: 
>Encryption successful
>cs@debian:/opt/ansible$ cat node-pass.yaml 
>$ANSIBLE_VAULT;1.1;AES256
>64383861626430373864316636386430306463656436623238386238303537313964396238343133
>3763333630643336333930333934653466393863366365390a386637343761376430613465333233
>33643364633930346466646233356637333862653730663063636332653436353635643535376164
>3061396164616266380a656239313837353632386562613531633539313461343764376139373838
>38616631616565316264366436326665646665663866306161396132303236313234



###### 编辑加密文件

```shell
ansible-vault edit  node-pass.yaml 
```

> cs@debian:/opt/ansible$ ansible-vault edit  node-pass.yaml 
> Vault password: 



###### 查看加密文件

仅查看的内容而不进行编辑

```shell
ansible-vault view  node-pass.yaml 
```

> cs@debian:/opt/ansible$ ansible-vault view  node-pass.yaml 
> Vault password: 
> \---
> password: 123456



###### [加密字符串](#create_string)

```shell
ansible-vault encrypt_string --vault-id dev@a_password_file  '123456' --name 'become_pass'
```

> cs@debian:/opt/ansible$ ansible-vault encrypt_string --vault-id dev@a_password_file  '123456' --name 'become_pass'
> become_pass: !vault |
>           $ANSIBLE_VAULT;1.2;AES256;dev
>           36636239393163616238326666343263613830363731333662373136313462613138356136616166
>           3264613139643933333663303938613539653963633038370a383961343836633937316362633437
>           33393836383734633838656130366666353838306234303762623966323764613465373865633865
>           6630323763396663300a303135353765613539306465363837653566613139353265373833613830
>           6135
> Encryption successful

- dev 代表标签

- a_password_file  一个文件,里面是`--vault-id @prompt ` 的值
- '123456'  字符串的明文,即密码,不推荐这样操作
- --name  指定变量名

推荐

```shell
 ansible-vault encrypt_string --vault-id dev@a_password_file --stdin-name 'become_pass'
```

> Reading plaintext input from stdin. (ctrl-d to end input)
> 123456 



\### <span id="jump1">1. 目录1</span>

##### 删除文件

###### 引用加密文件

```shell
 ansible-playbook  /opt/ansible/yaml/local-b.yaml       --vault-id @prompt
```

> cs@debian:~$ ansible-playbook  /opt/ansible/yaml/local-b.yaml       --vault-id @prompt 
> Vault password (default): 输入保护文件的密码,解密文件内容

<span id="create_yaml">node-pass.yaml</span>见创建加密文件

```yaml
# /opt/ansible/yaml/local-b.yaml
---
- hosts: node
  vars_files:
    - /opt/ansible/node-pass.yaml
  tasks:
  - name: Run a command
    become: yes
    become_method: su
    vars:
       ansible_become_pass: "{{ password }}"
    file:   
      state: absent 
      path: /opt/kubernetes/amd64/kube-apiserver
```

>vars_files 引入文件
>
>file 操作文件的模块

file模块主要用于远程主机上的文件操作

- force：需要在两种情况下强制创建软链接，一种是源文件不存在但之后会建立的情况下；另一种是目标软链接已存在,需要先取消之前的软链，然后创建新的软链，有两个选项：yes|no 
- group：定义文件/目录的属组 
- mode：定义文件/目录的权限
- owner：定义文件/目录的属主
- path：必选项，定义文件/目录的路径
- recurse：递归的设置文件的属性，只对目录有效
- src：要被链接的源文件的路径，只应用于state=link的情况
- dest：被链接到的路径，只应用于state=link的情况 
- state： directory：如果目录不存在，创建目录
  file：即使文件不存在，也不会被创建
  link：创建软链接
  hard：创建硬链接
  touch：如果文件不存在，则会创建一个新的文件，如果文件或目录已存在，则更新其最后修改时间
  absent：删除目录、文件或者取消链接文件



###### 引用文件内加密变量

```shell
ansible-playbook /opt/ansible/yaml/local-b.yaml  --vault-password-file /opt/ansible/a_password_file 
```

<span id="create_string">custom.yaml</span>  见创建加密变量

```yaml
# 加密变量
---
custom_vars:
    become_pass: !vault |
          $ANSIBLE_VAULT;1.2;AES256;dev
          66383637343038636234353234353062633966663738616666653931353730333839653362373935
          6632343665313561333435323366376661343065636133340a373866373835303731383034653663
          31633938616330343535393339626163656630323233316566393264306462666434303434383263
          6333386535323666330a623965623436373464653734383736663464356664343439343837613039
          3635
```

local-b.yaml 

```yaml
---
- hosts: node
  vars_files:
    - /opt/ansible/custom.yaml
  tasks:
  - name: Run a command
    become: yes
    #become_user: root
    become_method: su
    vars:
       ansible_become_pass: "{{ custom_vars.become_pass }}"
    file:   
      state: absent 
      path: /opt/kubernetes/amd64/kube-apiserver
```

