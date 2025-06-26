{
--------------------------------------------------------------------------------
                           SOBRE O CODIGO
--------------------------------------------------------------------------------
  Este script gerencia uma tela de "Lista de Precos" com uma grade de itens,
  implementando uma logica complexa de calculo de custos e um fluxo de
  trabalho para geracao e envio de relatorios por email.

  O que ele faz:
  1. CONFIGURACAO DA TELA:
     - O procedimento 'Per3609' e o ponto de entrada. Ele cria e posiciona
       um formulario com uma grade de itens dentro da tela principal.
     - Ele associa todos os eventos customizados (como salvar, incluir,
       navegar) aos botoes e acoes padrao do sistema.

  2. CALCULO DE CUSTOS E MARKUP:
     - Calcula dinamicamente o Custo da Mercadoria Vendida (CMV), o Custo
       de Armazenagem e o Custo de Comissao para cada item.
     - Sempre que o usuario altera o Local de Estoque ou o Preco Base de um
       item, os custos e o Markup sao recalculados automaticamente.
     - As funcoes 'GetCusto' e 'GetCustoArm' buscam os valores no banco de
       dados, enquanto 'GetMarkup' realiza o calculo final.

  3. INTERACAO E EDICAO DA GRADE:
     - Permite incluir e excluir itens na lista de precos.
     - A tecla F3 abre uma tela de pesquisa generica para selecionar Itens
       e Locais de Estoque, facilitando a entrada de dados.
     - Campos calculados buscam as descricoes dos codigos para melhor
       visualizacao.

  4. FLUXO DE SALVAMENTO E ENVIO:
     - Ao salvar, o sistema pergunta ao usuario se deseja enviar a lista de
       precos para os vendedores.
     - Se a resposta for sim, o procedimento 'GeraRelatorio' cria um arquivo
       PDF da lista de precos atual.
     - Em seguida, 'EnviaEmail' busca as configuracoes de SMTP do banco,
       monta e envia um email com o relatorio em PDF como anexo.
     - Apos o envio, a lista e marcada como "Enviada" e os campos sao
       bloqueados para impedir novas edicoes.
--------------------------------------------------------------------------------
}
{$FORM TForm1, uGridItens.sfm}

Uses   
    Classes, Graphics, Controls, Forms, Dialogs, VsNum, VsEdit, VsDBGrid, uStringCache,
    uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
    Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
    VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
    Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
    Menus, BibData, cxGridCol, UProcRapidaCds, ImgList, uPesquisa, uScriptEmail, uCarregaRelatorio;        
    
const                                        
    _nCustoComis = 0.001;
    _cSqlCustoArmz = '#SELECT VALOR FROM CUSTOARMZ
                        WHERE CUSTOARMZ.DATA = (SELECT MAX(AUX.DATA)
                                                  FROM CUSTOARMZ AUX
                                                 WHERE AUX.ESTAB = CUSTOARMZ.ESTAB
                                                   AND AUX.IDESTOQUELOCAL = CUSTOARMZ.IDESTOQUELOCAL)
                          AND CUSTOARMZ.ESTAB = :ESTAB                       
                          AND CUSTOARMZ.IDESTOQUELOCAL = :IDESTOQUELOCAL';      
    _cFormatoNum = '#,##0.000000';
    _cSqlConfEmail = '#SELECT CONFEMAIL.* 
                        FROM CONFEMAIL
                       INNER JOIN FILIALCONF
                          ON FILIALCONF.IDCONFEMAIL = CONFEMAIL.IDCONFEMAIL             
                       WHERE FILIALCONF.ESTAB = :ESTAB';
    _cDirRel = 'C:\Temp';                                                    
var                                                                               
    form : TForm1;
    nMaxId : Integer;                                                           
    
function GetCusto(AEstab, AIdItem, AData, AIdEstoqueLocal, AHora) : Float;
var                                             
    cControlaCMVLocal : String;                                                        
    nCusto : Float;                             
begin                        
    cControlaCMVLocal := St(dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                       'CONTROLACUSTOPORLOCAL',  
                                       ['?', '1:s', 'FILIALCONFGP',
                                        '?', '2:s', 'ESTAB = :ESTAB',        
                                        'P', 'ESTAB', AEstab],
                                        [ftString, ftString, ftInteger],       
                                        [20, 20, 0]));                                            
                                              
    if (cControlaCMVLocal = 'S') then                                         
        nCusto := FloatOf(dmConexao3c.QueryPegaCampo('SEL_CUSTOUNIT_LOCAL',                                              
                                       'CUSTO',                               
                                       ['P', 'ESTAB', AEstab,
                                        'P', 'IDITEM', AIdItem,   
                                        'P', 'DATA', AData,
                                        'P', 'IDESTOQUELOCAL', AIdEstoqueLocal,
                                        'P', 'HORA', AHora],
                                        [ftInteger, ftString, ftDateTime, ftInteger, ftString],                
                                        [0, 20, 0, 0, 20])); 
    else
        nCusto := FloatOf(dmConexao3c.QueryPegaCampo('SEL_CUSTOUNIT',
                                       'CUSTO',                               
                                       ['P', 'ESTAB', AEstab,
                                        'P', 'IDITEM', AIdItem,         
                                        'P', 'DATA', AData,
                                        'P', 'CUSTOGER', 'N',
                                        'P', 'HORA', St(AHora)],            
                                        [ftInteger, ftString, ftDateTime, ftString, ftString],       
                                        [0, 20, 0, 1, 20]));                   
                                                   
                                                                                         
    Result := nCusto;                                        
end;              
                                                                            
function GetCustoArm(AEstab, AIdEstoqueLocal) : Float;   
begin
    Result := FloatOf(dmConexao3c.QueryPegaCampo(_cSqlCustoArmz,
                                       'CUSTO',                               
                                       ['P', 'ESTAB', AEstab,
                                        'P', 'IDESTOQUELOCAL', AIdEstoqueLocal],
                                        [ftInteger, ftInteger],                
                                        [0, 0]));                                                                                  
                                            
end; 

function GetMarkup(ACMV, ACustoArm, ACustoComis, APrecoBase) : Float;   
begin
    Result := ((APrecoBase / (ACMV + ACustoArm + ACustoComis)) - 1) * 100;                                                                                  
                                            
end;                         
             
procedure MeuChangeEstoqueLocal(Sender : TField);             
begin        
    inherited(Sender, 'OnChange'); 
    form.cdsGridItens.FieldByName('CMV').Value := GetCusto(oDadosSis.EstabSelecionado,
                                                           form.cdsGridItens.FieldByName('IDITEM').Value,
                                                           Date,
                                                           Sender.Value,
                                                           '01:01:01');      
                                                                                                           
    form.cdsGridItens.FieldByName('CUSTOARM').Value := GetCustoArm(oDadosSis.EstabSelecionado, Sender.Value );                                                                                                             
                                                                                                            
                                                                                                           
    form.cdsGridItens.FieldByName('CUSTOCOMIS').Value := _nCustoComis;                                                                                                        
end;                                                                                                                         

procedure MeuChangePrecoBase(Sender : TField);
begin
    inherited(Sender, 'OnChange'); 
    form.cdsGridItens.FieldByName('MARKUP').Value := GetMarkup(form.cdsGridItens.FieldByName('CMV').Value,
                                                                form.cdsGridItens.FieldByName('CUSTOARM').Value,
                                                                form.cdsGridItens.FieldByName('CUSTOCOMIS').Value,
                                                                Sender.Value); 
end;       

procedure EnviaEmail;
var                                                                          
    Email          : TScripterEmail;                            
    Cfg            : TScripterEmailCfg;
    cdsConfEmail   : TClientDataSet;      
    OwnerData      : OleVariant;
begin                                    
    cdsConfEmail := TClientDataSet.Create(nil);          
    try                                                 
        cdsConfEmail.Data := dmConexao3c.QueryPegaData(_cSqlConfEmail,
                                       '*',                               
                                       ['P', 'ESTAB', oDadosSis.EstabSelecionado],
                                       [ftInteger],                
                                       [0]);
                                       
        Cfg := TScripterEmailCfg.Create;                                                                 
        Cfg.SMTPHost         := cdsConfEmail.FieldByName('SERVIDOR').AsString;                   
        Cfg.SMTPPorta        := cdsConfEmail.FieldByName('PORTA').AsInteger                                                    
        Cfg.SMTPUsuario      := cdsConfEmail.FieldByName('LOGIN').AsString;        
        Cfg.SMTPSenha        := cdsConfEmail.FieldByName('SENHA').AsString;                       
        Cfg.Remetente        := cdsConfEmail.FieldByName('LOGIN').AsString;
        Cfg.RemetenteNome    := cdsConfEmail.FieldByName('REMETENTE').AsString;                               
        Cfg.UsarAutenticacao := True;   
        //Cfg.VersaoSSL      := 3;                                                            
        Cfg.SMTPAutenticacao := cdsConfEmail.FieldByName('CONEXAOSEGURA').AsInteger;      
        Email := TScripterEmail.New(Cfg);             
        Email.Assunto('Lista de Pre�o');                          
        Email.Mensagem('Segue em anexo lista de pre�o!', tmHTML); 
        Email.AddAnexo('c:\temp\listapreco.pdf');
        Email.EnviarPara('Email@gmail.com.br');
        
        EB_ENVIADO.ItemIndex := 0;
        dmConexao3c.ExecuteListaSimples('UPDATE U_LISTAPRECOCAB SET ENVIADO = ''S'' WHERE U_LISTAPRECOCAB_ID = ' + IntToStr(EB_U_LISTAPRECOCAB_ID.Value), OwnerData, true);
        OwnerData := UnAssigned;
    finally                                                                                   
        cdsConfEmail.Free;                      
        Cfg.Free              
        Email.Free;
    end;
end;     

procedure GeraRelatorio;
var                                             
    cNomeParams : String; 
    cValorParams: String;                                     
    Rel         : TFCarregaRelatorio;  
    cNomeRel    : String;   
    Input      : TMemoryStream;
    cNomeArq   : String;
begin                                                                                         
    cNomeParams := '';                                                                           
    cValorParams := '';                                                                      
    Rel := TFCarregaRelatorio.Create;              
    Input := TMemoryStream.Create;                                             
    
    cNomeArq := 'listapreco';    
    
    if not DirectoryExists(_cDirRel) then
      ForceDirectories(_cDirRel)
   
    
    //adicionando o parametro ESTAB com o valor do oDadosSis.EstabSelecionado
    TFCarregaRelatorio.ParamAdd(cNomeParams, cValorParams, 'U_LISTAPRECOCAB_ID', FFormPadraoU_LISTAPRECOCAB.DsPrincipal.DataSet.FieldByName('U_LISTAPRECOCAB_ID').Value );    
                                                                                                   
    Rel.RelatorioByNome('Listapreco', cNomeParams, cValorParams, false, '', _cDirRel + '\' + cNomeArq + '.pdf');
                                                                                                                        
end;     

procedure BloqueiaComp(lBloqueia : Boolean);
begin
    form.bIncluir.Enabled := not lBloqueia;
    form.bExcluir.Enabled := not lBloqueia;    
    form.gridItens.Enabled := not lBloqueia;
end;
        
procedure BuscaDados;
begin
    form.cdsGridItens.Data := dmConexao3c.QueryPegaData('SEL_PADRAO_COM_WHERE',
                                                       '*',                               
                                                       ['?', '1:s', 'U_LISTAPRECODET',
                                                        '?', '2:s', 'U_LISTAPRECOCAB_ID = :U_LISTAPRECOCAB_ID',
                                                        'P', 'U_LISTAPRECOCAB_ID', EB_U_LISTAPRECOCAB_ID.Value],            
                                                        [ftString, ftString, ftInteger],       
                                                        [100, 100, 0]);    
    if (EB_ENVIADO.ItemIndex = 0) then
        BloqueiaComp(True)
    else
        BloqueiaComp(False);
                                            
end;

procedure MeuIncluir(Sender : TObject);
begin                                                                               
    inherited(Sender, 'OnExecute');
    EB_ESTAB.CodigoValue := oDadosSis.EstabSelecionado;  
    BuscaDados;
end;                                   

procedure MeuSalvar(Sender : TObject);
begin
    inherited(Sender, 'OnExecute');                       
    dmConexao3c.CDSApplyUpdates([form.cdsGridItens ]);         
    
    if MessageDlg('Deseja enviar relat�rio para os vendedores?', mtConfirmation, SetOf([mbYes, mbNo]), 0) = mrYes then
    begin        
        GeraRelatorio;
        EnviaEmail;
    end;                   
end;                             
         

procedure MeuScroll(Sender : TObject);
begin
    inherited(Sender, 'OnExecute');
    BuscaDados;       
end;  
         
procedure bIncluirClick(Sender: TObject);
begin
    if cdsGridItens.State = dsEdit then                                 
        cdsGridItens.Post;
             
    cdsGridItens.Append;    
end;  

procedure bExcluirClick(Sender: TObject);
begin   
    cdsGridItens.Delete; 
    FFormPadraoU_LISTAPRECOCAB.EstadoDoForm := 2;        
end; 
                                                                                  
procedure gridItensKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);   
var
  oPesquisa : TFPesquisa;
begin     
    inherited(Sender, 'OnKeyUp');    
    if (Key = VK_F3) then  
    begin
        if (gridItens.SelectedField.FieldName = 'IDITEM') then
        begin  
            oPesquisa := TFPesquisa.Create(nil);
            try                                                                                  
                oPesquisa.Init('Pesquisa Item', 'SELECT IDITEM AS CODIGO, DESCRICAO FROM ITEM WHERE ESTAB = ' + IntToStr(dmConexao3c.UsaDe(oDadosSis.EstabSelecionado, 'ITEM')) ); 
                if oPesquisa.ShowModal = mrOK then
                begin
                    cdsGridItens.Edit;  
                    cdsGridItens.FieldByName('IDITEM').value := oPesquisa.cds.FieldByName('CODIGO').Value;
                end;                                 
            finally
                oPesquisa.free;
            end;   
        
        end;
        if (gridItens.SelectedField.FieldName = 'IDESTOQUELOCAL') then
        begin  
            oPesquisa := TFPesquisa.Create(nil);
            try                                                                                  
                oPesquisa.Init('Pesquisa Unidade', 'SELECT IDESTOQUELOCAL AS CODIGO, DESCRICAO FROM ESTOQUELOCAL WHERE ESTAB = ' + IntToStr(oDadosSis.EstabSelecionado));
                if oPesquisa.ShowModal = mrOK then
                begin
                    cdsGridItens.Edit;  
                    cdsGridItens.FieldByName('IDESTOQUELOCAL').value := oPesquisa.cds.FieldByName('CODIGO').Value;
                end;  
            finally
                oPesquisa.free;
            end;   
        
        end;           
    end;         
    
    if (Key = VK_DELETE) then
    begin
        cdsGridItens.Edit;
        cdsGridItens.Delete;
    end;     
end;         

procedure cdsGridItensNewRecord(Sender: TDataSet);
begin
   if nMaxId > 0 then
       nMaxId := nMaxId + 1;
   else
   begin
       nMaxId := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',           
                                                 'MAX(U_LISTAPRECODET_ID)',
                                                ['?', '1:s', 'U_LISTAPRECODET',                      
                                                '?', '2:s', '0=0'],
                                                [ftString, ftString, ftInteger],     
                                                [20, 1000, 0]) + 1;
    end;
    Sender.FieldByName('U_LISTAPRECODET_ID').Value := nMaxId;  
        
    Sender.FieldByName('U_LISTAPRECOCAB_ID').Value := EB_U_LISTAPRECOCAB_ID.Value;
    Sender.FieldByName('ESTAB').Value := dmConexao3c.UsaDe(EB_ESTAB.CodigoValue, 'ITEM');          
end;    
       
procedure cdsGridItensAfterPost(DataSet: TDataSet);
begin         
    inherited(DataSet, 'AfterPost');
    FFormPadraoU_LISTAPRECOCAB.EstadoDoForm := 2;      
end;

procedure cdsGridItensCalcFields(DataSet: TDataSet);
begin
    DataSet.FieldByName('DESCITEM').Value := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',           
                                                 'DESCRICAO',
                                                ['?', '1:s', 'ITEM',                      
                                                 '?', '2:s', 'ESTAB = :ESTAB AND IDITEM = :IDITEM',
                                                 'P', 'ESTAB', dmConexao3c.UsaDe(oDadosSis.EstabSelecionado, 'ITEM'),
                                                 'P', 'IDITEM', DataSet.FieldByName('IDITEM').Value ],
                                                [ftString, ftString, ftInteger, ftString],     
                                                [20, 1000, 0, 20]);
                                                
    DataSet.FieldByName('DESCESTOQUELOCAL').Value := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',           
                                                 'DESCRICAO',
                                                ['?', '1:s', 'ESTOQUELOCAL',                      
                                                 '?', '2:s', 'ESTAB = :ESTAB AND IDESTOQUELOCAL = :IDESTOQUELOCAL',
                                                 'P', 'ESTAB', oDadosSis.EstabSelecionado,
                                                 'P', 'IDESTOQUELOCAL', DataSet.FieldByName('IDESTOQUELOCAL').Value ],
                                                [ftString, ftString, ftInteger, ftString],     
                                                [20, 1000, 0, 20]);                                                
end;        

procedure Per3609;                                      
begin          
    EB_ESTAB.Enabled := False;
    EB_ENVIADO.Enabled := False;
    
    form := TForm1.Create(FFormPadraoU_LISTAPRECOCAB);           
    form.Panel1.Parent := FFormPadraoCds_abPrinc_ts1_sbPrinc; 
    TWinControl(form.Panel1).Top := 300;
    TWinControl(form.Panel1).Width := TWinControl(FFormPadraoCds_abPrinc_ts1_sbPrinc).Width;     
    
   
    dmConexao3c.GetDspEdicao(form.cdsGridItens, 'U_LISTAPRECODET', true);
    form.cdsGridItens.Open;     
    
    BuscaDados;   
                                                       
    TFloatField(form.cdsGridItens.FieldByName('CMV')).DisplayFormat := _cFormatoNum;
    TFloatField(form.cdsGridItens.FieldByName('CUSTOARM')).DisplayFormat := _cFormatoNum;
    TFloatField(form.cdsGridItens.FieldByName('CUSTOCOMIS')).DisplayFormat := _cFormatoNum;    
    TFloatField(form.cdsGridItens.FieldByName('MARKUP')).DisplayFormat := _cFormatoNum;    
    TFloatField(form.cdsGridItens.FieldByName('PRECOBASE')).DisplayFormat := _cFormatoNum;    
                                                                          
    form.cdsGridItens.FieldByName('IDESTOQUELOCAL').OnChange := 'MeuChangeEstoqueLocal';     
    form.cdsGridItens.FieldByName('PRECOBASE').OnChange := 'MeuChangePrecoBase'
                                                                                             
    ActAnterior.OnExecute := 'MeuScroll';
    ActPrimeiro.OnExecute := 'MeuScroll';
    ActProximo.OnExecute := 'MeuScroll';
    ActUltimo.OnExecute := 'MeuScroll';
    ActRefresh.OnExecute := 'MeuScroll';    
                      
    ActIncluir.OnExecute := 'MeuIncluir';
    ActSalvar.OnExecute := 'MeuSalvar';
end; 

begin
    Per3609;        
end;
