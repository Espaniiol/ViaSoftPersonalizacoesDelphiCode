Uses
 Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
 uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
 Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
 VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
 Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
 Menus, uStringCache;   
    
const        
    _seqItem = 0;
    _item = 1;     
                                
var   
    cdsNotaConf : TVsClientDataSet;
    cNotaConf : String;
    cSql : String;                                                      
    T : TTimer; 
    cUser : String;   
                           
procedure MeuExecute(Sender : TObject);  
begin                                
    try             
        cdsNotaConf := TVsClientDataSet.Create(nil);    
                                                        
        cNotaConf := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                         'TO_CHAR(NOTACONF)',          
                                        ['?', '1:s', 'U_NFCFGUSEREXC',                      
                                        '?', '2:s', 'NOTACONF = :NOTACONF',
                                        'P', 'NOTACONF', FNfCab.ValorNaTela('NOTACONF')], 
                                        [ftString, ftString, ftInteger],     
                                        [20, 1000, 0]);        
                                                               
        cSql := '#SELECT PUSUARIO.USERID 
                  FROM PUSUARIO
                 WHERE ((('',''|| CAST((SELECT U_NFCFGUSEREXC.USERID FROM U_NFCFGUSEREXC WHERE NOTACONF = ' + IntToStr(FNfCab.ValorNaTela('NOTACONF')) + ') AS VARCHAR(1000)) ||'','') LIKE ''%,'' || PUSUARIO.USERID || '',%''))      
                   AND PUSUARIO.USERID = ''' + oDadosSis.UserId + '''';
                                        
        cUser := dmConexao3c.QueryPegaCampo(cSql,
                                         '*',          
                                        [],
                                        [ftString],     
                                        [200]); 
                                        
                                        
        if (cNotaConf <> '') and (cUser = '') then
            ShowMessage('Usuário sem acesso para realizar exclusão para essa configuração de nota!');    
        else                                   
            inherited(Sender, 'OnExecute');  
    finally                                                                                               
        cdsNotaConf.Free;      
    end;
end;                                                                        
                                                                                                
function BuscarTextoCab: string;
var
    cSql : String;                   
begin                                    
    cSql := Format('#WITH CID AS ( SELECT DADOS.CIDADE,
                     CIDADE.NOME          
                FROM (                 
              SELECT COALESCE(ENDERECO.CIDADE, CONTAMOV.CIDADE) AS CIDADE
                FROM CONTAMOV   
                LEFT JOIN ENDERECO       
                  ON ENDERECO.NUMEROCM = CONTAMOV.NUMEROCM
                 AND ENDERECO.SEQENDERECO = %s   
               WHERE CONTAMOV.NUMEROCM = %s
                   ) DADOS                                                                                    
               INNER JOIN CIDADE 
                  ON CIDADE.CIDADE = DADOS.CIDADE
    )
            SELECT DISTINCT
                   REPLACE(    
                    REPLACE(                                    
                        DBMS_LOB.SUBSTR(U.TEXTOCAB, 4000, 1)  
                        ,''{CIDADE}'',C.NOME)                  
                        ,''{LOCAISDESCARTE}'', LISTAGG(DBMS_LOB.SUBSTR(U.TESTE, 4000, 1), CHR(13)) OVER ()) AS TEXTOCAB
              FROM NFCFG                                                                       
             INNER JOIN NFCFG_U U       
                ON U.NOTACONF = NFCFG.NOTACONF                                             
             INNER JOIN CID C 
                ON 0=0
             INNER JOIN U_LOCAISDESCARTE U
                ON U.CIDADE = C.CIDADE
             WHERE NFCFG.NOTACONF = %s',[FloatToStr(EB_SEQENDERECO.Value), IntToStr(EB_NUMEROCM.CodigoValue), IntToStr(EB_NOTACONF.CodigoValue)]);
   
     ShowMessage(cSql);    
         
     Result := dmConexao3c.QueryPegaCampo(cSql,  
                                        'TEXTOCAB',                                                
                                        [],                  
                                        [ftString],   
                                        [Length(cSql)]);                                                                                                                                                           
          
end;                                                     
             
function Validacao: Boolean;
var                                                         
  cEstab   : String;
  cRamo    : String; 
  cProduto : String;
  cConfigNf: String;
  i: integer;
begin                   
    Result := False;                   
                                            
    cEstab := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',              
                                        'U.LOGREVERSAEMB',
                                       ['?', '1:s', 'PEMPRESA_U U',                      
                                       '?', '2:s', 'EMPRESA = :EMPRESA', 
                                       'P', 'EMPRESA', oDadosSis.EstabSelecionado],
                                       [ftString, ftString, ftInteger],     
                                       [20, 1000, 0]);  
                                                                             
    if St(cEstab) = 'S' then                                            
    begin                         
                                                            
     cRamo := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',       
                                        'U.LOGREVERSAEMB',
                                       ['?', '1:s', 'PPESCLI 
                                       INNER JOIN PRAMOS         
                                          ON PPESCLI.RAMO = PRAMOS.RAMO                              
                                       INNER JOIN PRAMOS_U U     
                                          ON U.RAMO = PRAMOS.RAMO',                      
                                       '?', '2:s', 'PPESCLI.CLIENTE = :NUMEROCM', 
                                       'P', 'NUMEROCM', EB_NUMEROCM.CodigoValue],
                                       [ftString, ftString, ftInteger],     
                                       [1000, 1000, 0]);     
          
        if St(cRamo) = 'S' then                              
        cConfigNf := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',       
                                                'U.LOGREVERSAEMB',             
                                               ['?', '1:s', 'NFCFG   
                                                INNER JOIN NFCFG_U U           
                                                  ON U.NOTACONF = NFCFG.NOTACONF',                      
                                                '?', '2:s', 'NFCFG.NOTACONF = :NOTACONF', 
                                                'P', 'NOTACONF', EB_NOTACONF.CodigoValue],
                                               [ftString, ftString, ftInteger],        
                                               [1000, 1000, 0]);  
                                                                    
          
        
        if St(cConfigNf) = 'S' then
        begin                                                      
            for i := 1 to FNfCab.sgProdutos.RowCount - 1 do                    
            begin                                                                      
                cProduto := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',       
                                               'LOGREVERSAEMB',   
                                               ['?', '1:s', 'ITEMAGRO_U
                                               INNER JOIN ITEMAGRO        
                                               ON ITEMAGRO_U.ITEM = ITEMAGRO.ITEM',                                                                      
                                               '?', '2:s', 'ITEMAGRO.ITEM = :ITEM', 
                                               'P', 'ITEM', FNfCab.sgProdutos.Cells[_item,i]],
                                               [ftString, ftString, ftInteger],     
                                               [1000, 1000, 0]); 
                                                               
                if St(cProduto) = 'S' then
                begin
                  Result := True;  
                  break; 
                end;    
            end;                                                                                                         
                                                
        end;   
    end;                            
end;                 
                                                                                                  
Procedure MeuSalvar(ASender: TObject);               
begin          
        
 
                        
    TStringCache.SetCacheString('PERSON_EMB', oDadosSis.UserId, Validacao);
    
    TStringCache.SetCacheString('PERSON_CAB', oDadosSis.UserId, BuscarTextoCab);
    
               
                                                               
    Inherited(ASender, 'OnExecute');
end;     
        
procedure MeuTimer(ASender : TObject);
begin
  T.Enabled := False;

  if oDadosSis.UserId = 'VIASOFT.GUILHERME' then
  begin
    ActSalvar.OnExecute := 'MeuSalvar';
  end;
end;                   

begin                      
    T := TTimer.Create(FNfCab);
    //FNfCab.ActExcluir.OnExecute := 'MeuExecute';  
    T.Interval := 50;                 
    T.OnTimer := 'MeuTimer';                                
end;