# macos-worker-checker

script icerigini dizine kopyaladıktan sonra 18. Satır'a kendi komutunuzu eklemeniz gerekiyor.

kaydettikten sonra chmod +x ionet.sh

5 dakika'da bir çalıştırmak için crontab'a job ekliyoruz. crontab -e */5 * * * * /dosyaninbulundugudizin/ionet.sh
