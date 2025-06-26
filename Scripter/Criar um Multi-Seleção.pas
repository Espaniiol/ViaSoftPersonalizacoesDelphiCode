Uses
    Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
    uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
    Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
    VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
    Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
    Menus, WhichLight;
    
var
    wItem : TWhichLight;  

procedure AtualizaCampos;
begin                     
    wItem.Selecao := EB_PRODUTOS.Text;                                 
end;                      
                                          
procedure MeuDigitou(ASender : Object);
begin                                                             
    //Inherited(ASender, 'OnDigitou');                    
    if Length(wItem.CodigoValue) > 0 then
        EB_PRODUTOS.Text := wItem.CodigoValue                
    else if Length(wItem.Selecao) > 0 then
        EB_PRODUTOS.Text := wItem.Selecao;
end;
                                          
procedure MeuExecute(Sender : TObject);
begin
    try                                   
        Inherited(Sender, 'OnExecute');                                                  
        AtualizaCampos;
    except
        MessageDlg(StringReplace(LastExceptionMessage,'Erro ao chamar método padrão pelo VsScripter!!','',0), mtError, 4, 0);
    end;                 
end;

                    
procedure Per3929;
begin        
    EB_PRODUTOS.Enabled := False;
    EB_PRODUTOS.Visible := False;
    
    wItem := TWhichLight.Create(FFormPadraoU_ITENSPERMITIDOS);
    wItem.Parent := EB_PRODUTOS.Parent;    
    wItem.Caption := 'Produtos:';
    wItem.Hint := 'Informe os itens!';
    wItem.LabelLeft := 7;
    wItem.LabelAlign := 0; 
    wItem.SetBounds(8, EB_PRODUTOS.ExplicitTop, 654, 400);
    wItem.LookupOptions.CodigoFieldType := 'ftdString';
    wItem.LabelLeft := 0; 
    wItem.LookupLeft := 83;
    wItem.LookupWidth := 200;
                                                                        
    wItem.BringToFront;
    wItem.LookupOptions.RelativoTableName := 'ITEM';      
    wItem.LookupOptions.RelativoCodigo := 'IDITEM';    
    wItem.LookupOptions.RelativoDescricao := 'DESCRICAO';                   
    wItem.OnDigitou := 'MeuDigitou'; 
end;        
 
begin
    Per3929;
    AtualizaCampos;
    
    ActAnterior.OnExecute := 'MeuExecute';
    ActPrimeiro.OnExecute := 'MeuExecute';
    ActProximo.OnExecute  := 'MeuExecute';
    ActUltimo.OnExecute   := 'MeuExecute'; 
    ActIncluir.OnExecute  := 'MeuExecute';
    ActDesfazer.OnExecute := 'MeuExecute';
    ActExcluir.OnExecute  := 'MeuExecute';
    ActRefresh.OnExecute  := 'MeuExecute';
end;
