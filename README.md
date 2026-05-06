# commands-nt

Sistema de Punição para servidores FiveM construído sobre o framework vRP. Aplica um "modo punição" em jogadores que descumprem regras, bloqueando ações ofensivas (atirar, mirar, drive-by) por um tempo determinado, com aplicação e remoção via comandos administrativos.

## Funcionalidades

- Bloqueio de tiro, mira e drive-by enquanto a punição estiver ativa
- Comandos `/punir` e `/despunir` restritos a grupo administrativo
- Tempo de punição configurável com auto-remoção via timer no servidor
- State replicado (`Punishment-nt`) para outros resources detectarem o status do jogador
- Cleanup automático ao desconectar
- Notificações ao admin e ao jogador punido em todas as ações
- Proteção contra trigger duplicado (não cria threads paralelas se chamado mais de uma vez)

## Dependências

- [vRP](https://github.com/vRP-framework/vRP) — framework base
- Sistema de notificação compatível com o evento `Notify` (cliente e servidor)

## Instalação

1. Coloque a pasta `commands-nt` em `resources/` do seu servidor
2. Adicione `ensure commands-nt` no `server.cfg`
3. Reinicie o servidor

## Configuração

No arquivo `server-side/core.lua`:

```lua
local Config = {
    AdminGroup = "Admin",  -- grupo necessário para usar os comandos
    DefaultTime = 600,     -- tempo padrão em segundos (10 min)
    MaxTime = 3600,        -- tempo máximo permitido (1 hora)
}
```

## Uso

| Comando     | Argumentos        | Descrição                                  |
|-------------|-------------------|--------------------------------------------|
| `/punir`    | `[id] [tempo?]`   | Aplica modo punição no jogador             |
| `/despunir` | `[id]`            | Remove o modo punição manualmente          |

Se `tempo` não for informado, usa `DefaultTime`. Tempos acima de `MaxTime` são truncados automaticamente.

**Exemplo:**
```
/punir 12 300       -- pune o jogador de id 12 por 5 minutos
/despunir 12        -- libera antes do tempo acabar
```

## Estrutura

```
commands-nt/
├── fxmanifest.lua
├── client-side/
│   └── core.lua
└── server-side/
    └── core.lua
```

## Como funciona

**Client-side:** Ao receber o evento `nt_punishment:Init`, o cliente ativa um loop com `Wait(0)` que chama `DisableControlAction` em cada frame para os IDs de controle de ataque e mira — chamada por frame é exigência da engine pra que o bloqueio tenha efeito. `PlayerId()` e o tamanho da tabela de controles bloqueados são cacheados fora do loop pra evitar overhead. A flag local `IsPunished` controla a vida da thread e protege contra triggers duplicados.

**Server-side:** Os comandos validam o grupo do solicitante via `vRP.HasGroup`, conferem se o alvo existe (`GetPlayerName`) e se já não está punido, e disparam o evento no cliente alvo. Um `SetTimeout` agenda a auto-despunição após o tempo configurado. A tabela `ActivePunishments` rastreia o estado server-side pra evitar reaplicação e é limpa em `playerDropped` caso o jogador desconecte enquanto punido.

## Autor

Natti
