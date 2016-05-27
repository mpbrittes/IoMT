function r = TipoEvento(Nr)
%
% Tipos de eventos na simulacao.
%   1 - Entrada na rede
%   2 - Saida voluntaria da rede
%   3 - Comunicacao ou troca de servicos
%
    r = randi(3,Nr,1);
end
