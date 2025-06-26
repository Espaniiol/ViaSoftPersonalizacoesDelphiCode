{
--------------------------------------------------------------------------------
                           SOBRE O CODIGO
--------------------------------------------------------------------------------
  Este script executa uma atualizacao em massa na tabela de titulos a pagar
  (PDUPPAGA).

  O que ele faz:
  1. Busca todos os titulos que estao em aberto (QUITADA = 'N') e que
     pertencem a um fornecedor especifico (EB_FORNECEDOR).
  2. Percorre cada um desses titulos encontrados.
  3. Para cada titulo, ele atualiza o campo 'BANCO' com o valor do
     componente de tela 'EB_BANCO' e define o campo 'JUROS' com o valor fixo '1'.
  4. Salva todas as alteracoes no banco de dados de uma so vez.

  Em resumo: e uma rotina para aplicar um juro e alterar o banco de todos
  os debitos pendentes de um unico fornecedor.
--------------------------------------------------------------------------------
}
Uses
  Classes,  Graphics,  Controls,  Forms,  Dialogs,  VsNum,  VsEdit, VsDBGrid, uStringCache,
  uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, BtChkBox, DB, ExtCtrls,
  Tsmcode, VsEdRigh, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, VsLabel, DBClient,
  VsMes, VsMesAno, VsDBLoCo, VsEdRigh, VsEditAl, VsDBComb, VsDbNum, VsDBEdit, bib, Windows,
  Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, DBGrids, Grids, SysUtils, ComCtrls,
  Menus;

var
  cdsPDUPPAGA : TClientDataSet;

begin
  cdsPDUPPAGA := TClientDataSet.Create(nil);
  dmConexao3c.GetDspEdicao(cdsPDUPPAGA, 'PDUPPAGA');
  cdsPDUPPAGA.Open;

  cdsPDUPPAGA.Data := dmConexao3c.QueryPegaData('SEL_PESQUISAFILTRO',
                                                '*',
                                               [ '?', '1:s', 'PDUPPAGA'    // TABELA DE ORIGEM
                                                 , '?', '2:s', 'QUITADA= ''N'' AND FORNECEDOR =:FORNECEDOR ' // FILTRO OPCIONAL
                                                 , 'P', 'FORNECEDOR' , EB_FORNECEDOR.Value],
                                               [ftString, ftString, ftInteger],
                                               [1000, 1000, 0]);

  cdsPDUPPAGA.First;
  while not cdsPDUPPAGA.Eof do
  begin

      cdsPDUPPAGA.Edit;
      cdsPDUPPAGA.FieldByName('BANCO').Value := EB_BANCO.Value;
      cdsPDUPPAGA.FieldByName('JUROS').Value := 1;

      cdsPDUPPAGA.post;
      cdsPDUPPAGA.next;

  end;

  dmConexao3c.CDSApplyUpdates([cdsPDUPPAGA]);

  // E uma boa pratica liberar a memoria apos o uso
  cdsPDUPPAGA.Free;
end;
