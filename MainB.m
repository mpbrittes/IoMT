%
%   Simulador de redes IoT
%

clear all; close all;
rng('shuffle');
 
%%
% Parametros gerais
%
MaxObjetos = 300;
MaxEventos = 100;
MaxDesconexoes = 25;
MaxIteracoes = 2000;
MaxMaliciosos = 30;         % Percentual de objetos maliciosos

IniciarObjetos = true;
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
hConexoes = zeros(1,1);
hEventos = [];
%%
%   Criacao da lista de objetos para simulacao
%

lstObjetos(1,MaxObjetos) = Objeto(MaxObjetos);

for i=1:MaxObjetos
    lstObjetos(i).Id = i;
    lstObjetos(i).Funcao = TipoFuncao(1);
    lstObjetos(i).MaxConexoes = randi([1,10],1,1);
end

%%
% Laco principal da simulacao
%

if IniciarObjetos
    i = 1;
    while i < ConexoesIniciais
        
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
        
        lstObjetos(SolicitadoId).Conectar(SolicitanteId, 0);
        lstObjetos(SolicitanteId).Conectar(SolicitadoId, 0);
        
        lstConexoes = [lstConexoes; SolicitanteId; SolicitadoId];
        
        NroConexoesAtuais = NroConexoesAtuais + 1;
        % hConexoes = [hConexoes NroConexoesAtuais];
        
        if NroConexoesAtuais > NroMaxConexoes
            NroMaxConexoes = NroConexoesAtuais;
        end
        
        i = i + 1;
    end
end

for i=1:MaxIteracoes
        
    ev = randi(4,1,1);
    
    lstEventos = [lstEventos; ev];
    
    SolicitanteId = randi(MaxObjetos,1,1);
    SolicitadoId = randi(MaxObjetos,1,1);
    
    if SolicitanteId == SolicitadoId
        hConexoes = [hConexoes NroConexoesAtuais];
        continue;
    end
    
    %   Conectar objetos na rede
    if ev == 1
        
        status = lstObjetos(SolicitadoId).JaConectado(SolicitanteId);
        
        if status
            hConexoes = [hConexoes NroConexoesAtuais];
            continue;
        end
        
        ra = CalcularRecomendacao(lstObjetos, SolicitanteId, lstObjetos(SolicitadoId));

        if ra >= 0
            lstObjetos(SolicitadoId).Conectar(SolicitanteId, i);
            lstObjetos(SolicitanteId).Conectar(SolicitadoId, i);
            
            NroConexoesAtuais = NroConexoesAtuais + 1;
            
            lstConexoes = [lstConexoes; SolicitanteId; SolicitadoId];
             
            if NroConexoesAtuais > NroMaxConexoes
                NroMaxConexoes = NroConexoesAtuais;
            end
        else
            NroNegativasConexoes = NroNegativasConexoes + 1;
        end
        
        hEventos = [hEventos; ev];
    end
    
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
            SolicitadoId = lstConexoes(j);
            
            x = randi(size(lstObjetos(SolicitadoId).Conectados(:),1), 1, 1);
            
            SolicitanteId = lstObjetos(SolicitadoId).Conectados(x);
            
            lstObjetos(SolicitadoId).Desconectar(SolicitanteId, i);
            s = lstObjetos(SolicitanteId).Desconectar(SolicitadoId, i);
            
            if s
                NroDesconexoes = NroDesconexoes + 1;
                NroConexoesAtuais = NroConexoesAtuais - 1;
            end
            
            lstConexoes(j) = [];
            
            k = find(lstConexoes(:) == SolicitanteId);
            lstConexoes(k) = [];
            
            hEventos = [hEventos; 2];
        end
    end
    
    if ev == 3
        if size(lstConexoes(:),1) > 0
            j = randi(size(lstConexoes(:),1), 1, 1);
            SolicitadoId = lstConexoes(j);
            
            x = randi(size(lstObjetos(SolicitadoId).Conectados(:),1), 1, 1);
            SolicitanteId = lstObjetos(SolicitadoId).Conectados(x);
            
            lstObjetos(SolicitadoId).Comunicar(i);
            
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
                
                lstObjetos(SolicitadoId).Desconectar(x, i);
                s = lstObjetos(x).Desconectar(SolicitadoId, i);
                
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
    
    hConexoes = [hConexoes NroConexoesAtuais];
end

figure;
plot(hConexoes); title('Network Evolution'); 
                ylabel('Number of connections');
                ylabel('Time');

figure;
histogram(hConexoes); title('Maximum of Instances in Time'); 
                ylabel('Instances in time');
                ylabel('Amount of connections');
                