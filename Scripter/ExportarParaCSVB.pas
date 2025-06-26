{$FORM TForm1, Exportar.sfm}
{
    PER-3588 - Exportar itens da tabela para Excel
    23/04/2025 - Eric Ribeiro e Guilherme Schlickmann
} 
uses
  SysUtils, Classes, Graphics, Controls, Forms, Dialogs, VsNum, VsEdit, VsDBGrid, 
  uStringCache, uVsLookupVsScripter, VsCombo, VsSpin, VsMask, VsEdRigh, VsPageCo, 
  BtChkBox, DB, ExtCtrls, Tsmcode, VsDate, VsDateFT, VsDateTime, VsDiaMes, VsHora, 
  VsLabel, DBClient, VsMes, VsMesAno, VsDBLoCo, VsEditAl, VsDBComb, VsDbNum, 
  VsDBEdit, bib, Windows, Messages, StdCtrls, uVsClientDataSet, Buttons, DBCtrls, 
  DBGrids, Grids, ComCtrls, Menus, ComObj, Variants, VsSGrid;
 
procedure btnExportarClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  ArqCSV: TextFile;
  i, j, k: Integer;
  celula, novaCelula, linhaCSV, cabecalhoUnico, limpa: string;
  c: Char;
  campos: array[0..11] of string;
  colunas: array[0..11] of integer;
begin
  inherited(Sender, 'OnClick');

  SaveDialog := TSaveDialog.Create(nil);
  SaveDialog.FileName := 'Exportacao_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.csv';
  SaveDialog.Filter := 'Arquivo CSV (*.csv)|*.csv';
  SaveDialog.DefaultExt := 'csv';
  SaveDialog.Title := 'Salvar como CSV';

  if not SaveDialog.Execute(True) then
  begin
    SaveDialog.Free;
    Exit;
  end;

  campos[0] := 'Seq';
  campos[1] := 'Item';
  campos[2] := 'Descri��o';
  campos[3] := 'Pre�o';
  campos[4] := 'Custo Gerencial';
  campos[5] := '% Margem';
  campos[6] := '% Margem M�nima';
  campos[7] := 'Ativo';
  campos[8] := 'C�d. Marca';
  campos[9] := 'Descri��o';
  campos[10] := 'C�d. Grupo';
  campos[11] := 'Des. Grupo';

  for j := 0 to 11 do
    colunas[j] := -1;

  for j := 0 to sgTabPreco.ColCount - 1 do
    for i := 0 to 11 do
      if UpperCase(Trim(sgTabPreco.Cells[j, 0])) = UpperCase(campos[i]) then
        colunas[i] := j;

  for j := 0 to 11 do
    if colunas[j] = -1 then
    begin
      MessageDlg('Coluna "' + campos[j] + '" n�o encontrada.', mtError, [mbOK], 0);
      SaveDialog.Free;
      Exit;
    end;

  AssignFile(ArqCSV, SaveDialog.FileName);
  try
    Rewrite(ArqCSV);

    // Escreve o cabe�alho da tela
    WriteLn(ArqCSV, '"Estabelecimento: ' + EB_ESTAB.Text + '"');
    WriteLn(ArqCSV, '"Descri��o: ' + EB_DESCRICAO.Text + '"');
    WriteLn(ArqCSV, '"Data Inicial de Vig�ncia: ' + EB_DTINIVIGENCIA.Text + '"');
    WriteLn(ArqCSV, '"Data Final de Vig�ncia: ' + EB_DTFINVIGENCIA.Text + '"');
    WriteLn(ArqCSV, '"Base da tabela: ' + EB_DTBASE.Text + '"');
    WriteLn(ArqCSV, '"Data Prazo p/ Pagamento: ' + EB_DTPRAZOPAGTO.Text + '"');
    WriteLn(ArqCSV, '"% Acr�scimo: ' + EB_PERCACRESCIMO.Text + '"');
    WriteLn(ArqCSV, '"% de Desconto: ' + EB_PERCDESCONTO.Text + '"');
    WriteLn(ArqCSV, ''); // Linha em branco para separar

    // Escreve o cabe�alho da tabela
    linhaCSV := '';
    for j := 0 to 11 do
    begin
      if linhaCSV <> '' then linhaCSV := linhaCSV + ';';
      linhaCSV := linhaCSV + '"' + campos[j] + '"';
    end;
    WriteLn(ArqCSV, linhaCSV);

    // Escreve os dados
    for i := 1 to sgTabPreco.RowCount - 1 do
    begin
      linhaCSV := '';
      for j := 0 to 11 do
      begin
        celula := sgTabPreco.Cells[colunas[j], i];
        limpa := '';
        for k := 1 to Length(celula) do
        begin
          c := celula[k];
          if (c <> #10) and (c <> #13) then
            limpa := limpa + c;
        end;
        if linhaCSV <> '' then linhaCSV := linhaCSV + ';';
        linhaCSV := linhaCSV + '"' + Trim(limpa) + '"';
      end;
      WriteLn(ArqCSV, linhaCSV);
    end;

    CloseFile(ArqCSV);
    MessageDlg('Exportado para CSV com sucesso!', mtInformation, mbOK, 0);
  except
    MessageDlg('Erro ao exportar para CSV', mtError, mbOK, 0); 
  end;

  SaveDialog.Free;
end;

procedure Per3588;
begin          
  btnexportar.Parent := sbSimPreco.Parent;
  btnexportar.SetBounds(sbSimPreco.ExplicitLeft, sbSimPreco.ExplicitTop + 30, sbSimPreco.ExplicitWidth, sbSimPreco.ExplicitHeight);
  btnexportar.OnClick := 'btnexportarClick';
end;                       

begin

  Per3588;   
  
end;
