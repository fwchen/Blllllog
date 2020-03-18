title: 备份 Postgresql 到 Seafile
date: 2020-02-28 18:54:02
---

前段时间用 Python 写了一段小脚本，就是把 Postgresql 的备份数据备份到 Seafile 中，这种方法只适合小数据的数据库，聊做记录一番：

> 当然了，备份到 seafile 并不是一个好方法，其实更好的方法是备份到 s3 之类的对象存储里，可以参考我的另一篇文章
> [https://www.chencanhao.com/Database/s3%E5%A4%87%E4%BB%BDpg](https://www.chencanhao.com/Database/s3%E5%A4%87%E4%BB%BDpg)

流程如下：

首先我们通过 `pg_dump` 这个工具把 pg 里面的某一个数据库给 dump 下来，当然还有按日期命名，dump 完删除之类的操作。

``` python
def backup_postgres():
    today = "{:%Y-%m-%d}".format(datetime.now())
    print('%s start backup' % today)
    filename = '%s.gz' % today

    with gzip.open(filename, 'wb') as f:
        popen = subprocess.Popen(["pg_dump", "-h", (os.environ['BACKUP_HOST']), "-U", (os.environ['PGUSER']), (os.environ['PGDBNAME'])], stdout=subprocess.PIPE, universal_newlines=True)

        for stdout_line in iter(popen.stdout.readline, ""):
            f.write(stdout_line.encode("utf-8"))

        popen.stdout.close()
        popen.wait()

    save_file_to_seafile(filename)
    remove_file(filename)

```

然后，我们需要讲 dump 下来的数据上传到我们的网盘 seafile 上。

相关的 api 可以查阅 seafile 的官方 web 2.1 文档

[https://seafile.gitbook.io/seafile-server-manual/developing/web-api-v2.1#upload-file]

首先需要获取 api 的认证 token，token 可以事先用账号和密码生成好，就不用在程序里写了，毕竟放个用户名和密码也不是很好。

然后通过 Get Upload Link 这个 api 获取 seafile 的上传地址，然后通过开子进程用 curl 进行上传，用 curl 相对来说比写 python 代码要简单和方便一些。然后就可以了。

完整的程序在下面，整个程序还处理了一些环境变量的问题，敏感信息都放在环境变量里了，还有定时任务等等。


``` python
import http.client
import requests
import gzip
import os
import schedule
import time
from datetime import datetime
import subprocess

def save_file_to_seafile(filename):
    print('start upload backup file to seafile')
    print(filename)
    print()
    get_upload_api_request = requests.get(os.environ['SEAFILE_API'], headers={
        'Authorization': 'Token ' + os.environ['SEAFILE_TOKEN']
    })
    upload_link = get_upload_api_request.text.replace('"', '')

    print('upload link is ' + upload_link)

    result = subprocess.run([
      'curl', '-H', 'Authorization: Token %s' % os.environ['SEAFILE_TOKEN'], '-F', ('file=@%s' % filename), '-F', 'parent_dir=/db', '-F', 'replace=0',
      upload_link
    ], stdout=subprocess.PIPE)

    print(result.stdout.decode('utf-8'))

    print('backup to seafile done')


def remove_file(filename):
    os.remove(filename)
    print('file removed')

def backup_postgres():
    today = "{:%Y-%m-%d}".format(datetime.now())
    print('%s start backup' % today)
    filename = '%s.gz' % today

    with gzip.open(filename, 'wb') as f:
        popen = subprocess.Popen(["pg_dump", "-h", (os.environ['BACKUP_HOST']), "-U", (os.environ['PGUSER']), (os.environ['PGDBNAME'])], stdout=subprocess.PIPE, universal_newlines=True)

        for stdout_line in iter(popen.stdout.readline, ""):
            f.write(stdout_line.encode("utf-8"))

        popen.stdout.close()
        popen.wait()

    save_file_to_seafile(filename)
    remove_file(filename)

def start_backup():
    run_now = False
    if os.environ.get('RUN_NOW') == 'true':
        run_now = True

    if run_now != True:
        print('start scheme backup')
        schedule.every().day.at(os.environ['BACKUP_TIME']).do(backup_postgres)
        while 1:
            schedule.run_pending()
            time.sleep(1)
    else:
        print('start backup once')
        backup_postgres()

def main():
    print('start backup service')
    start_backup()

if __name__ == '__main__':
    main()
```

最后，附上一个 dockerfile，毕竟这年头跑这些个小脚本，还是起一个 docker 方便简洁多了。

``` Dockerfile
FROM python:3.8.0a4-stretch

COPY pgdg.list /etc/apt/sources.list.d/pgdg.list

RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt update
RUN apt install -y postgresql-client-11

WORKDIR /usr/src/app

COPY requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD [ "python", "./main.py" ]
```

github 源码在[https://github.com/fwchen/oyster/tree/seafile-backup/backup](https://github.com/fwchen/oyster/tree/seafile-backup/backup)