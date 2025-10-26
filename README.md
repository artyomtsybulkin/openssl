# openssl
SSL Certificates and related scripts

Generating CA certificate for signing server certificates:

```bash
mv example_config.sh config.sh
mv example_hosts.txt hosts.txt
```

Correct `hosts.txt` and `config.sh` to match target environment and then run scripts

```bash
chmod +x make_ca.sh make_servers.sh
./make_ca.sh
./make_servers.sh
```

Result directory structure:

```bash
ca/
 ├── ca.key       # Private key
 ├── ca.crt       # Root certificate
 ├── ca.csr       # CSR for reference
 ├── ca.pfx       # PFX with friendly name
 ├── index.txt
 └── serial
servers/
 ├── app1.contoso.com.key
 ├── app1.contoso.com.csr
 ├── app1.contoso.com.crt
 ├── app1.contoso.com.pfx
 ├── openssl_app1.contoso.com.cnf
 ├── ...
```