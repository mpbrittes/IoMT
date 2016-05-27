%
%   Simulador de redes IoT
%

clear all; close all;
rng('shuffle');
 
%%
% Parametros gerais
%
MaxObjetos = 50;
MaxEventos = 100;
MaxDesconexoes = 25;
MaxIteracoes = 500;
MaxMaliciosos = 30;         % Percentual de objetos maliciosos

IniciarConexoes = false;
ConexoesIniciais = 1000;
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
NroMaliciosos = MaxObjetos * MaxMaliciosos / 100;

EventoAtual = 1;

lstEventos = [];
lstConexoes = [];
hConexoes = [];
hEventos = [];
%%
%   Criacao da lista de objetos para simulacao
%

lstObjetos(1,MaxObjetos) = Objeto(MaxObjetos);

for t=1:MaxObjetos
    lstObjetos(t).Id = t;
end

%%
% Laco principal da simulacao
%

if IniciarConexoes
    t = 1;
    while t < ConexoesIniciais
        
        SolicitanteId = randi(MaxObjetos,1,1);
        SolicitadoId = randi(MaxObjetos,1,1);
        
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

for t=1:MaxIteracoes
    waitbar(t/MaxIteracoes,h);
    
    for o=1:MaxObjetos   
        %%
        %
        %   Executa os eventos na rede
        ev = randi(4,1,1);
        ev = 1;
        
        SolicitanteId = lstObjetos(o).Id;
        SolicitadoId = randi(MaxObjetos,1,1);
        
        if SolicitanteId == SolicitadoId
            continue;
        end
        
        %   Conectar objetos na rede
        if ev == 1
            status = lstObjetos(SolicitanteId).JaConectado(SolicitadoId);
   
            if ~status
                % Objetos não estão conectados
                ra = CalcularRecomendacao(lstObjetos, SolicitadoId, lstObjetos(SolicitanteId));
                
                if ra >= 0
                    lstObjetos(SolicitanteId).Conectar(lstObjetos(SolicitadoId), t);
                    
                    NroConexoesAtuais = NroConexoesAtuais + 1;
                    
                    lstConexoes = [lstConexoes; SolicitanteId];
                    
                    if NroConexoesAtuais > NroMaxConexoes
                        NroMaxConexoes = NroConexoesAtuais;
                    end
                else
                    NroNegativasConexoes = NroNegativasConexoes + 1;
                end
                
                hEventos = [hEventos; ev];
            else
                % Se estão conectados então podem desconectar (2) ou
                % comunicar(3)
                ev = randi([2,3] ,1,1);
            end
        end
        
        % Desconectar objetos
        if ev == 2            
            %
            %   Para controlar o percentual de desconexoes descomentar
            %
            %         ed = randi(4,1,1);
            %
            %         if ed > 2
            %             hConexoes = [hConexoes NroConexoesAtuais];
            %             continue;
            %         end
            
            %
            %   até aqui
            %
            
            if size(lstConexoes(:),1) > 0
                j = randi(size(lstConexoes(:),1), 1, 1);
                SolicitanteId = lstConexoes(j);
                
                x = randi(size(lstObjetos(SolicitanteId).ConexoesOut, 2), 1, 1);
                SolicitadoId = lstObjetos(SolicitanteId).ConexoesOut(x).Id;
                
                lstObjetos(SolicitanteId).Desconectar(lstObjetos(SolicitadoId), t);
                
                NroDesconexoes = NroDesconexoes + 1;
                NroConexoesAtuais = NroConexoesAtuais - 1;
                
                lstConexoes(j) = [];
                
                hEventos = [hEventos; 2];
            end
        end
        
        if ev == 3
            if size(lstConexoes) > 0
                j = randi(size(lstConexoes(:),1), 1, 1);
                SolicitanteId = lstConexoes(j);
                
                x = randi(size(lstObjetos(SolicitanteId).ConexoesOut, 2), 1, 1);
                SolicitadoId = lstObjetos(SolicitanteId).ConexoesOut(x).Id;
                
                lstObjetos(SolicitanteId).Comunicar(lstObjetos(SolicitadoId), t);
                
                NroMensagens = NroMensagens + 1;
                
                hEventos = [hEventos; 3];
            end
        end
        
        %
        %   Ataque malicioso
        %
        if ev == 4
            if NroConexoesAtuais > 0
                if size(lstConexoes(:),1) > 0
                    j = randi(size(lstConexoes(:),1), 1, 1);
                    SolicitadoId = lstConexoes(j);
                end
                
                while size(lstObjetos(SolicitadoId).Conectados) > 0
                    x = lstObjetos(SolicitadoId).Conectados(1);
                    
                    lstObjetos(SolicitadoId).Desconectar(x, t);
                    s = lstObjetos(x).Desconectar(SolicitadoId, t);
                    
                    if s
                        NroConexoesAtuais = NroConexoesAtuais - 1;
                        NroDesconecoesAtaques = NroDesconecoesAtaques + 1;
                    end
                    
                    k = find(lstConexoes(:) == SolicitadoId);
                    lstConexoes(k) = [];
                    
                    k = find(lstConexoes(:) == x);
                    lstConexoes(k) = [];
                end
                NroAtaques = NroAtaques + 1;
                
                hEventos = [hEventos; 4];
            end
        end
        
        %%
        %
        %   Buscar por comportamentos maliciosos
        %
        
        for k=1:size(lstObjetos(o).ConexoesIn(:))
            x = lstObjetos(lstObjetos(o).ConexoesIn(k).Id);
            
            y = find(lstObjetos(o).Conhecidos(:) == x.Id,1);
            Conceito = lstObjetos(o).Recomendacao(y);
            
            switch x.Funcao
                case 1
                    % Calculo do tempo de permanencia na rede
                    % Diferença maior que 3 comportamento malicioso
                    if ((t - x.TempoEntrada) >= 4) || ...
                            (lstObjetos(o).ConexoesIn(k).Comunicados > 1)
                        Conceito = -1;
                    else
                        Conceito = 1;
                    end
                otherwise
                    continue;
            end
            
            lstObjetos(o).Recomendacao(y) = Conceito;
        end
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
                