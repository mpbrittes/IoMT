%
%   Simulador de redes IoT
%

clear all; close all;
rng('shuffle');
 
%%
% Parametros gerais
%
Parametros.MaxObjetos = 10;
Parametros.MaxEventos = 100;
Parametros.MaxDesconexoes = 25;
Parametros.MaxIteracoes = 200;
Parametros.MaxMaliciosos = 30;         % Percentual de objetos maliciosos
Parametros.IniciarConexoes = false;
Parametros.ConexoesIniciais = 100;
Parametros.AplicarDetecao = false;
%%
%   Dados gerais coletados
%

NroConexoesAtuais = 0;
NroDesconexoes = 0;
NroMaxConexoes = 0;
NroNegativasConexoes = 0;
NroMensagens = 0;
NroAtaques = 0;
NroDesconecoesAtaques = 0;
NroMaliciosos = Parametros.MaxObjetos * Parametros.MaxMaliciosos / 100;

EventoAtual = 1;

lstEventos = [];
lstConexoes = [];
hConexoes = [];
hEventos = [];
%%
%   Criacao da lista de objetos para simulacao
%

% lstObjetos(1,Parametros.MaxObjetos) = Objeto(Parametros.MaxObjetos);

for i=1:Parametros.MaxObjetos
    lstObjetos(i) = Objeto(i);
end

%%
% Laco principal da simulacao
%

if Parametros.IniciarConexoes
    t = 1;
    while t < Parametros.ConexoesIniciais
        
        SolicitanteId = randi(Parametros.MaxObjetos,1,1);
        SolicitadoId = randi(Parametros.MaxObjetos,1,1);
        
        if SolicitanteId == SolicitadoId
            continue;
        end
        
        ev = 1;
        
        lstEventos = [lstEventos; ev];
        hEventos = [hEventos; ev];
        
        %   Conectar objetos na rede
        
        status = lstObjetos(SolicitadoId).JaConectado(SolicitanteId);
        
        if status
            continue;
        end
        
        lstObjetos(SolicitanteId).Conectar(lstObjetos(SolicitadoId), 0);
        
        lstConexoes = [lstConexoes; SolicitanteId];
        
        NroConexoesAtuais = NroConexoesAtuais + 1;
%         hConexoes = [hConexoes; NroConexoesAtuais];
        
        if NroConexoesAtuais > NroMaxConexoes
            NroMaxConexoes = NroConexoesAtuais;
        end
        
        t = t + 1;
    end
end

h = waitbar(0,'Executando simulação...');

lstC = find([lstObjetos(:).Funcao] == 2 | [lstObjetos(:).Funcao] == 4);

for t=1:Parametros.MaxIteracoes
    waitbar(t/Parametros.MaxIteracoes,h);
    
    for o=1:Parametros.MaxObjetos   
        oA = lstObjetos(o);
        
        if oA.Funcao == 2 || oA.Funcao == 4
            continue;
        end
   
        oB = lstObjetos(randi(size(lstC), 1));
        
        if Parametros.AplicarDetecao
            ra = CalcularRecomendacao(lstObjetos, oB.Id, oA);
        else
            ra = 0;
        end
        
        if ra >= 0
            if oA.Conectar(oB, t)
                NroConexoesAtuais = NroConexoesAtuais + 1;
            end
        else
            NroNegativasConexoes = NroNegativasConexoes + 1;
        end
        
        if NroConexoesAtuais > NroMaxConexoes
            NroMaxConexoes = NroConexoesAtuais;
        end
        
        if mod(t,2) == 0
            oA = lstObjetos(randi(size(lstC), 1));
            oB = lstObjetos(randi(size(lstC), 1));
            if oA.Desconectar(oB,t)
                NroConexoesAtuais = NroConexoesAtuais - 1;
            end
        end
        
        %%
        %
        %   Buscar por comportamentos maliciosos
        %
        
%         for k=1:size(lstObjetos(o).ConexoesIn(:))
%             x = lstObjetos(lstObjetos(o).ConexoesIn(k).Id);
%             
%             y = find(lstObjetos(o).Conhecidos(:) == x.Id,1);
%             Conceito = lstObjetos(o).Recomendacao(y);
%             
%             switch x.Funcao
%                 case 1
%                     % Calculo do tempo de permanencia na rede
%                     % Diferença maior que 3 comportamento malicioso
%                     if ((t - x.TempoEntrada) >= 4) || ...
%                             (lstObjetos(o).ConexoesIn(k).Comunicados > 1)
%                         Conceito = -1;
%                     else
%                         Conceito = 1;
%                     end
%                 otherwise
%                     continue;
%             end
%             
%             lstObjetos(o).Recomendacao(y) = Conceito;
%         end
    end
    
    hConexoes = [hConexoes; NroConexoesAtuais];
end

close(h);

figure;
plot(hConexoes); title('Network Evolution'); 
                ylabel('Number of connections');
                xlabel('Time');

figure;
histogram(hConexoes); title('Maximum of Instances in Time'); 
                ylabel('Instances in time');
                xlabel('Amount of connections');
                