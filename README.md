

Links
-----

* https://intern.zhdk.ch/?agw/admin
* https://wiki.intern.zhdk.ch/itz/doku.php?id=dienstleistungen:authentication-gateway


Deploy
------

### Python Environment

#### Using the Deployment-Environment

Before calling `ansible` etc:

```
source py-venv/bin/activate
```


#### Installing a Deployment-Environment

We recommend to install a compatible `ansible` version as follows:

```
python3 -m venv py-venv
source py-venv/bin/activate
pip install -r deploy/requirements.txt
```

This requires Python 3.7 or later.

#### Upgrading `ansible` from scratch

```
python3 -m venv py-venv
source py-venv/bin/activate
pip install ansible
pip freeze > requirements.txt
```



### Staging aka.staging.leihs.zhdk.ch

    cd deploy
    ansible-playbook -i ../../zhdk-inventory/staging-hosts deploy_play.yml -l zhdk-leihs-staging


    cd deploy
    ansible-playbook -i ../../zhdk-inventory/developer-hosts -l tom deploy_play.yml




