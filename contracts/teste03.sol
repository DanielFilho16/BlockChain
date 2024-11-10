//Código criado para a disciplina de Blockchain e Criptomoedas Disciplina ministrada pelo professor Doutor Jó Ueyama no segundo semestre de 2024. Finalizado em 10/11/2024 
// Código criado com bbase na docmentação e materiais em vídeo/fóruns na internet
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Valida_dados_pacientes {

    // dados básicos do paciente na struct    
    struct Paciente {
        address medicoAutorizado;
        string nome;
        string dados;
    }

    struct Acesso {
        address medico;
        uint timestamp;
    }

    struct Alteracao {
        string dados_originais;
        string dados_novos;
        uint timestamp;
    }

    struct AcessoTemp {
        address medico;
        uint dataExpiracao;
    }

    mapping(address => Paciente) private pacientes;
    mapping(address => Acesso[]) private historicoAcessos;
    mapping(address => Alteracao[]) private historicoAlteracoes;
    mapping(address => AcessoTemp[]) private acessosTemporarios;
    mapping(address => address[]) private medicosAutorizados;
    mapping(address => string) private tokens;

    // dono do contrato - administrador
    address public administrador;
    
    // notifica quando um paciente é registrado
    event PacienteRegistrado(address enderecoPaciente, string nome);
    // notifica quando alguém é autorizado a acessar os dados
    event AcessoConcedido(address enderecoPaciente, address medico);
    // mostra quem acessou os dados
    event DadosAcessados(address enderecoPaciente, address medico);
    // notifica quando os dados são atualizados
    event DadosAtualizados(address enderecoPaciente, string dados_novos);
    // notifica o paciente sobre um acesso
    event NotificacaoPaciente(address enderecoPaciente, string mensagem);

    // restringe alterações só para o administrador
    modifier so_adm() {
        require(msg.sender == administrador, "Apenas o adm pode executar esta funcao.");
        _;
    }

    // restringe o acesso aos dados apenas ao medico autorizado
    modifier acesso_negado(address enderecoPaciente) {
        bool autorizado = false;
        for (uint i = 0; i < medicosAutorizados[enderecoPaciente].length; i++) {
            if (medicosAutorizados[enderecoPaciente][i] == msg.sender) {
                autorizado = true;
                break;
            }
        }
        require(autorizado || msg.sender == administrador, "Acesso negado. Voce nao esta autorizado a acessar os dados deste paciente.");
        _;
    }

    modifier acesso_temporario(address enderecoPaciente) {
        bool autorizado = false;
        for (uint i = 0; i < acessosTemporarios[enderecoPaciente].length; i++) {
            if (acessosTemporarios[enderecoPaciente][i].medico == msg.sender && acessosTemporarios[enderecoPaciente][i].dataExpiracao > block.timestamp) {
                autorizado = true;
                break;
            }
        }
        require(autorizado || msg.sender == administrador, "Eroo: Acesso expirado ou nao autorizado.");
        _;
    }

    // define e printa adm
    constructor() {
        administrador = msg.sender;
    }

    // adiciona novo paciente
    function Registrar_novo_paciente(address enderecoPaciente, string memory nome, string memory dados) public so_adm {
        pacientes[enderecoPaciente] = Paciente(address(0), nome, dados);
        emit PacienteRegistrado(enderecoPaciente, nome);
    }

    // atualiza dados do paciente e grava no log
    function atualizar_dados_paciente(address enderecoPaciente, string memory dados_novos) public so_adm {
        string memory dados_originais = pacientes[enderecoPaciente].dados;
        historicoAlteracoes[enderecoPaciente].push(Alteracao(dados_originais, dados_novos, block.timestamp));
        pacientes[enderecoPaciente].dados = dados_novos;
        emit DadosAtualizados(enderecoPaciente, dados_novos);
    }

    // remove acesso do médico
    function remover_acesso_medico(address enderecoPaciente) public so_adm {
        pacientes[enderecoPaciente].medicoAutorizado = address(0);
        emit AcessoConcedido(enderecoPaciente, address(0));
    }

    // medico acessa os dados por um tempo determinado
    function conceder_acesso_temp(address enderecoPaciente, address enderecoMedico, uint duracao) public so_adm {
        uint expiracao = block.timestamp + duracao;
        acessosTemporarios[enderecoPaciente].push(AcessoTemp(enderecoMedico, expiracao));
        emit AcessoConcedido(enderecoPaciente, enderecoMedico);
    }

    // acesso permanente para mais de um endereco
    function conceder_acesso_medico(address enderecoPaciente, address enderecoMedico) public so_adm {
        medicosAutorizados[enderecoPaciente].push(enderecoMedico);
        emit AcessoConcedido(enderecoPaciente, enderecoMedico);
    }

    // exibe os dados consultados e adiciona ao histórico de acesso
    function obter_Dados_Paciente(address enderecoPaciente) public acesso_negado(enderecoPaciente) returns (string memory nome, string memory dados) {
        Paciente memory paciente = pacientes[enderecoPaciente];
        historicoAcessos[enderecoPaciente].push(Acesso(msg.sender, block.timestamp));
        emit DadosAcessados(enderecoPaciente, msg.sender);
        emit NotificacaoPaciente(enderecoPaciente, "Seus dados foram acessados.");
        return (paciente.nome, paciente.dados);
    }

    // exibe os dados consultados com permissão temporaria e adiciona ao histórico de acesso
    function obterDadosPacienteTemp(address enderecoPaciente) public acesso_temporario(enderecoPaciente) returns (string memory nome, string memory dados) {
        Paciente memory paciente = pacientes[enderecoPaciente];
        historicoAcessos[enderecoPaciente].push(Acesso(msg.sender, block.timestamp));
        emit DadosAcessados(enderecoPaciente, msg.sender);
        emit NotificacaoPaciente(enderecoPaciente, "Seus dados foram acessados.");
        return (paciente.nome, paciente.dados);
    }

    // autentica com senha
    function configurar_token(address enderecoPaciente, string memory token) public so_adm {
        tokens[enderecoPaciente] = token;
    }

    // exibir dados sensiveis com senha
    function obterDadosPacienteComToken(address enderecoPaciente, string memory token) public acesso_negado(enderecoPaciente) returns (string memory nome, string memory dados) {
        require(keccak256(abi.encodePacked(tokens[enderecoPaciente])) == keccak256(abi.encodePacked(token)), "Senha invalida.");
        Paciente memory paciente = pacientes[enderecoPaciente];
        historicoAcessos[enderecoPaciente].push(Acesso(msg.sender, block.timestamp));
        emit DadosAcessados(enderecoPaciente, msg.sender);
        return (paciente.nome, paciente.dados);
    }

    // mostra os acessosa informações
    function verHistoricoAcessos(address enderecoPaciente) public view so_adm returns (Acesso[] memory) {
        return historicoAcessos[enderecoPaciente];
    }

    // mostra alterações feitas
    function verHistoricoAlteracoes(address enderecoPaciente) public view so_adm returns (Alteracao[] memory) {
        return historicoAlteracoes[enderecoPaciente];
    }
}
