

Links
-----

* https://intern.zhdk.ch/?agw/admin
* https://wiki.intern.zhdk.ch/itz/doku.php?id=dienstleistungen:authentication-gateway


Deploy
------

For the following scripts:

* the ZHdK leihs-inventory must be reachable via `../leihs/zhdk-inventory` from this directory
* a python 3.x version must be in the path as `python3`

### Prepared deploy scripts

    ./bin/deploy2staging

    ./bin/deploy2test


### Manual example

    source ./tmp/py-venv/bin/activate
    ansible-playbook -i ../../zhdk-inventory/staging-hosts deploy_play.yml -l zhdk-leihs-staging

