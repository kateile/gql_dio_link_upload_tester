# dio_upload
 Trying reproducing *gql_dio_link* upload bug found [here](https://github.com/gql-dart/gql/pull/255#issuecomment-894391724)



- create lib/my_ip.dart and put 
```
const MY_IP = "127.0.0.1"; //replace with your ip here
```

then run
```
graphql-faker -o schema.graphql
```