
## Diagram of the architecture of 4 FRR routers in 2 DCs:


```
              DC-1                     |                    DC-2
            ---------- 213.131.230.19  |  213.131.230.183 -------------
AS:64999    | dc1-gw |-----------------|------------------|   dc2-gw  | AS:65000
            ----------                 |                  -------------
                  |                    |                        |
                  |                    |                        |
                  | 213.131.230.104    |                        |  213.131.230.39
            -------------              |                  -------------
AS:64999    | cloud1-gw |              |                  | cloud2-gw | AS:65000
            -------------              |                  -------------
```


In the directory there are 4 deployment and config files for every of the FRR router VM.

## Prequisites
- Created VM on plusserver
- Security group of VM to allow connections on port 179


