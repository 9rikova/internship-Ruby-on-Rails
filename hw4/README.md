Запуск:  
docker-compose up

Примеры запросов:  
(без дополнительных дисков)  
127.0.0.1:8080/price?cpu=4&ram=16&hdd_type=ssd&hdd_capacity=1000  

(с дополнительными дисками)
127.0.0.1:8080/price?cpu=4&ram=16&hdd_type=ssd&hdd_capacity=1000&extra[]=ssd&extra[]=256&extra[]=sata&extra[]=500
