  cWhere : String;
  filtros : TStringList;  
  FiltroEstab : TStringList;  
  dIni, dFin : Date;
  cFiltroAux : String;
  nUsadeItem : Integer;
  
begin
  filtros := TStringList.Create;       
  FiltroEstab := TStringList.Create;

  filtros.Add(MontaFiltroSelecao('Filtro de Estabelecimentos', 'Estab', 'V_FILIAL_USERACESSO', 
    'NOTA', 'ESTAB', 'I', 'RAZAOSOC', 'CNPJ', '', 0, 'INATIVA = ''N'' AND USERID = ''' 
    + Report.Parameters.Items['USUARIO_LOGADO'].Value + ''' ', 'N'));
    
  filtros.Text := MontaTelaFiltros(filtros,false);
  FiltroEstab.CommaText := ExtrairSelecaoEstab(Trim(filtros[0]));
      
  dIni := PriDiaMes(CurrentDate);
  dFin := UltDiaMes(CurrentDate);

  nUsadeItem     := QueryCampoInt('SELECT USADE FROM USANDODE WHERE TABELA = ''ITEM'' AND ESTAB = '+FiltroEstab[0]);                                               

  cWhere := filtros[0] + FiltrarAcessoEstabPorUsuario('NOTA', 'ESTAB', Report.Parameters.Items['USUARIO_LOGADO'].Value);  
    
  filtros.Clear;                                                                   

  filtros.Add(MontaFiltroData('Filtros Adicionais', 'Data inicial', '', '', 0, dIni, dIni, 'N'));
  filtros.Add(MontaFiltroData('Filtros Adicionais', 'Data final', '', '', 0, dIni, dIni, 'N'));     
  filtros.Add(MontaFiltroSelecao('Filtros Adicionais', 'Item', 'ITEM', 'ITEM', 'IDITEM', 'S', 'DESCRICAO', 
                                 'ESTAB', 'ESTAB', nUsadeItem, '','N'));           
  filtros.Add(MontaFiltroCheck('Filtros Adicionais', 'Exibe Pessoa', '', '', 'S'));
  filtros.Add(MontaFiltroCheck('Filtros Adicionais', 'Exibe Pessoa', '', '', 'S'));
  filtros.Add(MontaFiltroCheck('Filtros Adicionais', 'Exibe Pessoa', '', '', 'S'));
  filtros.Add(MontaFiltroCheck('Filtros Adicionais', 'Exibe Pessoa', '', '', 'S'));

  filtros.Text := MontaTelaFiltros(filtros, True);
   
  //extrair selecao de data inicial
  SetParametroData(Report, ':DTINI', ExtrairSelecaoData(filtros[0]));
  
  //extrair selecao de data final
  SetParametroData(Report, ':DTFIM', ExtrairSelecaoData(filtros[1])); 
  
  cWhere := cWhere + filtros[2];

  filtros.Delete(3);
  filtros.Delete(2);
  filtros.Delete(1);    
  filtros.Delete(0);
  mmListaFiltros.Text := filtros.Text;
    
  filtros.free;
  
  cWhere := '0 ' + cWhere; 
  SetParametro(Report, ':SQL', cWhere);       