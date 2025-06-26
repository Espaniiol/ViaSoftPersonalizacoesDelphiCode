{
--------------------------------------------------------------------------------
                          SOBRE O CODIGO
--------------------------------------------------------------------------------
  Este script tem como objetivo principal sincronizar dados bancarios de forma
  automatica.

  O que ele faz:
  1. INTERCEPTA O SALVAMENTO: O codigo substitui a acao padrao de "Salvar".

  2. CAPTURA DADOS (ANTES E DEPOIS):
     - Antes de salvar, ele guarda uma copia dos dados originais do registro
       (em 'cdsOldValue').
     - Executa o salvamento padrao do sistema.
     - Apos salvar, ele pega os dados atualizados do mesmo registro (em
       'cdsNewValue').

  3. COMPARA E ATUALIZA:
     - O script compara os dados antigos com os novos.
     - Se qualquer informacao bancaria foi alterada, ele automaticamente
       busca todos os titulos a pagar que estao em aberto para o mesmo
       fornecedor.
     - Em seguida, ele atualiza os dados bancarios (Banco, Agencia, Conta,
       Chave PIX, etc.) de todos esses titulos em aberto para que fiquem
       iguais aos dados recem-salvos.

  Em resumo: Se o usuario edita os dados bancarios de um fornecedor, este
  codigo garante que todos os seus titulos pendentes sejam atualizados com
  as novas informacoes, evitando pagamentos para contas antigas.
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
  cdsOldValue : TClientDataSet;
  cdsNewValue : TClientDataSet;
  i : integer;

procedure BuscaOldValue;
begin
    cdsOldValue.Data := dmConexao3c.QueryPegaData('SEL_PADRAO_COM_WHERE',
                                                  '* ',
                                                 ['?', '1:s', 'CONTAMOV',
                                                  '?', '2:s', 'NUMEROCM = :NUMEROCM',
                                                  'P', 'NUMEROCM', EB_NUMEROCM.Value],
                                                 [ftString, ftString, ftInteger],
                                                 [20, 1000, 0]);
    // ShowMessage('Valor Antigo: ' + cdsOldValue.FieldByName('BANCO').AsString);
end;

procedure BuscaNewValue;
begin
    cdsNewValue.Data := dmConexao3c.QueryPegaData('SEL_PADRAO_COM_WHERE',
                                                  '* ',
                                                 ['?', '1:s', 'CONTAMOV',
                                                  '?', '2:s', 'NUMEROCM = :NUMEROCM',
                                                  'P', 'NUMEROCM', EB_NUMEROCM.Value],
                                                 [ftString, ftString, ftInteger],
                                                 [20, 1000, 0]);
    // ShowMessage('Valor Novo: ' + cdsNewValue.FieldByName('BANCO').AsString);
end;

procedure MeuSalvar(Sender : TObject);
begin
  cdsOldValue := TClientDataSet.Create(nil);
  cdsNewValue := TClientDataSet.Create(nil);

  cdsPDUPPAGA := TClientDataSet.Create(nil);
  dmConexao3c.GetDspEdicao(cdsPDUPPAGA, 'PDUPPAGA');
  cdsPDUPPAGA.Open;

  BuscaOldValue;
  Inherited(Sender, 'OnExecute');
  BuscaNewValue;

  cdsPDUPPAGA.Data := dmConexao3c.QueryPegaData('SEL_PESQUISAFILTRO',
                                                '*',
                                               [ '?', '1:s', 'PDUPPAGA'
                                               , '?', '2:s', 'QUITADA= ''N'' AND FORNECEDOR =:FORNECEDOR '
                                               , 'P', 'FORNECEDOR' , EB_NUMEROCM.Value],
                                               [ftString, ftString, ftInteger],
                                               [1000, 1000, 0]);

  if cdsOldValue.RecordCount > 0 then
  begin
    for i := 0 to cdsOldValue.FieldCount - 1 do
    begin
      if cdsOldValue.Fields.Fields[i].Value <> cdsNewValue.Fields.Fields[i].Value then
      begin
        cdsPDUPPAGA.First;
        while not cdsPDUPPAGA.Eof do
        begin
          cdsPDUPPAGA.Edit;
          cdsPDUPPAGA.FieldByName('BANCO').Value := cdsNewValue.FieldByName('BANCO').Value;
          cdsPDUPPAGA.FieldByName('AGENCIA').Value := cdsNewValue.FieldByName('AGENCIA').Value;
          cdsPDUPPAGA.FieldByName('CONTA').Value := cdsNewValue.FieldByName('CONTA').Value;
          cdsPDUPPAGA.FieldByName('TIPCONTA').Value := cdsNewValue.FieldByName('TIPCONTA').Value;
          cdsPDUPPAGA.FieldByName('CODID1').Value := cdsNewValue.FieldByName('CODID1').Value;
          cdsPDUPPAGA.FieldByName('CODID2').Value := cdsNewValue.FieldByName('CODID2').Value;
          cdsPDUPPAGA.FieldByName('FAVORECIDO').Value := cdsNewValue.FieldByName('FAVORECIDO').Value;
          cdsPDUPPAGA.FieldByName('IDPIXREFBANCDET').Value := cdsNewValue.FieldByName('IDPIXREFBANCDET').Value;
          cdsPDUPPAGA.FieldByName('CHAVEPIX').Value := cdsNewValue.FieldByName('CHAVEPIX').Value;
          cdsPDUPPAGA.post;
          cdsPDUPPAGA.next;
        end;
          DmConexao3c.CDSApplyUpdates([cdsPDUPPAGA]);
          // Interrompe o loop 'for', pois ja encontrou a mudanca e atualizou.
          Break;
      end;
    end;
  end;
  
  // Libera a memoria
  cdsOldValue.Free;
  cdsNewValue.Free;
  cdsPDUPPAGA.Free;
end;

begin
  ActSalvar.OnExecute := 'MeuSalvar';
end;