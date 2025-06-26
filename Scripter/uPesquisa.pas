{
--------------------------------------------------------------------------------
                          SOBRE O CODIGO
--------------------------------------------------------------------------------
  Este e o codigo de um formulario de pesquisa generico (lookup).

  O que ele faz:
  1. INICIALIZACAO:
     - O formulario e iniciado atraves do procedimento 'Init', que recebe
       um titulo para a janela e um comando SQL.
     - O comando SQL e executado para carregar os dados que serao
       exibidos na grade de pesquisa.

  2. FILTRO EM TEMPO REAL:
     - Existe um campo de texto ('eb_pesquisa') que permite ao usuario
       digitar para filtrar os resultados.
     - A cada tecla pressionada, o codigo filtra os dados na grade,
       procurando pelo texto digitado na coluna 'DESCRICAO' de forma
       nao sensitiva a maiusculas/minusculas.

  3. SELECAO DE ITEM:
     - O usuario pode selecionar um item de duas formas:
       a) Dando um duplo-clique sobre a linha desejada na grade.
       b) Pressionando a tecla 'Enter' no campo de pesquisa.
     - Ao selecionar um item, o formulario e fechado e retorna um
       resultado positivo ('mrOK') para a tela que o chamou.
--------------------------------------------------------------------------------
}

{$FORM TFPesquisa, uPesquisa.sfm}

uses
  Classes, Graphics, Controls, Forms, Dialogs, VsEdit, 
  StdCtrls, VsDBGrid, uVsClientDataSet, DBClient, DB;

               
procedure grdDblClick(Sender: TObject);
begin
  inherited(Sender,'OnDblClick');
  ModalResult := mrOK;
end;      

procedure Init(cCaption, cSql : String);
  begin
  cds.data := dmConexao3c.QueryPegaData('#'+cSql,'*',                                                 
                                          [], [ftString], [1000]);
  self.caption := cCaption;                                           
end;
                          
procedure eb_pesquisaKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin   
    if key = Vk_RETURN then
      ModalResult := mrOK;   

  cds.Filtered := false;    
  cds.FilterOptions := [];
  if (eb_pesquisa.text <> '') then
    begin
    cds.Filter := 'UPPER(DESCRICAO) like ''%' + UPPERCASE(eb_pesquisa.Text) + '%''';
    cds.Filtered := true;
  end;                                          
end; 
      
begin
end;
