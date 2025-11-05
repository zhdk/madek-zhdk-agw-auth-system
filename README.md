
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



## Notes 

### Hosts not allowed Problem

* https://github.com/sinatra/sinatra/pull/2053
* https://github.com/sinatra/sinatra/pull/2053/files/8466a9ea462c1a5bc46b151e02fb108f048bc8dd#diff-026d81b9fb9515bb82e62b71e99f40d18c9a1dca495473e0c132d00e7e1b1265
* https://github.com/sinatra/sinatra/issues/2065#issuecomment-2484285707
