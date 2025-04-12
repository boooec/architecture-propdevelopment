Run services
```
kubectl apply -f non-admin-api-allow.yml
./run_services.sh
```

Test services
```
kubectl run test-$RANDOM --rm -i -t --image=alpine -- wget -qO- --timeout=2 http://back-end-api-app 
# wget: download timed out
```

Delete services
```
./delete_services.sh
```
