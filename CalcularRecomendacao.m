function r = CalcularRecomendacao(lstO, Solicitante, oSolicitado)
%   Calcula o indice de recomendacao de um determinado objeto
%   baseado nas recomendacoes individuais dos objetos da rede
%   

    r = 0;
    c = [oSolicitado.ConexoesIn(:).Id oSolicitado.ConexoesOut(:).Id];
    
    for i=1:size(c)
        
        d = lstO(c(i)).Conhecidos(:);
        
        for j=1:size(d)
            k = find(lstO(d(j)).Conhecidos(:) == Solicitante,1);
            
            if ~isempty(k)
                r = r + lstO(d(j)).Recomendacao(k);
            end
        end
    end
end

