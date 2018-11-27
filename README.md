

Links
-----

* https://intern.zhdk.ch/?agw/admin
* https://wiki.intern.zhdk.ch/itz/doku.php?id=dienstleistungen:authentication-gateway


Deploy
------

### Staging aka. staging.leihs.zhdk.ch

    cd deploy
    ansible-playbook -i ../../zhdk-inventory/staging-hosts deploy_play.yml -l zhdk-leihs-staging


    cd deploy
    ansible-playbook -i ../../zhdk-inventory/developer-hosts -l tom deploy_play.yml



