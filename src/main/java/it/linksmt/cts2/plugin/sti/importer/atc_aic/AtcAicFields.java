package it.linksmt.cts2.plugin.sti.importer.atc_aic;

public interface AtcAicFields {

	String ATC_CODE_SYSTEM_NAME = "ATC";
	String AIC_CODE_SYSTEM_NAME = "AIC";

	// Campi ATC
	String ATC_CODICE = "CODICE_ATC";
	String ATC_SUBCLASS_OF	= "SUBCLASS_OF";

	String ATC_DENOMINAZIONE = "DENOMINAZIONE";
	String ATC_GRUPPO_ANATOMICO = "GRUPPO_ANATOMICO";

	// Campi AIC
	String AIC_CODICE = "CODICE_AIC";
	String AIC_DENOMINAZIONE = "DENOMINAZIONE";

	String VERSIONI_MAPPING = "VERSIONI_MAPPING";
	String VERSIONE_ATC = "VERSIONE_ATC";

	String AIC_DITTA = "DITTA";
	String AIC_CONFEZIONE = "CONFEZIONE";
	String AIC_TIPO_FARMACO = "TIPO_FARMACO";
	String AIC_PRINCIPIO_ATTIVO = "PRINCIPIO_ATTIVO";

	String AIC_CLASSE = "CLASSE";
	String AIC_CODICE_GRUPPO_EQ = "CODICE_GRUPPO_EQ";
	String AIC_DESCR_GRUPPO_EQ = "DESCR_GRUPPO_EQ";

	String AIC_PREZZO_EX_FACTORY = "PREZZO_EX_FACTORY";
	String AIC_PREZZO_AL_PUBBLICO = "PREZZO_AL_PUBBLICO";
	String AIC_PREZZO_MASSIMO_CESSIONE = "PREZZO_MASSIMO_CESSIONE";

	String AIC_IN_LISTA_TRASPARENZA_AIFA = "IN_LISTA_TRASPARENZA_AIFA";
	String AIC_IN_LISTA_REGIONE = "IN_LISTA_REGIONE";

	String AIC_METRI_CUBI_OSSIGENO = "METRI_CUBI_OSSIGENO";
	String AIC_UNITA_POSOLOGICA = "UNITA_POSOLOGICA";
	String AIC_PREZZO_UNITA_POSOLOGICA = "PREZZO_UNITA_POSOLOGICA";

	String AIC_NOTA = "NOTA";
}
