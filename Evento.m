classdef Evento
    %   Definicao dos eventos da simulacao
    %
    
    properties
        Id                              % Identificador do evento
        Tipo                            % Tipo de evento: 1-Entrada, 2-Saida, 3-Comunicacao
    end
    
    methods
        function r = Evento(aId)
            if nargin > 0
                r.Id = aId;
            end
        end
    end
    
end

