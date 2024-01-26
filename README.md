
ZHdK AGW Authentication for https://medienarchiv.zhdk.ch/
=========================================================

This is project is taken and adjusted from https://github.com/zhdk/leihs-zhdk-agw-auth-system.



Links
-----

* https://intern.zhdk.ch/?agw/admin
* https://wiki.intern.zhdk.ch/itz/doku.php?id=dienstleistungen:authentication-gateway


Deploy
------

For the following scripts:

* the ZHdK madek-inventory must be reachable via `../madek/zhdk-inventory` from this directory
* a python 3.x version must be in the path as `python3`

### Prepared deploy scripts

    ./bin/deploy2staging

    ./bin/deploy2test


### Manual example

    source ./tmp/py-venv/bin/activate
    ansible-playbook -i ../../zhdk-inventory/staging-hosts deploy_play.yml -l zhdk-madek-staging

