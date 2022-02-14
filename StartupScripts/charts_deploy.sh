mkdir -p ./packages
# Traefik up first for ingress control

helm package Charts/traefik-charts -d ./packages/
helm install traefik ./packages/traefik-10.9.1.tgz



helm package Charts/cron-charts/ -d ./packages/
helm package Charts/cyberchef-charts/ -d ./packages/
helm package Charts/devdocs-charts/ -d ./packages/
helm package Charts/dokuwiki-charts -d ./packages/
helm package Charts/drawio-charts/ -d ./packages/
helm package Charts/ethercalc-charts -d ./packages/
helm package Charts/etherpad-charts -d ./packages/
helm package Charts/gitea-charts -d ./packages/
helm package Charts/grafana-charts -d ./packages/
helm package Charts/homer-charts -d ./packages/
helm package Charts/misp-charts -d ./packages/
helm package Charts/prometheus-charts -d ./packages/
helm package Charts/pwndrop-charts -d ./packages/
helm package Charts/regexr-charts -d ./packages/
helm package Charts/rocketchat-charts -d ./packages/
helm package Charts/screego-charts -d ./packages/
helm package Charts/thp-charts -d ./packages/
helm package Charts/vaultwarden-charts -d ./packages/

helm install cron ./packages/cron-1.0.0.tgz
helm install cyberchef ./packages/cyberchef-1.0.0.tgz
helm install devdocs ./packages/devdocs-1.0.0.tgz
helm install dokuwiki ./packages/dokuwiki-1.0.0.tgz
helm install drawio ./packages/drawio-1.0.0.tgz
helm install ethercalc ./packages/ethercalc-1.0.0.tgz
helm install etherpad ./packages/etherpad-1.0.0.tgz
helm install gitea ./packages/etherpad-1.0.0.tgz
helm install grafana ./packages/grafana-1.0.0.tgz
helm install homer ./packages/homer-1.0.0.tgz
helm install misp ./packages/misp-1.0.0.tgz
helm install prometheus ./packages/prometheus-6.6.5.tgz
helm install pwndrop ./packages/pwndrop-1.0.0.tgz
helm install regexr ./packages/regexr-1.0.0.tgz
helm install rocketchat ./packages/rocketchat-4.3.2.tgz --set mongodb.auth.password="$(pwgen 20 1)",mongodb.auth.rootPassword="$(pwgen 20 1)"
helm install screego ./packages/screego-1.0.0.tgz
helm install thp ./packages/thehiveproject-1.0.0.tgz
helm install vaulwarden ./packages/vaultwarden-1.0.0.tgz










