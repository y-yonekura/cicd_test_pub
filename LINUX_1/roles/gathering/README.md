gathering
==========================

## Trademarks
- Linuxは、Linus Torvalds氏の米国およびその他の国における登録商標または商標です。
- RedHat、RHEL、CentOSは、Red Hat, Inc.の米国およびその他の国における登録商標または商標です。
- Windows、PowerShellは、Microsoft Corporation の米国およびその他の国における登録商標または商標です。
- Ansibleは、Red Hat, Inc.の米国およびその他の国における登録商標または商標です。
- pythonは、Python Software Foundationの登録商標または商標です。
- NECは、日本電気株式会社の登録商標または商標です。
- その他、本ロールのコード、ファイルに記載されている会社名および製品名は、各社の登録商標または商標です。

## Description
ファイルやコマンド実行結果などの情報をターゲットホストから収集し、制御ホストに格納する。  
Playbookの実行前と実行後に本ロールを実行することで、ターゲットホストの改変前と改変後の状態を取得できる。

本ロールは Windows, Linux 共通で利用できる。

Supports
--------
- 制御ホスト
  - Ansible 2.5, 2.6, 2.7
- ターゲットホスト
  - RHEL 7
  - Windows Server 2012 R2
  - Windows Server 2016
  - Windows Server 2019

Requirements
------------

Dependencies
------------

Usage
-----

### 基本的な使い方
ユーザは、通常のplaybook(site.yml)とともに、情報収集playbook(site_gathering_definition.yml)を作成し、site.ymlの先頭と末尾でsite_gathering_definition.ymlをインポートする。  
各インポートでは、VAR_gathering_labelパラメータに異なるラベルを指定する。 

`site.yml`
```
---
- import_playbook: site_gathering_definition.yml VAR_gathering_label=before

- hosts: rhel
  roles:
    - rhel_setup

- hosts: win
  roles:
    - win_setup

- import_playbook: site_gathering_definition.yml VAR_gathering_label=after
```

情報収集playbookでは、VAR_gathering_definitionパラメータで、情報種別と収集する項目を指定する。 

`site_gathering_definition.yml`
```
---
- hosts: rhel
  roles:
    - role: gathering
      VAR_gathering_definition:
        file: # ファイル収集
          - /etc/fstab
          - /etc/udev # ディレクトリ指定時は配下のファイルを収集
        command: # コマンド出力収集
          - cat /proc/partitions
          - ip addr show

- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition:
        file: # ファイル収集
          - C:\Windows\system32\drivers\etc\hosts
          - C:\Windows\INF\.NETFramework # ディレクトリ指定時は配下のファイルを収集
        command: # コマンド出力収集
          - Get-Volume
          - ipconfig /all
        registry: # レジストリ収集
          - HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
```

### ロールに収集情報を定義する
ロールの作成者は、ロールの中に、そのロールで収集すべき情報を定義できる。
ロールに収集情報を定義するには、ロールのvarsディレクトリにgathering_definition.ymlを作成し、情報種別と収集する項目を記載する。

`roles/rhel_setup/vars/gathering_definition.yml`
```
---
file: # ファイル収集
  - /etc/fstab
  - /etc/udev # ディレクトリ指定時は配下のファイルを収集
command: # コマンド出力収集
  - cat /proc/partitions
  - ip addr show
```

`roles/win_setup/vars/gathering_definition.yml`
```
---
file: # ファイル収集
  - C:\Windows\system32\drivers\etc\hosts
  - C:\Windows\INF\.NETFramework # ディレクトリ指定時は配下のファイルを収集
command: # コマンド出力収集
  - Get-Volume
  - ipconfig /all
registry: # レジストリ収集
  - HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
```

ロールに定義された情報を収集するには、VAR_gathering_definition_role_pathパラメータに、対象のロールのパスを指定する。  
指定されたロールにvars/gathering_definition.ymlが無い場合はエラーとなる。 

`site_gathering_definition.yml`
```
---
- hosts: rhel
  roles:
    - role: gathering
      VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/rhel_setup"

- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/win_setup"
```

VAR_gathering_definition_role_pathパラメータとVAR_gathering_definitionパラメータを併用することで、収集する情報を追加することができる。 

`site_gathering_definition.yml`
```
---
- hosts: rhel
  roles:
    - role: gathering
      VAR_gathering_definition_role_path: "{{ inventory_dir }}/roles/rhel_setup"
      VAR_gathering_definition:
        file:
          - /etc/selinux/config # ロール側の定義に加えて /etc/selinux/config も収集
```

### グローバル変数

#### VAR_gathering_root
制御ホスト上の収集情報保存先ディレクトリ (default: /tmp)

### 引数

#### VAR_gathering_definition
収集する情報の定義

#### VAR_gathering_definition_role_path
収集する情報を定義したロールの絶対パスまたは相対パス

#### VAR_gathering_label
情報収集タイミングを示すラベル。
連続するロールの収集結果を同じ日時のディレクトリに格納するには、
各ロールの実行時に同じラベルを指定する。
別のラベルを指定すると、日時が再設定される。 

通常は、情報収集playbookのインポート時の引数として本パラメータを指定する
(ロールの引数には指定しない)。

### 戻り値

#### gathered_data_dest
収集したデータの格納先パス。
以下の値が格納される。
`{{ VAR_gathering_root }}/_gathered_data/{{ 日時 }}_{{ ラベル }}/{{ ターゲットホスト }}`

### ファイルとディレクトリ

収集情報は制御ホストの以下のパスに格納される。 

`{{ VAR_gathering_root }}/_gathered_data/{{ 日時 }}_{{ ラベル }}/{{ ターゲットホスト }}/{{ 情報種別 }}/`

例: `/tmp/_gathered_data/20171228T100726_before/192.168.50.16/file/`

ラベル省略時(VAR_gathering_labelが未定義時)はラベルの部分が省略される。

例: `/tmp/_gathered_data/20171228T100726/192.168.50.16/file/`

Data Types
--------------

### file

#### 用途
ファイルを取得する

#### プラットフォーム
Windows, Linux

#### 入力
ファイルまたはディレクトリのリスト。 ディレクトリの場合は配下のファイルを再帰的に取得する。  
リストの要素は、ファイル名の文字列、または以下のdict形式とする。
- name: ファイル名 (必須)
- depth: ディレクトリの再帰の深さ
  - 1以上の整数を指定する。1を指定するとディレクトリ直下のファイルのみを取得する。
  - Windowsでは PowerShell 5.0 (Windows Server 2016 に標準搭載) 以降で本パラメータが有効になる。PowerShellのバージョンがこれに満たない場合、本パラメータは無視される。
- quote: ファイル名をシェルで文字列化する際に利用するquote文字
  - ファイル名に環境変数を含める際、```"``` (double quote) を指定することで変数を展開することができる
  - 既定値は ```'``` (single quote)
- symlink: シンボリックリンクを辿る
  - trueを指定するとシンボリックリンク先のファイルも取得する。
  - Linuxのみ有効

#### 出力
取得したファイル

#### 例
Playbook
```
---
- hosts: rhel
  roles:
    - role: gathering
      VAR_gathering_definition:
        file:
          - /etc/fstab
          - /etc/udev
          - name: /etc/systemd
            depth: 1
          - name: $HOME/.bashrc
            quote: '"'
          - name: /etc/pam.d
            symlink: yes

- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition:
        file:
          - C:\Windows\system32\drivers\etc\hosts
          - name: $env:windir\system.ini
            quote: '"'
```
格納ファイル
```
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/fstab
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/udev/udev.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/udev/hwdb.bin
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/bootchart.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/coredump.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/journald.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/logind.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/system.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/systemd/user.conf
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/config-util
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/other
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/chfn
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/chsh
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/login
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/remote
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/runuser
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/runuser-l
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/su
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/su-l
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/systemd-user
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/polkit-1
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/crond
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/vlock
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/vmtoolsd
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/sshd
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/smtp.postfix
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/smtp
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/sudo
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/sudo-i
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/passwd
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/system-auth-ac
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/system-auth
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/postlogin-ac
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/postlogin
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/password-auth-ac
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/password-auth
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/fingerprint-auth-ac
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/fingerprint-auth
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/smartcard-auth-ac
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/smartcard-auth
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/etc/pam.d/samba
/tmp/_gathered_data/20190215T105025/172.16.0.6/file/root/.bashrc
/tmp/_gathered_data/20190215T105025/192.168.50.1/file/C:/Windows/system32/drivers/etc/hosts
/tmp/_gathered_data/20190215T105025/192.168.50.1/file/C:/Windows/system.ini
```

### command

#### 用途
コマンドの実行結果を取得する

#### プラットフォーム
Windows, Linux

#### 入力
コマンドのリスト

#### 出力
- 各コマンドの情報を格納するJSONファイル(results.json)
- 各コマンドの情報をテキストファイルとして格納するディレクトリ (数字、0オリジン)
  - コマンドライン (item.txt)
  - 終了コード (rc.txt)
  - 標準出力 (stdout.txt)
  - 標準エラー出力 (stderr.txt)

#### 例
Playbook
```
---
- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition:
        command:
          - Get-Volume
          - ipconfig /all
```
格納ファイル
```
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/results.json
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/0/item.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/0/rc.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/0/stdout.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/0/stderr.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/1/item.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/1/rc.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/1/stdout.txt
/tmp/_gathered_data/20171228T143714/192.168.50.37/command/1/stderr.txt
```

### registry

#### 用途
レジストリをエクスポートしたファイルを取得する

#### プラットフォーム
Windows

#### 入力
レジストリキーのリスト。以下の形式で指定可
- powershellのパス形式  
  `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\`
- reg export コマンドが受け付ける形式 (`:`および末尾の`\`なし)  
  `HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU`

#### 出力
エクスポートされた.regファイル (export.reg)

#### 例
Playbook
```
---
- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition:
        registry:
          - HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System
          - HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU\
```
格納ファイル
```
/tmp/_gathered_data/20180110T163102/192.168.50.37/registry/HKLM/SOFTWARE/Microsoft/Windows/CurrentVersion/Policies/System/export.reg
/tmp/_gathered_data/20180110T163102/192.168.50.37/registry/HKLM/SOFTWARE/Policies/Microsoft/Windows/WindowsUpdate/AU/export.reg
```

Examples
--------
[examplesディレクトリ](examples)を参照。

Playbook実行方法:
```
# cd examples/
# ansible-playbook site.yml -i hosts
```

Remarks
-------

### Windowsコマンド出力の文字化け対策
Windowsターゲットにおいて、commandで取得したコマンド出力(stdout.txt, stderr.txt)が文字化けする場合は、次の要領で回避することができる。
- `chcp`でコマンド出力の文字コードを指定する
- コマンド出力を一時ファイルにリダイレクトする
- fileで一時ファイルを回収する

以下の例では、`chcp`でコードページ932を指定し、コマンドの標準出力を一時ファイルにリダイレクトしている。一時ファイルはfileで回収した後で削除している。
```
- hosts: win
  roles:
    - role: gathering
      VAR_gathering_definition:
        command:
          - chcp 932; ipconfig /all > {{ ansible_facts.env.TEMP }}\ipconfig.out
          - chcp 932; auditpol /get /category:"オブジェクト アクセス" > {{ ansible_facts.env.TEMP }}\auditpol.out
    - role: gathering
      VAR_gathering_definition:
        file:
          - '{{ ansible_facts.env.TEMP }}\ipconfig.out'
          - '{{ ansible_facts.env.TEMP }}\auditpol.out'
  post_tasks:
    - win_file:
        path: '{{ item }}'
        state: absent
      loop:
        - '{{ ansible_facts.env.TEMP }}\ipconfig.out'
        - '{{ ansible_facts.env.TEMP }}\auditpol.out'
```

### virtualenv利用時のエラー回避策
本ロールをvirtualenvで実行すると、以下のエラーメッセージで停止する場合がある。
```
Aborting, target uses selinux but python bindings (libselinux-python) aren't installed!
```
エラーを回避するには次のような対策がある。
* selinuxをdisabledにする (permissiveではNG)
* システムの site-packages/selinux を virutalenv 配下にコピーする。  
  ```cp -a /usr/lib64/python2.7/site-packages/selinux $VIRTUAL_ENV/lib/python2.7/site-packages```
* virtualenv作成時に```--system-site-packages```を指定する

詳細は下記の議論を参照のこと。
- https://github.com/trailofbits/algo/issues/356
- https://github.com/ceph/ceph-ansible/issues/1775
- https://dmsimard.com/2016/01/08/selinux-python-virtualenv-chroot-and-ansible-dont-play-nice/
