openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out ec-ca.key
openssl req -new -key ec-ca.key -out ec-ca.csr -config openssl-ca-csr.cnf
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out ec-ca.key
openssl req -new -x509 -days 3650 -key ec-ca.key -out ec-ca.crt -config openssl-ca-x509.cnf
openssl pkcs12 -export -inkey ec-ca.key -in ec-ca.crt -out ec-ca.pfx \
  -name "My EC CA" -certpbe AES-256-CBC -keypbe AES-256-CBC
openssl pkcs12 -info -in ec-ca.pfx