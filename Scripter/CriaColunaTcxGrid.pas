Uses    
 Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
 uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
 Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
 VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
 Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
 Menus, CxGridCol;
 
var
    colCusto: TcxGridColuna; //TIPO DO OBJETO
    T : TTimer; 
    nCusto : Float;
    cdsCache : TClientDataSet;
    
procedure BuscaCusto; 
begin
    nCusto := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                                'PCUSTO(2, ITEMAGRO.ITEM, 2, CURRENT_DATE, NULL) AS CUSTO',
                                                ['?', '1:s', 'ITEMAGRO',
                                                '?', '2:s', 'ITEM = :ITEM',
                                                'P', 'ITEM', EB_ITEM.Value], 
                                                [ftString, ftString, ftInteger],
                                                [1000, 2000, 0]);                                               
end;

procedure MeuExecutar(Sender: TObject); 
begin                                         
    Inherited(Sender, 'OnExecute');
     
    BuscaCusto; 
    
    cdsCache.CloneCursor(cdsSaldosItem, False, False);
    
    cdsSaldosItem.First;
    while not cdsSaldosItem.Eof do
    begin
        cdsSaldosItem.Next;
    end;
end;

function BuscaDados(cCampo : String; AChave : String): String; 
var                                                                   
    cTexto : String; 
    nCodSaldo : integer;
    cdsCusto : TVsClientDataset;  
       
begin                        
    nCodSaldo := StrToInt(AChave); 
    try    
        if (cdsCache.Locate('CODIGOSALDO', [nCodSaldo], 0)) then         
            cTexto := cdsCache.FieldByName(cCampo).Value * nCusto;     
            cTexto := FormatFloat('#,##0.00',cTexto);                                       
        Result := cTexto;           
    finally
          
    end; 
end;        
    
procedure GetCusto(AChave : String; var ATexto: String);
begin          
    ATexto := BuscaDados('SALDO', AChave);                                                                                         
end                        
                        
procedure MeuTimer(Sender : TObject);                                          
begin
    //Inherited(Sender, 'OnTimer');                                                                                       
    T.Enabled := False;
    
    cdsCache := TClientDataSet.Create(nil);                           
                         
    actExecutar.OnExecute := 'MeuExecutar';
                       
    colCusto := TcxGridColuna.Create(cxSaldosDB , 'Custo', 'Numero', 15, 'CODIGOSALDO');
    colCusto.EventoMostrarValorNoGrid := 'GetCusto';    
    colCusto.Coluna.HeaderAlignmentHorz :=  taRightJustify;  
    colCusto.Decimais := 2;     

end;                                        
                                                               
begin                      
    T := TTimer.Create(FConsultaPreco); // TELA DO SISTEMA                                           
    T.Interval := 50;                 
    T.OnTimer := 'MeuTimer';       
end; 