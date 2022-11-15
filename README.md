# Servizio Terminologico Integrato (plugin per CTS2 Framework) 
### Nome del modulo:  sti-service

## Modulo maven contenente il codice di integrazione con il framework cts2



### Descrizione

Il progetto rappresenta un plugin (OSGI) installabile nel framework CTS2 attraverso la sua console web. Il modulo implementa degli 'hook' per il framework CTS2.



### Descrizione Repository
Questo repository contiene il modulo parent sti-cts2-portlets-build e i seguenti moduli figli
- sti-service[plugin (bundle osgi) per la gestione/importazione delle codifiche]

  


## Prerequisiti
Prima di procedere al download dei sorgenti per il corretto funzionamento occorre installare le seguenti.
Per l'installazione degli applicativi si demanda alla documentazione ufficiale

- [SO AlmaLinuxOS](https://almalinux.org/it/)

- [JDK 1.8](https://www.oracle.com/it/java/technologies/javase/javase8-archive-downloads.html)

- [Maven 3.6.3](https://maven.apache.org/docs/3.6.3/release-notes.html)

- [Postgres 9.6](https://www.postgresql.org/ftp/source/)

- [solr-6.3.0](https://archive.apache.org/dist/lucene/solr/)

- [sti-cts2-framework](https://github.com/iit-rende/sti-cts2-framework)

  

## Installazione 
Per procedere alla corretta installazione dei moduli del presente repository è necessario scaricare e configurare prima i repository [STI-CTS2-FRAMEWORK](https://github.com/aleciop/sti) e [STI-SERVICE](https://github.com/aleciop/sti-service) ed è importante che i moduli stiano nella stessa directory in quanto il presente modulo dipende dal framework.

Di seguito la dipendenza nel [Pom](./pom.xml) del modulo [STI-SERVICE](https://github.com/aleciop/sti-service)

https://github.com/AlecioP/sti-service/blob/33ab5aa179a1b23c64912547074a86cf2542c570/pom.xml#L6-L11



Per l'installazione degli applicativi [AlmaLinuxOS, JDK 1.8, Postgres 9.6, liferay-portal-6.2-ce-ga6,solr-6.3.0] si rimanda alla documentazione ufficiale.
Per quanto riguarda `CTS2 Framework` l'installazione è descritta nei repository di riferimento.

## Configurazione Ambiente

Per il corretto funzionamento del modulo è necessario creare i DB e avviare solr. Nel progetto è presente una cartella  [Sti-service/extra](./extra) dove sono presenti alcune risorse che vedremo più avanti.

Per quanto riguarda il DB è necessario creare 2 schema, sti_service e sti_import.

#### DB

Schema DB

<p align="center">
  <img width="400" height="400" src="./screenshot/DB.png">
</p>




Al seguente [indirizzo](http://cosenza.iit.cnr.it/repo/sti/dati_base/dump_dati_base.zip), è possibile scaricare gli script per la generazione dei 2 schema e il popolamento dei dati relativi ai sistemi di codifica di base gestiti dal sistema, ovvero quelli indicati dal `DPCM n.178/2015 sul Fascicolo Sanitario Elettronico`  (**LOINC; ATC; AIC; ICD9-CM**). 

Con i seguenti comandi importiamo gli script nel DB postgres.

```shell
psql sti_service < sti_service.sql
psql sti_import < sti_import.sql
```

#### Solr

Dopo aver scaricato Solr bisogna aggiungere gli indici per gestire le codifiche. Nella cartella [Solr_conf](./extra/solr/solr_conf) sono presenti definizioni degl'indici, quindi per ogni codifica sono definiti i file `schema.xml` e  `solrconfig.xml`. 

Le definizioni degli indici vanno copiate dentro solr (in servizio non deve esser attivo) sotto la cartella `$SOLR_INSTALL_DIR/server/solr`, successivamente vanno settate le prop e poi va avviato il servizio.

![](screenshot/path_definizione_indici.png)

Successivamente bisogna editare il file `$SOLR_INSTALL_DIR/bin/solr.in.sh` definendo le proprietà "sti.index.location.**NOME_INDICE**" utilizzate nei file `./solrconfig.xml` dei rispettivi indici per indicare la cartella di destinazione dei dati. Di seguito un esempio di configurazione


```shell
SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.loinc=/PATH/INDICI_SOLR/SOLR_IDX/LOINC_IDX"

SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.icd9cm=/PATH/INDICI_SOLR/SOLR_IDX/ICD9CM_IDX"

SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.atc=/PATH/INDICI_SOLR/SOLR_IDX/ATC_IDX"

SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.aic=/PATH/INDICI_SOLR/SOLR_IDX/AIC_IDX"

SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.standard_local=/PATH/INDICI_SOLR/SOLR_IDX/STANDARD_LOCAL_IDX"

SOLR_OPTS="$SOLR_OPTS -Dsti.index.location.valueset=/PATH/INDICI_SOLR/SOLR_IDX/VALUESET_IDX"

SOLR_OPTS="$SOLR_OPTS -Ddisable.configEdit=true"
```


Di seguito un esempio di come vengono usate le prop precedentemente definite. 

https://github.com/AlecioP/sti-service/blob/ed83fea8e52bec4aed326ac24124adcc88262645/extra/solr/solr_conf/sti_valueset_conf/solrconfig.xml#L1-L26

All'[indirizzo](http://cosenza.iit.cnr.it/repo/sti/dati_base/INDEX_SOLR_DATI_BASE.zip) è presente un dump degli indici contenente i dati delle codifiche di base (**LOINC; ATC; AIC; ICD9-CM**) relativo al dump del [DB](http://cosenza.iit.cnr.it/repo/sti/dati_base/dump_dati_base.zip). Quindi i caso di caricamento del DB con i dati di base bisogna prendere anche gli indici SOLR contenenti i dati in modo che all'avvio dell'applicazione sia tutto correttamente funzionante.

Il download del DB e degli indici SOLR aggiornati con tutte le codifiche **sarà disponibile** ai seguenti URL

 - [Solr core data](http://cosenza.iit.cnr.it/repo/sti/dati_produzione/INDEX_SOLR_DATI_PRODUZIONE.zip)

 - [Db dump](http://cosenza.iit.cnr.it/repo/sti/dati_produzione/dump_dati_produzione.zip)

A questo punto si può avviare Solr:

```shell
/PATH_SOLR/solr-6.3.0/bin/solr stop
/PATH_SOLR/solr-6.3.0/bin/solr start
```

Se tutto è andato bene dovremo accedere alla console di solr all'indirizzo (http://HOST:8983/solr/) e verificare che gli indici siano presenti.

![solr](screenshot/solr.png)

## Build
Per la build del modulo è necessario scaricare e installare - [Maven 3.6.3](https://maven.apache.org/docs/3.6.3/release-notes.html) o superiore

A questo punto si considera un ambiente configurato e con il framework cts2 correttamente importato come dipendenza e distribuito sotto Liferay come descritto nel repository  [Iit-rende/sti-cts2-framework](https://github.com/iit-rende/sti-cts2-framework)
Per la build  comandi da dare sono i seguenti

```sh
git clone https://github.com/iit-rende/sti-service.git
cd sti-service
mvn clean install
```

## Deploy

Una volta eseguita la build dei moduli verrà prodotto un jar da caricare nella console web di cts2.

Se l'ambiente è correttamente configurato ed è stato effettuato il deployment del framework cts2 sotto Liferay, si potrà accedere alla console tramite il seguente url: http://HOST/cts2framework/  cliccando su Admin Console, successivamente si dovrà caricare il file per il quale è stata precedentemente eseguita la build per poi confermare il caricamento.

N.B. in caso di conferma spuntare "Start Bundle"

### Accesso alla console

<p align="center">
  <img width="400" height="400" src="./screenshot/home.png">
</p>

### Caricamento plugin

<p align="center">
  <img width="700" height="250" src="./screenshot/caricamento.png">
</p>

### Conferma

<p align="center">
  <img width="600" height="300" src="./screenshot/conferma.png">
</p>


Per ulteriori approfondimenti si rimanda alla documentazione di cts2 framework

## Copyright ©

Istituto di Informatica e Telematica - Consiglio Nazionale delle Ricerche (IIT-CNR)

## Maintainer


IIT-CNR

**Contatti**

Elena Cardillo - email: [elena.cardillo@iit.cnr.it](mailto:elena.cardillo@iit.cnr.it)

Antonio Stumpo -email: [antonio.stumpo@cnr.it](mailto:antonio.stumpo@cnr.it)

Maria Taverniti - email: [maria.taverniti@cnr.it](mailto:maria.taverniti@cnr.it)


## License 
STI è concesso in licenza GPL-3.0 o seguenti https://www.gnu.org/licenses/gpl-3.0.html
