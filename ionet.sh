#!/bin/bash

# Docker images'ta 'ionet' içeren imaj sayısını kontrol et
# check docker image count
image_count=$(docker image ls | grep -c ionet)

# Docker container'larında 'ionet' çalışan sayısını kontrol et
# check docker container count
container_count=$(docker ps | grep -c ionet)

# Koşullar kontrol ediliyor, eğer calismiyor ise tekrar kurulum yapılacak.
# check for conditions, if not re-run docker containers for IONET
if [ $image_count -eq 3 ] && [ $container_count -eq 2 ]; then
  echo "IONET Worker is OK"
else
  ## buraya kurulum aşamasında kullandığınız kod satırını ekliyoruz, olması gereken ornek satir
  ## /launch_binary_mac --device_id=XXXX --user_id=XXXX --operating_system="macOS" --usegpus=false --device_name=m1

fi
