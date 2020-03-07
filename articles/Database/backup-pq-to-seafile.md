title: 备份 Postgresql 到 Seafile
date: 2020-02-28 18:54:02
---

前段时间用 Python 写了一段小脚本，就是把 Postgresql 的备份数据备份到 Seafile 中，这种方法只适合小数据的数据库，聊做记录一番：

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


[https://github.com/fwchen/oyster/tree/seafile-backup/backup](https://github.com/fwchen/oyster/tree/seafile-backup/backup)