classdef Objeto < handle
    %   Definicao do objeto IoT para simulacao.
    %   
    
    properties
        Id;                                 % Identificador unico de objeto
        Funcao;                             % Funcao do objeto na rede: 1,2,3, ou 4.
        Malicioso;                          % Indica um objeto malicioso (1) ou nao (0)
        TempoEntrada;                       % Momento de entrada na rede
        TempoSaida;                         % Momento de saida da rede
        UltimaComunicao;                    % Momento da ultima comunicacao
        Comportamento;                      % Padrão de comportamento do objeto
        Conhecidos = [];                    % Lista de amigos do objeto
        Recomendacao = [];                  % Recomendacoes para objetos conhecidos
                                            % Conexoes de entrada
        ConexoesIn = struct('Id', {}, 'Comunicados', {}, 'UltimoContato', {}, 'Eventos', {});
                                            % Conexoes de saida
        ConexoesOut = struct('Id', {}, 'Comunicados', {}, 'UltimoContato', {}, 'Eventos', {});
        
        Conectados = [];                    % Lista de objetos conectados
        Comunicados = [];                   % Nro de comunicações enviadas para o objeto
        UltimoContato = [];                 % Momento da ultima comunicação enviada
        MaxConexoes;                        % Limite maximo de conexoes
    end
    
    properties(Dependent)
        NrConexoes;                         % Nr. de conexões do objeto
    end
    
    methods
        function r = get.NrConexoes(this)
            r = size(this.ConexoesIn,2) + size(this.ConexoesOut,2);
        end
        
        function r = Objeto(aId)
            if nargin > 0
                r.Id = aId;
                r.Funcao = randi(4,1,1);
                r.MaxConexoes = randi([1 10],1,1);
                
                %
                % Tipos de eventos:
                %       a -> Aguardando pedido de conexão
                %       c -> Solicita conexão
                %       d -> Solicita desconexão
                %       m -> Envia mensagem
                %       r -> Aguarda mensagem
                %
                switch r.Funcao
                    case 1
                        r.Comportamento = 'cmd';
                    case 2
                        r.Comportamento = 'armd';
                    case 3
                        r.Comportamento = 'cmrd';
                    case 4
                        r.Comportamento = 'ard';
                end
            end
        end
        
        function r = Conectar(this, oS, t)
        %   Conectar dois objetos.
        %   
        %   Parametros: this -> objeto solicitante
        %               oS   -> objeto solicitado
        %               t    -> tempo atual
        %
        %   Para se conectar os objetos não podem estar conectados.
        %
        
            r = false;
            
            if this.Id == oS.Id
                return;
            end
            
            m = find([this.ConexoesOut.Id] == oS.Id, 1);
            n = find([this.ConexoesIn.Id] == oS.Id, 1);
            
            if ~isempty(m) || ~isempty(n)
                return;
            end
            
            % Insere o objeto solicitado na lista de Conexoes de saida
            k = size(this.ConexoesOut, 2) + 1;
            this.ConexoesOut(k).Id = oS.Id;
            this.ConexoesOut(k).Comunicados = 0;
            this.ConexoesOut(k).UltimoContato = t;
            
            if isempty(this.ConexoesOut(k).Eventos)
                this.ConexoesOut(k).Eventos = 1;
            else
                this.ConexoesOut(k).Eventos = this.ConexoesOut(k).Eventos + 1;
            end
                       
            % Insere o objeto solicitante na lista de entrada do solicitado
            k = size(oS.ConexoesIn, 2) + 1;
            oS.ConexoesIn(k).Id = this.Id;
            oS.ConexoesIn(k).Comunicados = 0;
            oS.ConexoesIn(k).UltimoContato = t;
            
            if isempty(oS.ConexoesIn(k).Eventos) 
                oS.ConexoesIn(k).Eventos = 1;
            else
                oS.ConexoesIn(k).Eventos = oS.ConexoesIn(k).Eventos + 1;
            end
            
            this.TempoEntrada = t;
            this.TempoSaida = t;
            
            ra = find(this.Conhecidos(:) == oS.Id, 1);
            if isempty(ra)
                this.Conhecidos = [this.Conhecidos; oS.Id];
                this.Recomendacao = [this.Recomendacao; 0];
            end
            
            ra = find(oS.Conhecidos(:) == this.Id, 1);
            if isempty(ra)
                oS.Conhecidos = [oS.Conhecidos; this.Id];
                oS.Recomendacao = [oS.Recomendacao; 0];
            end
            
            r = true;
        end
        
        function r = Desconectar(this, oS, t)
        %   Desconectar dois objetos.
        %   
        %   Parametros: this -> objeto solicitante
        %               oS   -> objeto solicitado
        %               t    -> tempo atual
        %

            r = false;
            
            this.TempoSaida = t;
            
            k = find([this.ConexoesOut.Id] == oS.Id, 1);
            
            if ~isempty(k)
                if this.Comportamento(this.ConexoesOut(k).Eventos) == 'd'
                    c = 1;
                else
                    c = -1;
                end
                
                j = find([oS.Conhecidos] == this.Id, 1);
                oS.Recomendacao(j) = c;
                
                this.ConexoesOut(k) = [];
                
                k = find([oS.ConexoesIn.Id] == this.Id, 1);
                
                oS.ConexoesIn(k) = [];
                r = true;
            else
                k = find([oS.ConexoesOut.Id] == this.Id, 1);
                if ~isempty(k)
                    if oS.Comportamento(oS.ConexoesOut(k).Eventos) == 'd'
                        c = 1;
                    else
                        c = -1;
                    end
                    
                    j = find([this.Conhecidos] == oS.Id, 1);
                    this.Recomendacao(j) = c;
                    
                    oS.ConexoesOut(k) = [];
                    
                    k = find([this.ConexoesIn.Id] == oS.Id, 1);
                    this.ConexoesIn(k) = [];
                    r = true;
                end
            end
        end

        function r = Comunicar(this, oS, t)
        %   Envio de mensagem entre dois objetos.
        %   
        %   Parametros: this -> objeto solicitante
        %               oS   -> objeto solicitado
        %               t    -> tempo atual
        %
        %   Para o envio de mensagem os objetos precisam estar conectados.
        %   A cada envio serão atualizados os campos com o número de
        %   mensagens enviadas.
        %   
        %   Todos os objetos pertencentes as ConexoesIn e ConexoesOut pode
        %   enviar mensagens.
        %
        
            k = find([this.ConexoesOut.Id] == oS.Id,1);
            if ~isempty(k)
                this.ConexoesOut(k).Comunicados = this.ConexoesOut(k).Comunicados + 1;
                this.ConexoesOut(k).Eventos = this.ConexoesOut(k).Eventos + 1;
                
                if this.Comportamento(this.ConexoesOut(k).Eventos) == 'm'
                    c = 1;
                else
                    c = -1;
                end
                
                j = find([oS.Conhecidos] == this.Id, 1);
                oS.Recomendacao(j) = c;               
            end
            
            k = find([oS.ConexoesIn.Id] == this.Id,1);
            if ~isempty(k)
                oS.ConexoesIn(k).Comunicados = oS.ConexoesIn(k).Comunicados + 1;
                
            end
            
            k = find([this.ConexoesIn.Id] == oS.Id,1);
            if ~isempty(k)
                this.ConexoesIn(k).Comunicados = this.ConexoesIn(k).Comunicados + 1;
            end
            
            k = find([oS.ConexoesOut.Id] == this.Id,1);
            if ~isempty(k)
                oS.ConexoesOut(k).Comunicados = oS.ConexoesOut(k).Comunicados + 1;
            end
        end
        
        function r = JaConectado(this, aSolicitante)
            a = ~isempty(find([this.ConexoesIn.Id] == aSolicitante, 1));
            b = ~isempty(find([this.ConexoesOut.Id] == aSolicitante, 1));
            r = a || b;
        end
    end
    
    methods(Access = protected)

    end
    
end

