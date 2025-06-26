Uses                                       
 Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
 uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
 Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
 VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,   
 Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
 Menus;
  
var
  T : TTimer;
  
function SituacaoPedido: Integer;
var           
  cSituacao: String;
begin                                       
  cSituacao:= dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',              
                                         'SITUACAO',
                                         ['?', '1:s', 'PEDIDO',                        
                                         '?', '2:s', 'ESTAB = :ESTAB AND IDPEDIDO = :IDPEDIDO', 
                                         'P', 'ESTAB',EB_ESTAB.Value, 
                                         'P', 'IDPEDIDO',EB_IDPEDIDO.Value],
                                         [ftString, ftString, ftInteger, ftInteger],     
                                         [20, 1000, 0, 0]);                                       
    Result := StrToIntDef(cSituacao, 0);
end; 

procedure habilitaPessoa(ASender: TObject);
begin
    if SituacaoPedido = 1 then
       EB_IDPESS.Enabled := True
end;


procedure MeuTimer(ASender: TObject);
begin 
  inherited(ASender,'OnTimer')
  T.Enabled := False;  

   ActDesfazer.OnExecute := 'MeuScroll';                       
   ActPrimeiro.OnExecute := 'MeuScroll'; 
   ActAnterior.OnExecute := 'MeuScroll'; 
   ActProximo.OnExecute := 'MeuScroll'; 
   ActUltimo.OnExecute := 'MeuScroll'; 
   ActRefresh.OnExecute := 'MeuScroll'; 
   ActSalvar.OnExecute := 'MeuScroll';    
   ActExcluir.OnExecute := 'MeuScroll';                                                                                               
                    
   habilitaPessoa;
                 
end;  
                 
procedure MeuScroll(Sender : TObject);
begin                   
    inherited(Sender, 'OnExecute');      
    MeuTimer(nil);       
end;            
            
begin    
   T := TTimer.Create(Fpedido);
   T.Interval := 50;                 
   T.OnTimer := 'MeuTimer';   
   MeuTimer(nil);                                 
end;  