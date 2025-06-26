-- REALIZA O CARREGAMENTO DAS INFORMAÇÕES DO BACKUP NA TABELA ORIGINAL
MERGE INTO NFMSG Destino
USING (
    SELECT
        SEQNOTA,
        MSGTB
        -- Adicione outras colunas da NFMSG_BACKUP que você possa precisar se for atualizar mais campos
    FROM (
        SELECT
            b.SEQNOTA,
            b.MSGTB,
            -- Adicione outras colunas
            ROW_NUMBER() OVER (PARTITION BY b.SEQNOTA ORDER BY b.ROWID DESC) as rn -- ou outra coluna para critério de desempate
        FROM NFMSG_BACKUP b
    )
    WHERE rn = 1 -- Pega apenas a primeira linha para cada SEQNOTA após a ordenação
) Fonte
ON (Destino.SEQNOTA = Fonte.SEQNOTA)
WHEN MATCHED THEN
  UPDATE SET Destino.MSGTB = Fonte.MSGTB;
  
SELECT MSGTB,NFMSG.* FROM NFMSG WHERE MSGTB IS NOT NULL;

CREATE TABLE NFMSG_BACKUP AS SELECT * FROM NFMSG; -- CRIA BACKUP DA TABELA DO FROM