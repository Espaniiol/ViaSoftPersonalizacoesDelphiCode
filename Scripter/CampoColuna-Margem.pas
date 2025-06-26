{
--------------------------------------------------------------------------------
                          SOBRE O CODIGO
--------------------------------------------------------------------------------
  Este script tem como objetivo principal calcular e exibir dinamicamente a
  margem de lucro em uma tela de itens.

  O que ele faz:
  1. INICIALIZACAO COM TIMER:
     - Um Timer e disparado uma unica vez, logo apos a abertura da tela,
       para configurar todo o ambiente de calculo de margem.

  2. CRIA COLUNA DE MARGEM DINAMICA:
     - O codigo cria programaticamente uma nova coluna na grade de itens
       chamada "Margem por Item".

  3. CALCULO DE MARGEM POR ITEM (COM CACHE):
     - Para cada item na grade, a funcao 'BuscaDados' calcula a margem.
     - Para otimizar a performance e evitar consultas repetidas ao banco de
       dados, o 'Custo Gerencial' de cada item e armazenado em um dataset
       de cache em memoria (cdsCache). Se o custo de um item ja foi
       buscado, ele e lido do cache nas proximas vezes, tornando o
       processo muito mais rapido.

  4. CALCULO DE MARGEM GERAL:
     - O procedimento 'calculaMargemGeral' soma os custos e valores de
       todos os itens para calcular a margem de lucro total do documento.
     - O resultado e exibido em um campo especifico ('margemGeral').

  5. ATUALIZACAO AUTOMATICA:
     - Os calculos de margem (tanto o geral quanto o da coluna) sao
       refeitos automaticamente sempre que o usuario navega entre os
       registros, salva, edita ou exclui um item, garantindo que os
       valores de margem estejam sempre atualizados.
--------------------------------------------------------------------------------
}

{$FORM TFo1, Unit1.sfm}

Uses
  Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
  uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
  Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
  VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
  Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
  Menus, CxGridCol;

var
  colMargem: TcxGridColuna;
  T : TTimer;
  cdsCache, cdsGeral : TClientDataSet;

function BuscaDados(cCampo : String; AChave : String): String;
var
  cTexto : String;
  nCustoGerencial : Float;
  nQuantidade, nValorTotal : Float;
  cdsCusto : TVsClientDataset;
  Txt      : TStringList;
  nChaveEstab, nChaveTabela, nChaveItem: Integer;

begin
  Txt := TStringList.Create;
    try
      Txt.StrictDelimiter := True;
      Txt.Delimiter := '¤';
      Txt.DelimitedText := AChave;
      nChaveEstab := StrToInt(Txt.Strings[0]);
      nChaveTabela := StrToInt(Txt.Strings[1]);
      nChaveItem := StrToInt(Txt.Strings[2]);
      nQuantidade := StrToFloat(Txt.Strings[4]);
      nValorTotal := StrToFloat(Txt.Strings[3]);
    finally
      Txt.Free;
    end;

    if not (cdsCache.Locate('ITEM;ESTAB;TABELA', [nChaveItem,nChaveEstab,nChaveTabela], 0)) then
    begin
        nCustoGerencial := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                                      'CUSTOGERENCIAL',
                                                     ['?', '1:s', 'TABPRECOITEM',
                                                      '?', '2:s', 'ITEM = :ITEM AND ESTAB = :ESTAB AND TABELA = :TABELA',
                                                      'P', 'ITEM', nChaveItem,
                                                      'P', 'ESTAB', nChaveEstab,
                                                      'P', 'TABELA', nChaveTabela],
                                                     [ftString, ftString, ftInteger, ftInteger, ftInteger],
                                                     [1000, 2000, 0, 0, 0]);
        cdsCache.Append;
        cdsCache.FieldByName('ITEM').Value := nChaveItem;
        cdsCache.FieldByName('ESTAB').Value := nChaveEstab;
        cdsCache.FieldByName('TABELA').Value := nChaveTabela;
        cdsCache.FieldByName('CUSTOGERENCIAL').Value := nCustoGerencial;
        cdsCache.Post;

      cTexto := FormatFloat('#,##0.00', (1 - nCustoGerencial * nQuantidade / nValorTotal) * 100);
    end
  else
    cTexto := FormatFloat('#,##0.00', (1 - cdsCache.FieldByName(cCampo).Value * nQuantidade /nValorTotal) * 100);
  Result := cTexto;
end;

procedure GetMargemItem(AChave : String; var ATexto: String);
begin
  ATexto := BuscaDados('CUSTOGERENCIAL', AChave);
end;

procedure calculaMargemGeral;
var
  nQuantidadeGeral, nValorTotalGeral, nCustoGerencial : Float;
begin
  nQuantidadeGeral := 0;
  nValorTotalGeral := 0;

  cdsGeral.First;
  while not cdsGeral.Eof do
    begin
      nCustoGerencial := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                                    'CUSTOGERENCIAL',
                                                   ['?', '1:s', 'TABPRECOITEM',
                                                    '?', '2:s', 'ITEM = :ITEM AND ESTAB = :ESTAB AND TABELA = :TABELA',
                                                    'P', 'ITEM', cdsGeral.FieldByName('ITEM').AsInteger,
                                                    'P', 'ESTAB', cdsGeral.FieldByName('ESTABTABPRECO').AsInteger,
                                                    'P', 'TABELA', cdsGeral.FieldByName('TABELAPRECO').AsInteger],
                                                   [ftString, ftString, ftInteger, ftInteger, ftInteger],
                                                   [1000, 2000, 0, 0, 0]);

      nQuantidadeGeral := nQuantidadeGeral + (nCustoGerencial * cdsGeral.FieldByName('QUANTIDADE').Value);
      nValorTotalGeral := nValorTotalGeral + cdsGeral.FieldByName('VLRTOT').Value;

      cdsGeral.Next;
    end;

  margemGeral.Value := (1 - (nQuantidadeGeral / nValorTotalGeral)) * 100;
end;

procedure criaColunaMargem;
begin
  if Assigned (colMargem)then
    begin
      colMargem.Free;
      colMargem := TcxGridColuna.Create (View_Itens, 'Margem por Item', 'NUMERO', 0, 'ESTABTABPRECO;TABELAPRECO;ITEM;VLRTOT;QUANTIDADE');
      colMargem.EventoMostrarValorNoGrid := 'GetMargemItem';
      colMargem.Coluna.HeaderAlignmentHorz :=  taRightJustify;
      colMargem.Decimais := 4;
      colMargem.SomenteLeitura := True;
    end;
end;

procedure MeuAfterPost(Sender : TObject);
var
    nQuantidadeGeral, nValorTotalGeral, nCustoGerencial : Float;
begin
    Inherited(Sender, 'AfterPost');
    nQuantidadeGeral := 0;
    nValorTotalGeral := 0;

    cdsGeral.First;
    while not cdsGeral.Eof do
    begin
        nCustoGerencial := dmConexao3c.QueryPegaCampo('SEL_PADRAO_COM_WHERE',
                                                        'CUSTOGERENCIAL',
                                                        ['?', '1:s', 'TABPRECOITEM',
                                                         '?', '2:s', 'ITEM = :ITEM AND ESTAB = :ESTAB AND TABELA = :TABELA',
                                                         'P', 'ITEM', cdsGeral.FieldByName('ITEM').AsInteger,
                                                         'P', 'ESTAB', cdsGeral.FieldByName('ESTABTABPRECO').AsInteger,
                                                         'P', 'TABELA', cdsGeral.FieldByName('TABELAPRECO').AsInteger],
                                                        [ftString, ftString, ftInteger, ftInteger, ftInteger],
                                                        [1000, 2000, 0, 0, 0]);

        nQuantidadeGeral := nQuantidadeGeral + (nCustoGerencial * cdsGeral.FieldByName('QUANTIDADE').Value);
        nValorTotalGeral := nValorTotalGeral + cdsGeral.FieldByName('VLRTOT').Value;

        cdsGeral.Next;
    end;


    margemGeral.Value := (1 - (nQuantidadeGeral / nValorTotalGeral)) * 100;
end;

procedure MeuScroll(Sender : TObject);
begin
  inherited(Sender, 'OnExecute');
  calculaMargemGeral;
  criaColunaMargem;
end;

procedure MeuTimer(Sender : TObject);
begin
  Inherited(Sender, 'OnTimer');
  T.Enabled := False;

  GroupBox1.Parent := pnTop;
  TControl (GroupBox1).left:= btnGeraDoctos.ExplicitLeft;
  TControl (GroupBox1).top:= btnGeraDoctos.ExplicitTop + 25;

  colMargem.Free;
  colMargem := TcxGridColuna.Create (View_Itens, 'Margem por Item', 'NUMERO', 0, 'ESTABTABPRECO;TABELAPRECO;ITEM;VLRTOT;QUANTIDADE');
  colMargem.EventoMostrarValorNoGrid := 'GetMargemItem';
  colMargem.Coluna.HeaderAlignmentHorz :=  taRightJustify;
  colMargem.Decimais := 4;
  colMargem.SomenteLeitura := True;

  cdsCache := TClientDataSet.Create(nil);
  cdsCache.Data := dmConexao3c.QueryPegaData('SEL_PADRAO_COM_WHERE',
                                             'ESTAB, TABELA, ITEM, CUSTOGERENCIAL',
                                            ['?', '1:s', 'TABPRECOITEM',
                                             '?', '2:s', '0 = 1'],
                                            [ftString, ftString],
                                            [1000, 2000]);

  View_Itens.DataController.DataSource.DataSet.First;

  while not View_Itens.DataController.DataSource.DataSet.Eof do
    begin
      View_Itens.DataController.DataSource.DataSet.Next;
    end;

  cdsGeral := TClientDataSet.Create(nil);
  cdsGeral := View_Itens.DataController.DataSource.DataSet;
  cdsGeral.AfterPost := 'MeuAfterPost';

  ActDesfazer.OnExecute := 'MeuScroll';
  ActPrimeiro.OnExecute := 'MeuScroll';
  ActAnterior.OnExecute := 'MeuScroll';
  ActProximo.OnExecute  := 'MeuScroll';
  ActUltimo.OnExecute   := 'MeuScroll';
  ActRefresh.OnExecute  := 'MeuScroll';
  ActSalvar.OnExecute   := 'MeuScroll';
  ActExcluir.OnExecute  := 'MeuScroll';

  calculaMargemGeral;
end;

begin
  T := TTimer.Create(FTrocaBarter);
  T.Interval := 50;
  T.OnTimer := 'MeuTimer';
end;