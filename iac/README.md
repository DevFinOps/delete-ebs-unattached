# Modulo Deploy Lambda-S3

### Estrutura do modulo
Este código foi criado para realizar o deploy de uma **Lambda**, um **Bucket S3** e a criação da **IAM Role** através do Terraform.
Dentro do diretório ***modules*** contém as variáveis utilizadas como padrão, faça uma análise e ajuste conforme a necessidade do padrão do seu ambiente aws, não se esquecendo que há um conjunto bem básico de **Tags**, afinal FinOps não faz nada sem elas.
É importante também ressaltar que o código que irá ser transformado em Lambda precisa ser transformado em arquivo **zip** antes da execução, neste módulo utilizamos python, porém se necessário ajuste também a referência e o runtime da lambda.

### Contato
O time de voluntários da frente **DevFinOps** poderá lhe auxiliar em relação ao modulo, precisando procure alguém do time.